//
//  FunctionBodyMockMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - FunctionBodyMockError

/// Errors that `FunctionBodyMock` may throw.
///
enum FunctionBodyMockError: CustomStringConvertible, Error {
    case appliedToWrongDeclaration

    var description: String {
        switch self {
        case .appliedToWrongDeclaration:
            "@FunctionBodyMock can only be attached to functions"
        }
    }
}

// MARK: - FunctionBodyMockMacro

public struct FunctionBodyMockMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some DeclSyntaxProtocol & WithOptionalCodeBlockSyntax,
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw FunctionBodyMockError.appliedToWrongDeclaration
        }

        let isThrowable = funcDecl.signature.effectSpecifiers?.throwsClause != nil
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil

        let mockExpr = DeclReferenceExprSyntax(baseName: .identifier(.mock))
        let funcNameExpr = DeclReferenceExprSyntax(baseName: funcDecl.name)
        let mockFuncCallExpr = MemberAccessExprSyntax(
            base: mockExpr,
            period: .periodToken(),
            declName: funcNameExpr
        )
        let functionCallExpr = FunctionCallExprSyntax(
            calledExpression: mockFuncCallExpr,
            leftParen: .leftParenToken(),
            arguments: createArgumentList(from: funcDecl.signature.parameterClause.parameters),
            rightParen: .rightParenToken()
        )
        let resultExpr = functionCallExpr
            .wrapToAwaitExprIfNeeded(isAsync)
            .wrapToTryExprIfNeeded(isThrowable)

        return [
            CodeBlockItemSyntax(
                item: .expr(
                    ExprSyntax(resultExpr)
                )
            ),
        ]
    }

    /// Generates the list of method call arguments.
    ///
    ///  - Parameter parameters: the method parameters list.
    ///  - Returns: the resulting method call arguments.
    ///
    private static func createArgumentList(
        from parameters: FunctionParameterListSyntax
    ) -> LabeledExprListSyntax {
        guard !parameters.isEmpty else { return [] }

        return parameters.enumerated().reduce(into: LabeledExprListSyntax()) { partialResult, item in
            let index = item.offset
            let parameter = item.element
            var firstName = parameter.firstName
            firstName.trailingTrivia = []
            let secondName = parameter.secondName
            let comma: TokenSyntax? = index == parameters.count - 1 ? nil : .commaToken()

            var mockFunctionCallExpr: LabeledExprSyntax

            if let secondName {
                if firstName.text == "_" {
                    mockFunctionCallExpr = LabeledExprSyntax(
                        expression: DeclReferenceExprSyntax(baseName: secondName),
                        trailingComma: comma
                    )
                } else {
                    mockFunctionCallExpr = LabeledExprSyntax(
                        label: firstName,
                        colon: .colonToken(),
                        expression: DeclReferenceExprSyntax(baseName: secondName),
                        trailingComma: comma
                    )
                }
            } else {
                mockFunctionCallExpr = LabeledExprSyntax(
                    label: firstName,
                    colon: .colonToken(),
                    expression: DeclReferenceExprSyntax(baseName: firstName),
                    trailingComma: comma
                )
            }

            partialResult.append(
                mockFunctionCallExpr
            )
        }
    }
}
