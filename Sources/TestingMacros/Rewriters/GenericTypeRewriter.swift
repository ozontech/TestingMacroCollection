//
//  GenericTypeRewriter.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax

/// AST-traversing entity that replaces specified generic types with `Any`.
final class GenericTypeRewriter: SyntaxRewriter {
    private let genericNames: [String]

    init(genericNames: [String]) {
        self.genericNames = genericNames
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ token: IdentifierTypeSyntax) -> TypeSyntax {
        if genericNames.contains(token.name.text) {
            let anyToken = IdentifierTypeSyntax(name: .keyword(.Any))
            return TypeSyntax(anyToken)
        }

        return TypeSyntax(token)
    }
}
