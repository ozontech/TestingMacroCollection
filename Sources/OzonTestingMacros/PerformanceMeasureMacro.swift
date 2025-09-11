//
//  PerformanceMeasureMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - PerformanceMeasureMacroError

/// The `Compile-time` error that the macro may throw.
enum PerformanceMeasureMacroError: CustomStringConvertible, Error {
    case expectsClosure

    var description: String {
        switch self {
        case .expectsClosure:
            "#PerformanceMeasureMacro is waiting for a closure"
        }
    }
}

// MARK: - PerformanceMeasureMacro

public struct PerformanceMeasureMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard let closure = node.trailingClosure ?? node.arguments.first?.expression.as(ClosureExprSyntax.self) else {
            throw PerformanceMeasureMacroError.expectsClosure
        }

        return """
        {
            let startTime = CFAbsoluteTimeGetCurrent()
            \(raw: closure.statements.trimmed)
            return Double(CFAbsoluteTimeGetCurrent() - startTime) * 1000
        }()
        """
    }
}
