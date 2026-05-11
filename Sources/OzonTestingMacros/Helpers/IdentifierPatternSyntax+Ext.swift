//
//  IdentifierPatternSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension IdentifierPatternSyntax {
    /// `underlying` property name.
    var underlying: IdentifierPatternSyntax {
        .init(identifier: .init(stringLiteral: .underlying + identifier.text.capitalizedFirstLetter))
    }
}
