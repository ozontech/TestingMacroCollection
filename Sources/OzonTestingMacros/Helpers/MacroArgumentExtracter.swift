//
//  MacroArgumentExtracter.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

enum MacroArgumentExtracter {
    static func extractArguments(from node: AttributeSyntax) -> [String: Any] {
        guard let arguments = node.arguments,
              let macroArguments = arguments.as(LabeledExprListSyntax.self) else {
            return [:]
        }

        return macroArguments.reduce(into: [String: Any]()) { partialResult, argument in
            let label = argument.label?.text ?? .unlabeledParam

            if let dictValue = extractDictionary(dictExpr: argument.expression) {
                return partialResult[label] = dictValue
            }

            var value = argument.expression.description.trimmingCharacters(in: .whitespacesAndNewlines)
            handleValueStartingWithDot(&value)

            partialResult[label] = value
        }
    }

    private static func handleValueStartingWithDot(_ value: inout String) {
        if value.starts(with: ".") {
            value = String(value.dropFirst())
        }
    }

    private static func extractDictionary(dictExpr: ExprSyntax) -> [(String, String)]? {
        guard let dictExpr = dictExpr.as(DictionaryExprSyntax.self),
              let content = dictExpr.content.as(DictionaryElementListSyntax.self) else { return nil }

        var dict: [(String, String)] = []

        for entry in content {
            guard let keyExpr = entry.key.as(StringLiteralExprSyntax.self),
                  let valueExpr = entry.value.as(StringLiteralExprSyntax.self) else {
                continue
            }

            let key = keyExpr.segments.description.trimmingCharacters(in: .punctuationCharacters)
            let value = valueExpr.segments.description.trimmingCharacters(in: .punctuationCharacters)

            dict.append((key, value))
        }

        return dict
    }
}
