//
//  IdentifierTypeSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension IdentifierTypeSyntax {
    /// Checks if current type is standard.
    var isSwiftOrFoundationType: Bool {
        `Type`(rawValue: name.text) != nil
    }

    /// Default type initializer implementation.
    ///
    /// - Important: works only with standard library types.
    ///
    /// Example:
    ///
    ///     String = String.arbitrary() ✅
    ///     CustomType = nil ❌
    ///
    var defaultInitialization: InitializerClauseSyntax? {
        guard isSwiftOrFoundationType else { return nil }

        return .initForDefaultType(name.text)
    }

    /// Default type initializer implementation for `Set`.
    ///
    /// - Important: works only with standard library types.
    ///
    /// Example:
    ///
    ///     [String] = [String.arbitrary()] ✅
    ///     [CustomType] = nil ❌
    ///
    var setDefaultInitialization: InitializerClauseSyntax? {
        makeDefaultSetInitializationIfPossible()
    }

    private func makeDefaultSetInitializationIfPossible() -> InitializerClauseSyntax? {
        guard let genericSyntax = genericArgumentClause?.arguments.first as? GenericArgumentSyntax,
              let setArgumentType = genericSyntax.argument.as(IdentifierTypeSyntax.self),
              setArgumentType.isSwiftOrFoundationType else {
            return nil
        }

        return .initForArrays(for: setArgumentType.name.text)
    }
}
