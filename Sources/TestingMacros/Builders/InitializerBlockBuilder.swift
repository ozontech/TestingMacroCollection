//
//  InitializerBlockBuilder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

enum InitializerBlockBuilder {
    /// Generates a block of initializer code.
    ///
    ///     // MARK: - Init
    ///
    ///     public init() {
    ///     }
    ///
    static func makeInitializer(accessModifiers: DeclModifierListSyntax) -> [MemberBlockItemSyntax] {
        var result = [MemberBlockItemSyntax]()

        result.append(
            .init(
                decl: MissingDeclSyntax(
                    placeholder: .init(stringLiteral: "\n    // MARK: - Default Empty Init\n")
                )
            )
        )

        let parameterClause = FunctionParameterClauseSyntax(
            leftParen: .leftParenToken(),
            parameters: .init(),
            rightParen: .rightParenToken()
        )
        let signature = FunctionSignatureSyntax(parameterClause: parameterClause)
        let body = CodeBlockSyntax(leftBrace: .leftBraceToken(), statements: .init(), rightBrace: .rightBraceToken())

        let initializer = InitializerDeclSyntax(
            modifiers: accessModifiers,
            initKeyword: .keyword(.`init`),
            signature: signature,
            body: body
        )
        result.append(.init(decl: initializer))

        return result
    }

    /// Generates an initializers block.
    /// - Note: Non-empty initializers contain `assertionFailure()`, since the mock uses an empty default initializer.
    /// Empty body is an exception.
    ///
    ///  - Parameters:
    ///     - initializers: initializers in the protocol.
    ///     - mockName: name of the mock class or actor.
    ///     - isActor: flag for finding initializers in the actor.
    ///     - accessModifiers: access modifiers for a mock entity.
    ///  - Returns: a block with initializers.
    ///
    static func makeInitializerBlock(
        with initializers: [InitializerDeclSyntax],
        mockName: String,
        isActor: Bool,
        accessModifiers: DeclModifierListSyntax
    ) -> [MemberBlockItemSyntax] {
        guard !initializers.isEmpty else { return [] }

        var result = [MemberBlockItemSyntax]()

        result.append(
            .init(
                decl: MissingDeclSyntax(
                    placeholder: .init(stringLiteral: "\n    // MARK: - Protocol Inits\n")
                )
            )
        )

        initializers.enumerated().forEach {
            var newInit = InitializerDeclSyntax(
                signature: $0.element.signature,
                body: $0.element.isEmptyInit ? .init(statements: .init([])) : makeInitBody(mockName: mockName)
            )
            newInit.setModifiersDependsOn(accessModifiers, isActorInit: isActor)
            result.append(MemberBlockItemSyntax(decl: newInit))
            if $0.offset < initializers.count - 1 {
                result.append(.init(decl: MissingDeclSyntax(placeholder: .init(stringLiteral: ""))))
            }
        }

        return result
    }

    /// Generates an initializer body with `assertionFailure()`, as the mock relies on the default empty initializer.
    ///
    ///  - Parameter mockName: mock class or actor name.
    ///  - Returns: the initializer body.
    ///
    private static func makeInitBody(mockName: String) -> CodeBlockSyntax {
        let funcNameCall = DeclReferenceExprSyntax(baseName: .init(stringLiteral: .assertionFailure))
        let stringElement = StringLiteralSegmentListSyntax.Element.stringSegment(.init(
            content: .identifier("Do not use this init. Use \(mockName)() instead.")
        ))
        let segments = StringLiteralSegmentListSyntax(arrayLiteral: stringElement)
        let arguments = LabeledExprListSyntax(arrayLiteral: .init(expression: StringLiteralExprSyntax(
            openingQuote: .stringQuoteToken(),
            segments: segments,
            closingQuote: .stringQuoteToken()
        ))
        )
        let functionExpr = FunctionCallExprSyntax(
            calledExpression: funcNameCall,
            leftParen: .leftParenToken(),
            arguments: arguments,
            rightParen: .rightParenToken()
        )
        let codeBlockItem = CodeBlockItemSyntax(item: CodeBlockItemSyntax.Item(functionExpr))
        return CodeBlockSyntax(statements: .init(arrayLiteral: codeBlockItem))
    }
}
