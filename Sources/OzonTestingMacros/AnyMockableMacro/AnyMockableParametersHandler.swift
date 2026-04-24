//
//  AnyMockableParametersHandler.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

enum AnyMockableParametersHandler {
    static func getInputParameters(from node: AttributeSyntax) -> AnyMockableParameters {
        var defaultValue: DefaultValue = .static

        let inputParameters = MacroArgumentExtracter.extractArguments(from: node)

        if let defaultValueValue = inputParameters[.defaultValue] as? String {
            defaultValue = DefaultValue(rawValue: defaultValueValue) ?? .static
        }

        return AnyMockableParameters(defaultValue: defaultValue)
    }
}
