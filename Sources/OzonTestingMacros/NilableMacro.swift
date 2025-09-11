//
//  NilableMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - NilableError

enum NilableError: CustomStringConvertible, Error {
    case wrongDeclarationPinning

    var description: String {
        switch self {
        case .wrongDeclarationPinning:
            "`@Nilable` can be attached only to optional properties"
        }
    }
}

// MARK: - NilableMacro

public struct NilableMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              varDecl.type?.type.is(OptionalTypeSyntax.self) == true ||
              varDecl.type?.type.is(ImplicitlyUnwrappedOptionalTypeSyntax.self) == true else {
            throw NilableError.wrongDeclarationPinning
        }

        return []
    }
}
