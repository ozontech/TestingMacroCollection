//
//  GenericTypeRewriter.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
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

        if let genericClause = token.genericArgumentClause {
            let newArguments = genericClause.arguments.map { argument in
                let newType = visit(argument.argument)
                return GenericArgumentSyntax(
                    argument: newType,
                    trailingComma: argument.trailingComma
                )
            }

            let newClause = GenericArgumentClauseSyntax(
                leftAngle: genericClause.leftAngle,
                arguments: GenericArgumentListSyntax(newArguments),
                rightAngle: genericClause.rightAngle
            )

            return TypeSyntax(
                token
                    .with(\.name, token.name)
                    .with(\.genericArgumentClause, newClause)
            )
        }

        return TypeSyntax(token)
    }
}
