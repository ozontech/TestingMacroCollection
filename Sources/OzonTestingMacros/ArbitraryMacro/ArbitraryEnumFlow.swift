//
//  ArbitraryEnumFlow.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

extension ArbitraryMacro {
    /// Creates an `arbitrary` method for the enumeration.
    ///
    /// - Parameters:
    ///   - accessModifier: access modifier for the `arbitrary` method.
    ///   - enumDecl: enumeration declaration for which the stub is created.
    ///   - arbitraryConfig: the `Arbitrary` type, can be `static` or `dynamic`.
    /// - Returns: the `arbitrary` method.
    /// - Throws: `ArbitraryMacroError`.
    static func makeArbitraryMethodForEnum(
        type: TypeSyntax? = nil,
        accessModifier: DeclModifierSyntax,
        enumDecl: any DeclGroupSyntax,
        arbitraryConfig: ArbitraryConfig
    ) throws -> FunctionDeclSyntax {
        // Checks that the declaration is actually an enumeration.
        // We don't accept `enumDecl: EnumDeclSyntax` as input.
        guard let enumDecl = enumDecl.as(EnumDeclSyntax.self) else {
            throw ArbitraryMacroError.unsupportedType
        }

        // Creates modifiers for the `arbitrary` function declaration.
        let modifiers = [accessModifier, .init(name: .keyword(.static))]
            .reduce(into: DeclModifierListSyntax()) { partialResult, modifier in
                guard !modifier.isInternal else { return }
                partialResult.append(modifier)
            }

        // <- Gets all case declarations of the enumeration.
        // Note: a single `case` declaration can contain multiple cases, for example, `case a, b`.
        let allEnumCaseDeclarations = enumDecl
            .memberBlock
            .members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }

        let allCaseElements = allEnumCaseDeclarations.flatMap(\.elements)
        guard !allCaseElements.isEmpty else {
            throw ArbitraryMacroError.enumHasNoCases
        }
        // ->

