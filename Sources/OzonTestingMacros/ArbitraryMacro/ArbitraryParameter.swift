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
    /// `true` if the default value should be empty, for `Collection` types.
    let isEmpted: Bool
    /// `true` if the property contains an `{ ... }` accessor block.
    let isWithAccessor: Bool
}
