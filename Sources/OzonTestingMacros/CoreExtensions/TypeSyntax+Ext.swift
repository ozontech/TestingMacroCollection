//
//  TypeSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension TypeSyntax {
    /// Type name.
    var name: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Checks if the type is optional.
    var isOptional: Bool {
        self.is(OptionalTypeSyntax.self)
    }

    /// Checks if the type is closure.
    var isClosure: Bool {
        ClosureFinder(viewMode: .sourceAccurate).hasClosure(self)
    }

    /// Checks if the type is `some` or `any`.
    var isSomeOrAny: Bool {
        self.is(SomeOrAnyTypeSyntax.self)
    }

    /// Checks if the type is force unwrapped.
    var isForceUnwrapped: Bool {
        self.is(ImplicitlyUnwrappedOptionalTypeSyntax.self)
    }

    /// Checks if the type is `Sendable`.
    var isSendable: Bool {
        self.as(IdentifierTypeSyntax.self)?.name.text == .sendable
    }

    /// Generates a default type initializer.
    /// - Important: available for non-optionals, tuples, arrays, dictionaries, and sets.
    ///
    var defaultInitialization: InitializerClauseSyntax? {
        if let type = self.as(IdentifierTypeSyntax.self), type.name.text != .set {
            type.defaultInitialization
        } else if let type = self.as(IdentifierTypeSyntax.self), type.name.text == .set {
            type.setDefaultInitialization
        } else if let type = self.as(ArrayTypeSyntax.self) {
            type.defaultInitialization
        } else if let type = self.as(DictionaryTypeSyntax.self) {
            type.defaultInitialization
        } else if let type = self.as(TupleTypeSyntax.self) {
            type.defaultInitialization
        } else {
            nil
        }
    }

    var prettyName: String {
        if self.is(IdentifierTypeSyntax.self) {
            return name
        }

        return TypeNameGenerator.readableName(for: self)
    }
}

extension TypeSyntaxProtocol {
    func toTupleTypeSyntax() -> TupleTypeSyntax {
        .init(elements: [.init(type: self)])
    }
}