        // Forms the function signature.
        let functionSignature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: []),
            returnClause: getReturnClause(type: type, typeName: enumDecl.name)
        )

        // <- Forms the function body.
        let functionBody: CodeBlockSyntax = switch arbitraryConfig {
        case .static:
            try buildFunctionBodyForStatic(
                enumDecl: enumDecl,
                allEnumCaseDeclarations: allEnumCaseDeclarations
            )
        case .dynamic:
            try buildFunctionBodyForDynamic(enumDecl: enumDecl, allCaseElements: allCaseElements)
        }
        // ->

        // Forms the function.
        let functionDeclaration = FunctionDeclSyntax(
            modifiers: modifiers,
            name: .identifier(String.arbitrary),
            signature: functionSignature,
            body: functionBody
        )

        return functionDeclaration
    }

    /// Creates the body of the `arbitrary` function for `.dynamic` generation.
    ///
    /// - Parameters:
    ///   - enumDecl: enumeration declaration for which the stub is created.
    ///   - allCaseElements: all enumeration cases.
    /// - Returns: the function body consisting of two blocks: 1. `let allCases = [...]` 2. `return allCases.random()!`.
    /// - Throws: `ArbitraryMacroError`.
    private static func buildFunctionBodyForDynamic(
        enumDecl: EnumDeclSyntax,
        allCaseElements: [EnumCaseElementListSyntax.Element]
    ) throws -> CodeBlockSyntax {
        // Creates elements of the `allCases` array.
        let allCasesArrayElements = try allCaseElements.enumerated().map { index, caseElement in
            // Creates an array element without surrounding syntax.
            let allCasesArrayElementWithoutSyntax = try buildCaseExpression(
                caseElement: caseElement,
                enumDecl: enumDecl,
                arbitraryConfig: .dynamic
            )

            // Creates an element of the `allCases` array with the surrounding syntax.
            let allCasesArrayElementWithSyntax = ArrayElementSyntax(
                expression: allCasesArrayElementWithoutSyntax,
                trailingComma: index == allCaseElements.count - 1 ? nil : .commaToken()
            )

            return allCasesArrayElementWithSyntax
        }

        // Creates the `allCases` array.
        let allCasesArrayWithSyntax = ArrayExprSyntax(
            leftSquare: .leftSquareToken(),
            elements: ArrayElementListSyntax(allCasesArrayElements),
            rightSquare: .rightSquareToken()
        )

        let allCasesVarName = "allCases"

        // Creates the `allCases` variable without the surrounding syntax.
        let allCasesVarWithoutSyntax = VariableDeclSyntax(
            .let,
            name: PatternSyntax(stringLiteral: allCasesVarName),
            type: TypeAnnotationSyntax(
                type: ArrayTypeSyntax(
                    element: IdentifierTypeSyntax(name: enumDecl.name)
                )
            ),
            initializer: InitializerClauseSyntax(value: ExprSyntax(allCasesArrayWithSyntax))
        )

        // Creates the `allCases` variable with the surrounding syntax.
        let allCasesVarWithSyntax = DeclSyntax(allCasesVarWithoutSyntax)

        // <- Creates a call to the `randomElement` function on the `allCases` variable.
        let randomElementCall = FunctionCallExprSyntax(
            calledExpression: MemberAccessExprSyntax(
                base: DeclReferenceExprSyntax(baseName: .identifier(allCasesVarName)),
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(.randomElementFunctionName))
            ),
            leftParen: .leftParenToken(),
            arguments: LabeledExprListSyntax(),
            rightParen: .rightParenToken()
        )

        let forceUnwrap = ForceUnwrapExprSyntax(expression: randomElementCall)
        let returnStatement = StmtSyntax(ReturnStmtSyntax(expression: ExprSyntax(forceUnwrap)))
        // ->

        let functionBody = CodeBlockSyntax(
            statements: CodeBlockItemListSyntax([
                CodeBlockItemSyntax(item: .decl(allCasesVarWithSyntax)),
                CodeBlockItemSyntax(item: .stmt(returnStatement)),
            ])
        )

        return functionBody
    }

    /// Creates the body of the `arbitrary` function for `.static` generation.
    ///
    /// - Parameters:
    ///   - enumDecl: enumeration declaration for which the stub is created.
    ///   - allEnumCaseDeclarations: all enumeration cases.
    /// - Returns: the function body containing a single `return ...` statement.
    /// - Throws: `ArbitraryMacroError`.
    private static func buildFunctionBodyForStatic(
        enumDecl: EnumDeclSyntax,
        allEnumCaseDeclarations: [EnumCaseDeclSyntax]
    ) throws -> CodeBlockSyntax {
        var selectedCaseElement: EnumCaseElementListSyntax.Element?

        for enumCaseDecl in allEnumCaseDeclarations {
            for attribute in enumCaseDecl.attributes {
                if case .attribute(let attributeSyntax) = attribute,
                   attributeSyntax.attributeName.trimmedDescription == String.arbitraryDefaultCaseMacro {
                    guard let element = enumCaseDecl.elements.first else {
                        continue
                    }
                    selectedCaseElement = element
                    break
                }
            }

            if selectedCaseElement != nil {
                break
            }
        }

        guard let selectedCaseElement else {
            throw ArbitraryMacroError.enumWithStaticArbitraryTypeMustHasDefaultValue
        }

        let returnExpression = try buildCaseExpression(
            caseElement: selectedCaseElement,
            enumDecl: enumDecl,
            arbitraryConfig: .static
        )
        let returnStatement = StmtSyntax(ReturnStmtSyntax(expression: returnExpression))

        let functionBody = CodeBlockSyntax(
            statements: [
                CodeBlockItemSyntax(item: .stmt(returnStatement)), // `return ...`
            ]
        )
        return functionBody
    }

    /// Creates an `.arbitrary` call for an enumeration case.
    ///
    /// - Parameters:
    ///   - caseElement: enumeration case.
    ///   - enumDecl: enumeration declaration.
    ///   - arbitraryConfig: generation type.
    /// - Returns: an expression calling `.arbitrary` for the `caseElement`.
    /// - Throws: `ArbitraryMacroError`.
    private static func buildCaseExpression(
        caseElement: EnumCaseElementListSyntax.Element,
        enumDecl: EnumDeclSyntax,
        arbitraryConfig: ArbitraryConfig
    ) throws -> ExprSyntax {
        if let parameters = caseElement.parameterClause?.parameters {
            var argumentList = LabeledExprListSyntax()
            for param in parameters.enumerated() {
                let paramType = param.element.type
                guard let defaultValueExpr = makeDefaultValueExprSyntaxForType(
                    paramType,
                    parentTypeName: enumDecl.name,
                    arbitraryConfig: arbitraryConfig
                ) else {
                    throw ArbitraryMacroError.unsupportedType
                }
                argumentList.append(
                    LabeledExprSyntax(
                        label: param.element.firstName,
                        colon: param.element.firstName != nil ? .colonToken() : nil,
                        expression: defaultValueExpr,
                        trailingComma: param.offset == parameters.count - 1 ? nil : .commaToken()
                    )
                )
            }
            let functionCall = ExprSyntax(
                FunctionCallExprSyntax(
                    calledExpression: MemberAccessExprSyntax(
                        period: .periodToken(),
                        declName: DeclReferenceExprSyntax(baseName: caseElement.name)
                    ),
                    leftParen: .leftParenToken(),
                    arguments: argumentList,
                    rightParen: .rightParenToken()
                )
            )

            return functionCall
            // Handles enumeration cases without associated values.
            // Creates a reference to the enumeration case.
        } else {
            let memberAccess = ExprSyntax(
                MemberAccessExprSyntax(
                    period: .periodToken(),
                    declName: DeclReferenceExprSyntax(baseName: caseElement.name)
                )
            )

            return memberAccess
        }
    }
}
