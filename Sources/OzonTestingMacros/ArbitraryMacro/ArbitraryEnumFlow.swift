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
    ///   - accessModifier: Access modifier for the `arbitrary` method.
    ///   - enumDecl: Declaration of the enumeration for which the stub is being created.
    ///   - arbitraryConfig: The `arbitrary` type — `static` or `dynamic`.
    /// - Returns: The `arbitrary` method.
    /// - Throws: `ArbitraryMacroError`.
    static func makeArbitraryMethodForEnum(
        type: TypeSyntax? = nil,
        accessModifier: DeclModifierSyntax,
        enumDecl: any DeclGroupSyntax,
        arbitraryConfig: ArbitraryConfig
    ) throws -> FunctionDeclSyntax {
        // Check that the declaration is indeed from an enumeration.
        // We do not accept `enumDecl: EnumDeclSyntax` as input for ease of use.
        guard let enumDecl = enumDecl.as(EnumDeclSyntax.self) else {
            throw ArbitraryMacroError.unsupportedType
        }

        // Create modifiers for the `arbitrary` function declaration.
        let modifiers = [accessModifier, .init(name: .keyword(.static))]
            .reduce(into: DeclModifierListSyntax()) { partialResult, modifier in
                guard !modifier.isInternal else { return }
                partialResult.append(modifier)
            }

        // <- Get all case declarations of the enumeration.
        // Note: a single `case` declaration can contain multiple cases, e.g. `case a, b`
        let allEnumCaseDeclarations = enumDecl
            .memberBlock
            .members
            .compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }

        let allCaseElements = allEnumCaseDeclarations.flatMap(\.elements)
        guard !allCaseElements.isEmpty else {
            throw ArbitraryMacroError.enumHasNoCases
        }
        // ->

        // Form the function signature.
        let functionSignature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: []),
            returnClause: getReturnClause(type: type, typeName: enumDecl.name)
        )

        // <- Form the function body.
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

        // Form the function.
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
    ///   - enumDecl: Declaration of the enumeration for which the stub is being created.
    ///   - allCaseElements: All cases of the enumeration.
    /// - Returns: The function body consisting of two blocks: 1. `let allCases = [...]` 2. `return allCases.random()!`.
    /// - Throws: `ArbitraryMacroError`.
    private static func buildFunctionBodyForDynamic(
        enumDecl: EnumDeclSyntax,
        allCaseElements: [EnumCaseElementListSyntax.Element]
    ) throws -> CodeBlockSyntax {
        // Create the elements of the `allCases` array.
        let allCasesArrayElements = try allCaseElements.enumerated().map { index, caseElement in
            // Create an element of the `allCases` array without the surrounding syntax.
            let allCasesArrayElementWithoutSyntax = try buildCaseExpression(
                caseElement: caseElement,
                enumDecl: enumDecl,
                arbitraryConfig: .dynamic
            )

            // Create an element of the `allCases` array with the surrounding syntax.
            let allCasesArrayElementWithSyntax = ArrayElementSyntax(
                expression: allCasesArrayElementWithoutSyntax,
                trailingComma: index == allCaseElements.count - 1 ? nil : .commaToken()
            )

            return allCasesArrayElementWithSyntax
        }

        // Create the `allCases` array.
        let allCasesArrayWithSyntax = ArrayExprSyntax(
            leftSquare: .leftSquareToken(),
            elements: ArrayElementListSyntax(allCasesArrayElements),
            rightSquare: .rightSquareToken()
        )

        let allCasesVarName = "allCases"

        // Create the `allCases` variable without the surrounding syntax.
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

        // Create the `allCases` variable with the surrounding syntax.
        let allCasesVarWithSyntax = DeclSyntax(allCasesVarWithoutSyntax)

        // <- Create a call to the `randomElement` function on the `allCases` variable.
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
    ///   - enumDecl: Declaration of the enumeration for which the stub is being created.
    ///   - allEnumCaseDeclarations: All cases of the enumeration.
    /// - Returns: The function body consisting of a single block: `return ...`.
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
    ///   - caseElement: The enumeration case.
    ///   - enumDecl: Declaration of the enumeration.
    ///   - arbitraryConfig: The generation type.
    /// - Returns: An expression calling `.arbitrary` for the `caseElement`.
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
            // Handle the case when the enumeration case has no associated types.
            // Form a reference to the enumeration case.
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
