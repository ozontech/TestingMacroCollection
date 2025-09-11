//
//  VariablesBlockBuilder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

enum VariablesBlockBuilder {
    /// Generates a block with a mock implementation of properties from the protocol.
    ///
    ///  - Parameters:
    ///     - clearMethodBuilder: object of the clearing methods builder.
    ///     - variables: protocol properties.
    ///     - accessModifiers: access modifiers.
    ///     - generateOnlyUnderlying: flag for generating only underlying properties. Is used for `AnyMockable` macro.
    ///     - isActor: flag if the mock is an actor.
    ///  - Returns: an array of `MemberBlockItemSyntax` objects with `underlying` and regular properties, in addition to `set`
    /// methods for actors.
    ///
    /// If the property is non-optional, it generates the construction:
    ///
    ///     var name: String {
    ///         get {
    ///            return underlyingName
    ///         }
    ///         set(value) {
    ///            underlyingName = value
    ///         }
    ///    }
    ///    var underlyingName: String!
    ///
    /// If the property is optional or insecurely extracted, generates the construction.
    ///
    ///     var name: String? или var name: String!
    ///
    static func makeVariablesBlock(
        clearMethodBuilder: ClearMethodBuilder? = nil,
        variables: [VariableDeclSyntax],
        accessModifiers: DeclModifierListSyntax,
        generateOnlyUnderlying: Bool = false,
        generateDefaultValues: Bool,
        isActor: Bool
    ) -> [MemberBlockItemSyntax] {
        var result: [MemberBlockItemSyntax] = []

        variables.forEach { variable in
            guard let name = variable.name, let type = variable.type else { return }

            let isNonOptionalType = !type.type.isOptional && !type.type.isForceUnwrapped

            if !generateOnlyUnderlying {
                result.append(
                    .init(decl: MissingDeclSyntax(placeholder: .init(stringLiteral: "\n    // MARK: - \(name)\n")))
                )

                if isNonOptionalType {
                    let mockVar = MemberBlockItemSyntax(decl: makeMockVarGetterSetter(
                        name: name,
                        type: type,
                        accessModifiers: accessModifiers
                    ))
                    result.append(mockVar)
                } else {
                    var _accessModifiers = accessModifiers

                    if variable.isDelegate, !variable.isIgnored {
                        result.append(
                            .init(decl: MissingDeclSyntax(
                                placeholder: .init(
                                    stringLiteral: "// Add the @Ignored macro to the delegate property `\(name.identifier.text)` to avoid making the property weak."
                                )
                            ))
                        )
                        _accessModifiers.append(.init(name: .keyword(.weak)))
                    }

                    let mockVar = VariableDeclSyntax(
                        modifiers: _accessModifiers,
                        Keyword.var,
                        name: .init(name),
                        type: variable.type
                    )
                    result.append(.init(decl: mockVar))
                }
            }

            var underlyingVarType: ImplicitlyUnwrappedOptionalTypeSyntax?

            let typeShouldBeTupled = type.type.isClosure || type.type.is(SomeOrAnyTypeSyntax.self)

            if isNonOptionalType {
                underlyingVarType = typeShouldBeTupled ? type.type.tupledForceUnwrapped : type.type.forceUnwrapped
            }

            if let underlyingVarType {
                let underlyingVar = MemberBlockItemSyntax(
                    decl: VariableDeclSyntax(
                        modifiers: accessModifiers,
                        Keyword.var,
                        name: .init(name.underlying),
                        type: .init(type: underlyingVarType),
                        initializer: generateDefaultValues ? type.type.defaultInitialization : nil
                    )
                )

                clearMethodBuilder?.addProperty(
                    .nilable(
                        propertyName: underlyingVar.decl.as(VariableDeclSyntax.self)?.name?.identifier.text ?? ""
                    )
                )
                result.append(underlyingVar)
            }

            if isActor {
                let setValueMethod = SetPropertyFunctionBuilder.makeSetMethod(
                    for: .client,
                    propertyName: name.identifier.text,
                    accessModifiers: accessModifiers,
                    type: type.type
                )

                result.append(.init(decl: setValueMethod))
            }
        }

        return result
    }

    /// Generates a `getter` for the mock property.
    /// Is added only if the property is non-optional.
    ///
    ///     get {
    ///         return underlyingVarName
    ///     }
    ///
    private static func makeMockVarGetterSetter(
        name: IdentifierPatternSyntax,
        type: TypeAnnotationSyntax,
        accessModifiers: DeclModifierListSyntax
    ) -> VariableDeclSyntax {
        let accessorBlock = AccessorBlockSyntax(
            accessors: .accessors(
                .init([
                    makeGetterBlock(varName: name),
                    makeSetterBlock(varName: name),
                ])
            )
        )

        let binding = PatternBindingSyntax(
            pattern: name,
            typeAnnotation: type,
            accessorBlock: accessorBlock
        )

        let newVar = VariableDeclSyntax(
            modifiers: accessModifiers,
            bindingSpecifier: .keyword(Keyword.var),
            bindings: .init([binding])
        )

        return newVar
    }

    private static func makeGetterBlock(varName: IdentifierPatternSyntax) -> AccessorDeclSyntax {
        let expression = DeclReferenceExprSyntax(baseName: .identifier(varName.underlying.identifier.text))
        let returnStatement = ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: expression)
        let statement = CodeBlockItemSyntax(item: .stmt(.init(returnStatement)))
        let getterBody = CodeBlockSyntax(statements: [statement])
        return AccessorDeclSyntax(accessorSpecifier: .keyword(.get), body: getterBody)
    }

    /// Generates a `setter` for the mock property.
    /// Is added only if the property is non-optional.
    ///
    ///     set(value) {
    ///         underlyingVarName = value
    ///     }
    ///
    private static func makeSetterBlock(varName: IdentifierPatternSyntax) -> AccessorDeclSyntax {
        let declExpr = DeclReferenceExprSyntax(baseName: .identifier(varName.underlying.identifier.text))
        let assignmentExpr = AssignmentExprSyntax(equal: .equalToken())
        let valueDeclExpr = DeclReferenceExprSyntax(baseName: .identifier(.value))

        let exprListSyntax = ExprListSyntax([
            ExprListSyntax.Element(declExpr),
            ExprListSyntax.Element(assignmentExpr),
            ExprListSyntax.Element(valueDeclExpr),
        ])
        let sequence = SequenceExprSyntax(elements: exprListSyntax)

        var statements = CodeBlockItemListSyntax()

        if let sequence = ExprSyntax(sequence) {
            let codeBlockItem = CodeBlockItemSyntax(item: .expr(sequence))
            statements.append(codeBlockItem)
        }

        let parameters = AccessorParametersSyntax(name: .identifier(.value))

        return AccessorDeclSyntax(
            accessorSpecifier: .keyword(.set),
            parameters: parameters,
            body: .init(statements: statements)
        )
    }
}
