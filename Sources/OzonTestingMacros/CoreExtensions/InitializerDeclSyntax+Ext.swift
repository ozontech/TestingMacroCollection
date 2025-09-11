//
//  InitializerDeclSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension InitializerDeclSyntax {
    /// Initializer access modifier.
    var accessModifier: DeclModifierSyntax {
        modifiers
            .filter { [.public, .private, .fileprivate, .open, .internal].contains($0.name.text) }
            .first ?? .init(name: .keyword(.internal))
    }

    /// Checks if `init` is empty
    var isEmptyInit: Bool {
        signature.parameterClause.parameters.isEmpty
    }

    /// Set modifiers depending on those of the parent entity.
    ///
    /// - Parameters:
    ///  - parentModifiers: modifiers of the parent entity that contain the initializer.
    ///  - isActorInit:  flag indicating if `init` is an actor initializer.
    ///
    mutating func setModifiersDependsOn(_ parentModifiers: DeclModifierListSyntax, isActorInit: Bool) {
        if parentModifiers.contains(where: { $0.isOpen || $0.isPublic }) {
            modifiers.append(.init(name: .keyword(.public)))
        }

        if !parentModifiers.contains(where: \.isFinal), !isActorInit {
            modifiers.append(.init(name: .keyword(.required)))
        }
    }
}
