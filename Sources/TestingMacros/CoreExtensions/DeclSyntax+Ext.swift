//
//  DeclSyntax+Ext.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension DeclSyntax {
    /// Checks whether the declaration is a type: class, actor or structure.
    var isTypeSyntax: Bool {
        ClassDeclSyntax(_syntaxNode) != nil ||
            StructDeclSyntax(_syntaxNode) != nil ||
            ActorDeclSyntax(_syntaxNode) != nil
    }
}
