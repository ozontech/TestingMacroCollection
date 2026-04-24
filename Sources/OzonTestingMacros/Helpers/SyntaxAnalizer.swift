//
//  SyntaxAnalizer.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

// MARK: - SyntaxAnalizer

protocol SyntaxAnalizer: SyntaxProtocol {
    /// Find a specific syntax in the syntax tree.
    ///
    ///   - Parameter syntax: type of syntax to find.
    ///   - Returns: the optional object of the required syntax type.
    ///
    func findSyntaxInTree<T: SyntaxProtocol>(_ syntax: T.Type) -> T?
}

extension SyntaxAnalizer {
    func findSyntaxInTree<T: SyntaxProtocol>(_ syntax: T.Type) -> T? {
        if let fndStx = self.as(syntax) {
            return fndStx
        }

        for childStx in children(viewMode: .all) {
            if let fndStx = childStx.findSyntaxInTree(syntax) {
                return fndStx
            } else {
                continue
            }
        }

        return nil
    }
}

// MARK: - SyntaxChildren.Element + SyntaxAnalizer

extension SyntaxChildren.Element: SyntaxAnalizer {}

// MARK: - TypeSyntax + SyntaxAnalizer

extension TypeSyntax: SyntaxAnalizer {}
