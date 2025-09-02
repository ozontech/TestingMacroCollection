//
//  IdentifierPatternSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension IdentifierPatternSyntax {
    /// `underlying` property name.
    var underlying: IdentifierPatternSyntax {
        .init(identifier: .init(stringLiteral: .underlying + identifier.text.capitalizedFirstLetter))
    }
}
