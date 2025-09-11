//
//  ArrayTypeSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension ArrayTypeSyntax {
    /// Default type initializer implementation.
    ///
    /// - Important: works only with standard types.
    ///
    /// Example:
    ///
    ///     [String] = [String.arbitrary()] ✅
    ///     [CustomType] = nil ❌
    ///
    var defaultInitialization: InitializerClauseSyntax? {
        makeDefaultInitializationIfPossible()
    }

    private func makeDefaultInitializationIfPossible() -> InitializerClauseSyntax? {
        guard let element = element.as(IdentifierTypeSyntax.self), element.isSwiftOrFoundationType else {
            return nil
        }

        return .initForArrays(for: element.name.text)
    }
}
