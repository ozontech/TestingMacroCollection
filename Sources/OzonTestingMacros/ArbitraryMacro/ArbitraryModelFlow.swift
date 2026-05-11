//
//  ArbitraryModelFlow.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension ArbitraryMacro {
    static func makeArbitraryMethodForModel(
        type: TypeSyntax? = nil,
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

        let parametersToUse = parameters.filter { !$0.isWithAccessor }
        let functionArgumentsSyntax = parametersToUse
            .enumerated()
            .reduce(into: LabeledExprListSyntax()) { partialResult, item in
                let offset = item.offset
                let parameter = item.element
                let trailingComma: TokenSyntax? = offset == parametersToUse.count - 1 ? nil : .commaToken()

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
            calledExpression: DeclReferenceExprSyntax(baseName: getBaseName(type: type, typeName: typeName)),
            leftParen: .leftParenToken(),
            arguments: functionArgumentsSyntax,
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
                    parameters: parametersToUse,
                    arbitararyConfig: arbitraryConfig,
                    declMembers: declMembers
                ),
                returnClause: getReturnClause(type: type, typeName: typeName)
            ),
            body: functionBody
        )
    }

    private static func getBaseName(
        type: TypeSyntax?,
        typeName: TokenSyntax
    ) -> TokenSyntax {
        guard let type else {
            return typeName
        }

        return TokenSyntax(stringLiteral: type.name)
    }
}
