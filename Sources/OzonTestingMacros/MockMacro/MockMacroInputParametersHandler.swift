//
//  MockMacroInputParametersHandler.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

/// Input parameter handler `MockMacro`
enum MockMacroInputParametersHandler {
    /// Gets the input parameters of the 'MockMacro` macro from the `Mock()` entity.
    ///
    ///  - Parameter node: macro node.
    ///  - Returns: macro input parameters.
    ///
    static func getInputParameters(from node: AttributeSyntax) -> MockMacroInputParameters {
        var associatedTypes: [(String, String)] = []
        var heritability = Heritability.final
        var accessModifier = AccessModifier.internal
        var sendableMode = SendableMode.auto
        var defaultValue = DefaultValue.static

        let parametersFromMacro = MacroArgumentExtracter.extractArguments(from: node)

        if let associatedTypesValue = parametersFromMacro[.associatedTypes] as? [(String, String)] {
            associatedTypes = associatedTypesValue
        }

        if let heritabilityValue = parametersFromMacro[.heritability] as? String {
            heritability = Heritability(rawValue: heritabilityValue) ?? .final
        }

        if let accessModifierValue = parametersFromMacro[.unlabeledParam] as? String {
            accessModifier = AccessModifier(rawValue: accessModifierValue) ?? .internal
        }

        if let sendableModeValue = parametersFromMacro[.sendableMode] as? String {
            sendableMode = SendableMode(rawValue: sendableModeValue) ?? .auto
        }

        if let defaultValueValue = parametersFromMacro[.defaultValue] as? String {
            defaultValue = DefaultValue(rawValue: defaultValueValue) ?? .static
        }

        return .init(
            associatedTypes: associatedTypes,
            accessModifier: accessModifier,
            heritability: heritability,
            sendableMode: sendableMode,
            defaultValues: defaultValue
        )
    }

    /// Adds a swift syntax dictionary element to the `(String, String)` tuple.
    ///
    ///  - Parameter element: dictionary element in `SwiftSyntax`.
    ///  - Returns: a tuple with dictionary element.
    ///
    private static func makeTypealiasValue(_ element: DictionaryElementListSyntax.Element) -> (String, String) {
        guard let key = element.key
            .as(StringLiteralExprSyntax.self)?
            .segments.first?
            .as(StringSegmentSyntax.self)?
            .content.text,
            let value = element.value
                .as(StringLiteralExprSyntax.self)?
                .segments.first?
                .as(StringSegmentSyntax.self)?
                .content.text else { return ("", "") }

        return (key, value)
    }
}
