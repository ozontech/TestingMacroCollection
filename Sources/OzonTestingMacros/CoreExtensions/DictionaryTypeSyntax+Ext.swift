//
//  DictionaryTypeSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension DictionaryTypeSyntax {
    /// Default type initializer implementation for `Dictionary`.
    ///
    /// - Important: works only with standard library types.
    ///
    /// Example:
    ///
    ///     [String: Int] = [String.arbitrary(): Int.arbitrary()] ✅
    ///     [CustomType: Int] = nil ❌
    ///
    var defaultInitialization: InitializerClauseSyntax? {
        makeDefaultInitializationIfPossible()
    }

    private func makeDefaultInitializationIfPossible() -> InitializerClauseSyntax? {
        guard let key = key.as(IdentifierTypeSyntax.self),
              let value = value.as(IdentifierTypeSyntax.self),
              key.isSwiftOrFoundationType, value.isSwiftOrFoundationType else { return nil }

        return .initForDictionaries(key: key.name.text, value: value.name.text)
    }
}
