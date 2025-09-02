//
//  GenericFinder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax

/// Entity that traverses the AST searching for specified generic types.
final class GenericFinder: SyntaxVisitor {
    private let genericTypes: [String]
    private var hasGenerics: Bool = false

    init(genericTypes: [String]) {
        self.genericTypes = genericTypes

        super.init(viewMode: .sourceAccurate)
    }

    func hasGenerics(_ type: TypeSyntax?) -> Bool {
        guard let type, !genericTypes.isEmpty else { return false }

        walk(type)

        return hasGenerics
    }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        if genericTypes.contains(node.name.text) {
            hasGenerics = true
            return .skipChildren
        }

        return .visitChildren
    }
}
