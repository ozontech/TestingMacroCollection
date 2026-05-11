//
//  DeinitBlockBuilder.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

/// Builder of the `deinit` block and methods for clearing properties.
///
///     // MARK: - Deinit
///
///     func clearFunctionProperties() {
///        makeWorkReturnValue = nil
///        makeWorkClosure = nil
///     }
///
///     func clearVariablesProperties() {
///         underlyingName = nil
///     }
///
///     deinit {
///         clearFunctionProperties()
///         clearVariablesProperties()
///     }
///
enum DeinitBlockBuilder {
    /// Generates a block with `deinit`.
    ///
    ///  - Parameters:
    ///     - clearMethodBuilders: builders of property clearing methods.
    ///     - dataStructure: data structure for which the block with the `deinit` is created.
    ///  - Returns: an array containing the methods of clearing properties and `deinit`.
    ///
    static func makeDeinitBlock(
        clearMethodBuilders: [ClearMethodBuilder],
        dataStructure: ClearMethodBuilder.DataStructure
    ) -> [MemberBlockItemSyntax] {
        guard !clearMethodBuilders.isEmpty else { return [] }

        var result: [MemberBlockItemSyntax] = []

        result.append(
            .init(decl: MissingDeclSyntax(placeholder: .init(stringLiteral: "\n    // MARK: - Deinit\n")))
        )

        let clearMethodNames: [TokenSyntax] = clearMethodBuilders
            .reduce(into: []) { partialResult, builder in
                if let clearMethod = builder.makeClearMethodIfNeeded(dataStructure: dataStructure) {
                    partialResult.append(clearMethod.name)
                    result.append(.init(decl: clearMethod))
                    result.append(.init(decl: MissingDeclSyntax(placeholder: .init(stringLiteral: ""))))
                }
            }

        guard !clearMethodNames.isEmpty else { return [] }

        let functionCalls: [ExprSyntaxProtocol] = switch dataStructure {
        case .actor:
            makeFunctionCallsForActor(clearMethodNames: clearMethodNames)
        case .finalClass,
             .nonFinalClass:
            makeFunctionCallsForClass(clearMethodNames: clearMethodNames)
        }

        let codeBlockItemList: CodeBlockItemListSyntax = functionCalls
            .compactMap { CodeBlockItemSyntax.Item($0) }
            .reduce(into: CodeBlockItemListSyntax()) { partialResult, item in
                partialResult.append(.init(item: item))
            }

        let deinitDecl = if dataStructure == .actor {
            DeinitializerDeclSyntax(body: .init(statements: makeTaskCall(body: codeBlockItemList)))
        } else {
            DeinitializerDeclSyntax(body: .init(statements: codeBlockItemList))
        }

        result.append(.init(decl: deinitDecl))

        return result
    }

    /// Generates a `Task` call with the `[weak self]` and `await` asynchronous method calls for the actor.
    ///
    ///  - Parameter body: body of the closure with asynchronous method calls.
    ///  - Returns: the `deinit` body.
    ///
    private static func makeTaskCall(body: CodeBlockItemListSyntax) -> CodeBlockItemListSyntax {
        let closureCaptureList = ClosureCaptureListSyntax(
            [
                ClosureCaptureSyntax(
                    specifier: ClosureCaptureSpecifierSyntax(specifier: .keyword(.weak)),
                    name: .identifier(._self)
                ),
            ]
        )
        let closureCaptureClause = ClosureCaptureClauseSyntax(items: closureCaptureList)
        let signature = ClosureSignatureSyntax(
            capture: closureCaptureClause,
            inKeyword: .keyword(.in)
        )
        let trailingClosure = ClosureExprSyntax(
            signature: signature,
            statements: body
        )
        let taskCallExpr = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: .identifier(.task)),
            arguments: .init([]),
            trailingClosure: trailingClosure
        )
        let item = CodeBlockItemSyntax.Item(taskCallExpr)
        var codeBlockItemList = CodeBlockItemListSyntax()
        codeBlockItemList.append(.init(item: item))
        return codeBlockItemList
    }

    /// Generates an asynchronous call to property clearing methods for the actor.
    ///
    ///   - Parameter clearMethodNames: names of property clearing methods.
    ///   - Returns: method call expressions wrapped in `await`.
    ///
    private static func makeFunctionCallsForActor(clearMethodNames: [TokenSyntax]) -> [AwaitExprSyntax] {
        clearMethodNames
            .reduce(into: [AwaitExprSyntax]()) { partialResult, function in
                let memberAccessExpr = MemberAccessExprSyntax(
                    base: OptionalChainingExprSyntax(expression: DeclReferenceExprSyntax(baseName: .identifier(._self))),
                    declName: .init(baseName: function)
                )
                let funcCall = FunctionCallExprSyntax(
                    calledExpression: memberAccessExpr,
                    leftParen: .leftParenToken(),
                    arguments: .init([]),
                    rightParen: .rightParenToken()
                )
                let awaitExpr = AwaitExprSyntax(expression: funcCall)
                partialResult.append(awaitExpr)
            }
    }

    /// Generates a call to methods for clearing properties for classes.
    ///
    ///   - Parameter clearMethodNames: names of property clearing methods.
    ///   - Returns: method call expressions.
    ///
    private static func makeFunctionCallsForClass(clearMethodNames: [TokenSyntax]) -> [FunctionCallExprSyntax] {
        clearMethodNames
            .reduce(into: [FunctionCallExprSyntax]()) { partialResult, function in
                let funcCall = FunctionCallExprSyntax(
                    calledExpression: DeclReferenceExprSyntax(baseName: function),
                    arguments: .init([])
                )
                partialResult.append(.init(callee: funcCall))
            }
    }
}
