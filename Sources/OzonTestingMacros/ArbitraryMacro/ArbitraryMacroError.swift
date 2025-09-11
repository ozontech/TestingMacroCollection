//
//  ArbitraryMacroError.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

/// Errors for the `Arbitrary` macro.
enum ArbitraryMacroError: CustomStringConvertible, Error {
    case unsupportedType
    case wrongArbitraryType

    var description: String {
        switch self {
        case .unsupportedType:
            return "@Arbitrary macro is attached to an unsupported declaration"
        case .wrongArbitraryType:
            return "ArbitraryType can only be static or dynamic"
        }
    }
}
