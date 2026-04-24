//
//  InheritedTypeListSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension InheritedTypeListSyntax {
    /// Adds a comma to the last element of a collection.
    ///
    mutating func addLastElementComma() {
        guard !isEmpty, var last, let lastIndex = lastIndex(of: last) else { return }

        last.trailingTrivia = []
        last.trailingComma = .commaToken()
        remove(at: lastIndex)
        append(last)
    }
}
