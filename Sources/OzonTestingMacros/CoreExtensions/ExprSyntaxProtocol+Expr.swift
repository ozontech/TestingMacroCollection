//
//  ExprSyntaxProtocol+Expr.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax

extension ExprSyntaxProtocol {
    /// Wraps expression in `await` block.
    func wrapToAwaitExprIfNeeded(_ predicate: Bool = true) -> ExprSyntaxProtocol {
        guard predicate else { return self }

        return AwaitExprSyntax(expression: self)
    }

    /// Wraps expression in `try` block.
    func wrapToTryExprIfNeeded(_ predicate: Bool = true) -> ExprSyntaxProtocol {
        guard predicate else { return self }

        return TryExprSyntax(expression: self)
    }
}
