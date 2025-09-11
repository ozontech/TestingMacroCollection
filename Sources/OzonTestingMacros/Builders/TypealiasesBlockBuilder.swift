//
//  TypealiasesBlockBuilder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax

enum TypealiasBlockBuilder {
    /// Generates `typealias` based on the received dictionary from the macro's initializer.
    static func makeTypealiasBlock(
        associatedTypes: [(String, String)],
        accessModifier: AccessModifier
    ) -> [MemberBlockItemSyntax] {
        let openOrPublic = accessModifier.modifierDecl.isPublic || accessModifier.modifierDecl.isOpen
        let typealiasAccessModifier = openOrPublic ? AccessModifier.public : nil

        var typealiases = associatedTypes
            .compactMap { makeBlockItemSyntax($0, accessModifier: typealiasAccessModifier?.modifierDecl) }

        // Adds MARK comment.
        if !typealiases.isEmpty {
            typealiases.insert(
                .init(decl: MissingDeclSyntax(
                    placeholder: .init(stringLiteral: "// MARK: - Typealiases\n")
                )),
                at: 0
            )
        }

        return typealiases
    }

    /// Maps `typealias` tuple to the `Typealias` declaration.
    ///
    ///  - Parameter typealiasValue: tuple with values for `typealias` declaration.
    ///  - Returns: the `typealias` declaration.
    ///
    private static func makeBlockItemSyntax(
        _ typealiasValue: (String, String),
        accessModifier: DeclModifierSyntax?
    ) -> MemberBlockItemSyntax {
        let modifierList = [accessModifier].compactMap(\.self)
        let value = IdentifierTypeSyntax(name: .identifier(typealiasValue.1))
        let initializer = TypeInitializerClauseSyntax(value: value)
        let decl = TypeAliasDeclSyntax(
            modifiers: .init(modifierList),
            name: .init(stringLiteral: typealiasValue.0),
            initializer: initializer
        )
        return MemberBlockItemSyntax(decl: decl)
    }
}
