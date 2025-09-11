//
//  InitializerClauseSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension InitializerClauseSyntax {
    /// Generates a dictionary initializer.
    ///
    /// - Parameters:
    ///   - key: key type.
    ///   - value: value type.
    /// - Returns: dictionary initialization syntax.
    ///
    static func initForDictionaries(key: String, value: String) -> InitializerClauseSyntax {
        let dictElements = DictionaryElementSyntax(
            key: makeFoundationTypeArbitraryInitialization(for: key),
            value: makeFoundationTypeArbitraryInitialization(for: value)
        )
        let dictExpr = DictionaryExprSyntax(content: .elements(
            DictionaryElementListSyntax([dictElements])
        )
        )

        return InitializerClauseSyntax(equal: .equalToken(), value: dictExpr)
    }

    /// Generates a standard type initializer, which is `IdentifierTypeSyntax`.
    ///
    ///   - Parameter type: type.
    ///   - Returns: standard type initialization syntax.
    ///
    static func initForDefaultType(_ type: String) -> InitializerClauseSyntax {
        .init(equal: .equalToken(), value: makeFoundationTypeArbitraryInitialization(for: type))
    }

    /// Generates an array initializer.
    ///
    ///   - Parameter elementType: array element type.
    ///   - Returns: `array` initialization syntax.
    ///
    static func initForArrays(for elementType: String) -> InitializerClauseSyntax {
        let arbitraryCall = makeFoundationTypeArbitraryInitialization(for: elementType)
        let arrayElement = ArrayElementSyntax(expression: arbitraryCall)
        let arrayElementList = ArrayElementListSyntax(arrayLiteral: arrayElement)
        let arrayExpr = ArrayExprSyntax(
            leftSquare: .leftSquareToken(),
            elements: arrayElementList,
            rightSquare: .rightSquareToken()
        )
        return InitializerClauseSyntax(equal: .equalToken(), value: arrayExpr)
    }

    /// Generates a `tuple` initializer.
    ///
    ///   - Parameter tupleTypes: `tuple` types.
    ///   - Returns: `tuple` initialization syntax.
    ///
    static func initForTuples(tupleTypes: [String]) -> Self {
        let typeList = tupleTypes.enumerated().reduce(into: LabeledExprListSyntax([])) { partialResult, item in
            let offset = item.offset
            let type = item.element
            let arbitraryInitialization = makeFoundationTypeArbitraryInitialization(for: type)
            let comma = offset == tupleTypes.count - 1 ? nil : TokenSyntax.commaToken()

            partialResult.append(
                LabeledExprSyntax(
                    expression: arbitraryInitialization,
                    trailingComma: comma
                )
            )
        }
        let tupleExpr = TupleExprSyntax(elements: typeList)

        return .init(equal: .equalToken(), value: tupleExpr)
    }

    private static func makeFoundationTypeArbitraryInitialization(for type: String) -> FunctionCallExprSyntax {
        let calledExpression = MemberAccessExprSyntax(
            base: DeclReferenceExprSyntax(baseName: .identifier(type)),
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(.arbitrary))
        )
        return FunctionCallExprSyntax(
            calledExpression: calledExpression,
            leftParen: .leftParenToken(),
            arguments: .init([]),
            rightParen: .rightParenToken()
        )
    }
}
