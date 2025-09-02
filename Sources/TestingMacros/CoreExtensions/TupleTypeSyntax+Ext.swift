//
//  TupleTypeSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension TupleTypeSyntax {
    /// Default initializer for the current type.
    /// - Important: works only with standard library types and returns `nil` for others.
    ///
    ///  For example:
    ///
    ///     (Int, String) = (Int.arbitrary(), String.arbitrary())
    ///     (Custom, Custom) = nil
    ///
    var defaultInitialization: InitializerClauseSyntax? {
        makeDefaultInitializationIfPossible()
    }

    private func makeDefaultInitializationIfPossible() -> InitializerClauseSyntax? {
        let tupleElements = elements.compactMap { $0.type.as(IdentifierTypeSyntax.self) }
        let allTupleTypesIsFoundation = tupleElements.allSatisfy { $0.isSwiftOrFoundationType }
        let shouldGenerateInit = allTupleTypesIsFoundation && tupleElements.count == elements.count

        return shouldGenerateInit ? .initForTuples(tupleTypes: tupleElements.map { $0.name.text }) : nil
    }
}
