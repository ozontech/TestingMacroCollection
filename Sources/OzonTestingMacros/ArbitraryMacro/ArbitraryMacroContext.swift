//
//  ArbitraryMacroContext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

/// Context containing data about the declaration to which the macro is attached.
struct ArbitraryMacroContext {
    let arbitraryType: ArbitraryMacro.ArbitaryType
    let arbitraryConfig: ArbitraryMacro.ArbitraryConfig
    let accessModifier: DeclModifierSyntax
    let buildType: BuildType
    let typeName: TokenSyntax
    let parameters: [ArbitraryParameter]
    let declMembers: MemberBlockItemListSyntax
}
