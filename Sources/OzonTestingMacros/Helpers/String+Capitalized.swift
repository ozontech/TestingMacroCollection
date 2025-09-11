//
//  String+Capitalized.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation

extension String {
    /// camelCase -> CapitalizedCameCase
    var capitalizedFirstLetter: String {
        let firstLetter = prefix(1).capitalized
        let remainingLetters = dropFirst()
        return firstLetter + remainingLetters
    }
}
