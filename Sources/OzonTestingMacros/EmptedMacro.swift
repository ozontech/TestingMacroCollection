//
//  EmptedMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - EmptedError

enum EmptedError: CustomStringConvertible, Error {
    case wrongDeclarationPinning

    var description: String {
        switch self {
        case .wrongDeclarationPinning:
            "`@Empted` can only be attached to Array, Set"
        }
    }
}

// MARK: - EmptedMacro

public struct EmptedMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              varDecl.type?.type.is(ArrayTypeSyntax.self) == true ||
              varDecl.type?.type.as(IdentifierTypeSyntax.self)?.name.text == String.set else {
            throw EmptedError.wrongDeclarationPinning
        }

        return []
    }
}
