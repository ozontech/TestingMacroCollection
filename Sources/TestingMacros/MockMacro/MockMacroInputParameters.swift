//
//  MockMacroInputParameters.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

// MARK: - AccessModifier

enum AccessModifier: String {
    case `public`
    case open
    case `internal`

    var modifierDecl: DeclModifierSyntax {
        switch self {
        case .public:
            return .init(name: .keyword(.public))
        case .open:
            return .init(name: .keyword(.open))
        case .internal:
            return .init(name: .keyword(.internal))
        }
    }
}

// MARK: - Heritability

/// Mock heritability.
enum Heritability: String {
    /// Mock will be inherited.
    case inheritable
    /// Mock will be of the `final` class.
    case final
}

// MARK: - SendableMode

/// `@unchecked Sendable` generation mode for mocks.
enum SendableMode: String {
    /// Automatically determines if generation is needed.
    case auto
    /// By default generates `@unchecked Sendable`.
    case enabled
    /// Disables generation.
    case disabled
}

// MARK: - DefaultValue

/// Default value generation for standard or collection types.
enum DefaultValue: String {
    /// Generates the `static arbitrary` values.
    case `static`
    /// Generates the `nil` values.
    case none
}

// MARK: - MockMacroInputParameters

/// Input parameters for `MockMacro`.
struct MockMacroInputParameters {
    /// Associated types for mock.
    let associatedTypes: [(String, String)]
    /// Access modifier for the mock entity and its methods or properties.
    let accessModifier: AccessModifier
    /// Mock heritability: inherited or `final`.
    let heritability: Heritability
    /// `Sendable` generation mode for mocks.
    let sendableMode: SendableMode
    /// Default value generation for standard or collection types.
    let defaultValues: DefaultValue
}
