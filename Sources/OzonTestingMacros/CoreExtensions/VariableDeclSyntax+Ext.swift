//
//  VariableDeclSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension VariableDeclSyntax {
    /// Variable name.
    var name: IdentifierPatternSyntax? {
        bindings.first?.pattern.as(IdentifierPatternSyntax.self)
    }

    /// Container of the variable data type.
    var type: TypeAnnotationSyntax? {
        bindings.first?.typeAnnotation
    }

    /// Checks if the variable contains `delegate` in the name and is therefore a delegate.
    var isDelegate: Bool {
        name?.identifier.text.lowercased().contains(String.delegate) ?? false
    }

    /// Checks if the variable in the macro should be ignored.
    var isIgnored: Bool {
        attributes.first(where: {
            $0.as(AttributeSyntax.self)?
                .attributeName
                .as(IdentifierTypeSyntax.self)?
                .name
                .text == String.ignored
        }) != nil
    }

    var isNilable: Bool {
        attributes.first(where: {
            $0.as(AttributeSyntax.self)?
                .attributeName
                .as(IdentifierTypeSyntax.self)?
                .name
                .text == String.nilable
        }) != nil
    }

    var isEmpted: Bool {
        attributes.first(where: {
            $0.as(AttributeSyntax.self)?
                .attributeName
                .as(IdentifierTypeSyntax.self)?
                .name
                .text == String.empted
        }) != nil
    }
}
