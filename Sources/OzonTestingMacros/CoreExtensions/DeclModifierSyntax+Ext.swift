//
//  DeclModifierSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension DeclModifierSyntax {
    /// Checks if access modifier is `public`.
    var isPublic: Bool {
        name.text == .public
    }

    /// Checks if access modifier is `internal`.
    var isInternal: Bool {
        name.text == .internal
    }

    /// Checks if access modifier is `open`.
    var isOpen: Bool {
        name.text == .open
    }

    /// Checks if access modifier is `final`.
    var isFinal: Bool {
        name.text == .final
    }
}
