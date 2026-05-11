//
//  ClosureFinder.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax

/// Entity that searches for `FunctionTypeSyntax` within `TypeSyntax` in the AST.
final class ClosureFinder: SyntaxVisitor {
    private var containsClosure = false

    func hasClosure(_ syntax: TypeSyntax) -> Bool {
        walk(syntax)

        return containsClosure
    }

    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        containsClosure = true

        return .skipChildren
    }
}
