//
//  ArbitraryMacroError.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

/// Errors for the `Arbitrary` macro.
enum ArbitraryMacroError: CustomStringConvertible, Error {
    case unsupportedType
    case wrongArbitraryType
    case enumHasNoCases
    case enumWithStaticArbitraryTypeMustHasDefaultValue

    var description: String {
        switch self {
        case .unsupportedType:
            "@Arbitrary macro is attached to an unsupported declaration"
        case .wrongArbitraryType:
            "ArbitraryType can only be static or dynamic"
        case .enumHasNoCases:
            "@Arbitrary macro attached to an empty enum"
        case .enumWithStaticArbitraryTypeMustHasDefaultValue:
            "@Arbitrary(.static) macro attached to an enum without a case marked with @ArbitraryDefaultCase"
        }
    }
}
