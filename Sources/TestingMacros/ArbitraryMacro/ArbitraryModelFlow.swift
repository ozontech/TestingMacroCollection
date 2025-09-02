//
//  ArbitraryModelFlow.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension ArbitraryMacro {
    static func makeArbitraryMethodForModel(
        accessModifier: DeclModifierSyntax,
        typeName: TokenSyntax,
        parameters: [ArbitraryParameter],
        arbitraryConfig: ArbitraryConfig,
        declMembers: MemberBlockItemListSyntax
    ) -> FunctionDeclSyntax {
        let modifiers = [accessModifier, .init(name: .keyword(.static))]
            .reduce(into: DeclModifierListSyntax()) { partialResult, modifier in
                guard !modifier.isInternal else { return }

                partialResult.append(modifier)
            }

        let params = parameters
            .enumerated()
            .reduce(into: LabeledExprListSyntax()) { partialResult, item in
                let offset = item.offset
                let parameter = item.element
                let trailingComma: TokenSyntax? = offset == parameters.count - 1 ? nil : .commaToken()

                partialResult.append(
                    LabeledExprSyntax(
                        label: parameter.name,
                        colon: .colonToken(),
                        expression: DeclReferenceExprSyntax(baseName: parameter.name),
                        trailingComma: trailingComma
                    )
                )
            }

        let initObjectSyntax = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: typeName),
            leftParen: .leftParenToken(),
            arguments: params,
            rightParen: .rightParenToken()
        )
        let item = CodeBlockItemSyntax.Item(initObjectSyntax)
        let stmts = CodeBlockItemListSyntax(arrayLiteral: .init(item: item))
        let functionBody = CodeBlockSyntax(statements: stmts)

        return FunctionDeclSyntax(
            modifiers: modifiers,
            name: .identifier(String.arbitrary),
            signature: .init(
                parameterClause: makeArbitraryMethodSignatureParameterClause(
                    parentTypeName: typeName,
                    parameters: parameters,
                    arbitararyConfig: arbitraryConfig,
                    declMembers: declMembers
                ),
                returnClause: .init(type: IdentifierTypeSyntax(name: typeName))
            ),
            body: functionBody
        )
    }
}
