//
//  DeclReferenceExprSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension DeclReferenceExprSyntax {
    /// Wraps the expression in optional chaining when the argument is `true`.
    ///
    ///  Example:
    ///
    ///    Expression: ```variable```
    ///
    ///    Result: ```variable?```
    ///
    func convertToOptionalIfNeeded(_ shouldBeOptional: Bool = true) -> ExprSyntaxProtocol {
        guard shouldBeOptional else { return self }

        return OptionalChainingExprSyntax(expression: self)
    }
}
