//
//  ForceUnwrapped.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension TypeSyntaxProtocol {
    /// Generated force-unwrapped data type.
    var forceUnwrapped: ImplicitlyUnwrappedOptionalTypeSyntax {
        var type = self
        type.trailingTrivia = []
        return .init(wrappedType: type)
    }

    /// `forceUnwrapped' default implementation for types that need to be wrapped in parentheses.
    var tupledForceUnwrapped: ImplicitlyUnwrappedOptionalTypeSyntax {
        var type = self
        type.trailingTrivia = []
        return .init(
            wrappedType: TupleTypeSyntax(
                leftParen: .leftParenToken(),
                elements: .init([.init(type: type)]),
                rightParen: .rightParenToken()
            )
        )
    }
}
