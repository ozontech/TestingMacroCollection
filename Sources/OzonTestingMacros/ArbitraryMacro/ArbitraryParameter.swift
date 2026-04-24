//
//  ArbitraryParameter.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

/// The declaration property model for `Arbitrary`.
struct ArbitraryParameter {
    /// Property name.
    let name: TokenSyntax
    /// Property data type.
    var type: TypeSyntax
    /// `true` if the property is excluded from default value generation.
    let isIgnored: Bool
    /// When `true`, initializes the property as `nil`.
    let isNilable: Bool
    /// Whether the default value should be empty, applicable to Collection.
    let isEmpted: Bool
    /// Whether the property contains an accessor declaration — `{ ... }`.
    let isWithAccessor: Bool
}
