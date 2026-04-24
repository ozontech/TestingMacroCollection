//
//  MemberArbitraryMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension ArbitraryMacro: MemberMacro {
    private enum InitializerType {
        /// Generates a new initializer.
        case generated
        /// Uses the structure's default initializer.
        case base
        /// The initializer is already declared in the type.
        case inDecl
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard !declaration.is(ProtocolDeclSyntax.self),
              !declaration.is(EnumDeclSyntax.self),
              !declaration.variables.isEmpty else { return [] }

        guard let declGroup = declaration.asProtocol(DeclGroupSyntax.self),
              let typeName = getTypeNameFromDecl(declGroup) else {
            return []
        }

        let context = try makeContext(
            node: node,
            declaration: declaration,
            declGroup: declaration,
            typeName: typeName
        )

        let initializerType = defineInitializerType(
            declaration: declaration,
            accessModifier: context.accessModifier
        )

        guard initializerType == .generated else { return [] }

        let variables = declaration.variables.reduce(into: [(TokenSyntax, TypeSyntax)]()) { partialResult, variable in
            guard let name = variable.name?.identifier, let type = variable.type?.type else { return }

            partialResult.append((name, type))
        }
        let generatedInit = makeInit(
            variables: variables,
            accessModifier: context.accessModifier.isInternal ? nil : context.accessModifier
        )

        return [.init(generatedInit)]
    }

    /// Generates an initializer.
    ///
    ///  - Parameters:
    ///   - variables: declaration properties.
    ///   - accessModifier: declaration access modifier.
    ///  - Returns: the initializer.
    ///
    private static func makeInit(
        variables: [(TokenSyntax, TypeSyntax)],
        accessModifier: DeclModifierSyntax?
    ) -> InitializerDeclSyntax {
        let initParameterList = variables.enumerated().reduce(into: FunctionParameterListSyntax()) { partialResult, item in
            let variable = item.element

            let parameter = if variable.1.is(FunctionTypeSyntax.self) {
                FunctionParameterSyntax(
                    firstName: variable.0,
                    type: AttributedTypeSyntax(
                        specifiers: .init([]),
                        attributes: .init(arrayLiteral: .attribute(
                            .init(
                                atSign: .atSignToken(),
                                attributeName: IdentifierTypeSyntax(name: .keyword(.escaping))
                            )
                        )),
                        baseType: variable.1
                    ),
                    trailingComma: item.offset == variables.count - 1 ? nil : .commaToken()
                )
            } else {
                FunctionParameterSyntax(
                    firstName: variable.0,
                    type: variable.1,
                    trailingComma: item.offset == variables.count - 1 ? nil : .commaToken()
                )
            }

            partialResult.append(parameter)
        }
        let initParameterClause = FunctionParameterClauseSyntax(parameters: initParameterList)
        let initSignature = FunctionSignatureSyntax(parameterClause: initParameterClause)
        var accessModifiers = DeclModifierListSyntax()
        if let accessModifier {
            accessModifiers.append(accessModifier)
        }

        return .init(
            modifiers: accessModifiers,
            signature: initSignature,
            body: makeInitBody(variables: variables.map(\.0))
        )
    }

    /// Generates the initializer body.
    ///
    /// - Parameter variables: properties of the initializer declaration.
    /// - Returns: the initializer body.
    ///
    private static func makeInitBody(variables: [TokenSyntax]) -> CodeBlockSyntax {
        let stmts = variables.reduce(into: CodeBlockItemListSyntax()) { partialResult, variable in
            let propertyAssignment = InfixOperatorExprSyntax(
                leftOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .identifier(String._self)),
                    period: .periodToken(),
                    declName: .init(baseName: variable)
                ),
                operator: AssignmentExprSyntax(equal: .equalToken()),
                rightOperand: DeclReferenceExprSyntax(baseName: variable)
            )
            let item = CodeBlockItemSyntax.Item(propertyAssignment)
            partialResult.append(.init(item: item))
        }

        return .init(statements: stmts)
    }

    /// Determines the initializer type to use.
    ///
    /// - Parameters:
    //   - declaration: the declaration to analyze for initializer requirements.
    ///  - accessModifier: access modifier for the `arbitrary` method.
    /// - Returns: the appropriate initializer type.
    ///
    private static func defineInitializerType(
        declaration: DeclGroupSyntax,
        accessModifier: DeclModifierSyntax
    ) -> InitializerType {
        guard declaration.initializers.isEmpty else { return .base }

        if declaration.is(StructDeclSyntax.self), !accessModifier.isPublic {
            return .base
        } else {
            return .generated
        }
    }
}
