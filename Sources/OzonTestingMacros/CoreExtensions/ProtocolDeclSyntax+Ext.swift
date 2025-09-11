//
//  ProtocolDeclSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension ProtocolDeclSyntax {
    /// Protocol variables.
    var variables: [VariableDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }
}
