//
//  DeclGroupSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension DeclGroupSyntax {
    /// Declaration initializers.
    var initializers: [InitializerDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(InitializerDeclSyntax.self) }
    }

    /// Declaration variables.
    var variables: [VariableDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }

    /// Declaration functions.
    var functions: [FunctionDeclSyntax] {
        memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    /// Declaration access modifier.
    var accessModifier: DeclModifierSyntax {
        modifiers
            .filter { [.public, .private, .fileprivate, .open, .internal].contains($0.name.text) }
            .first ?? .init(name: .keyword(.internal))
    }
}
