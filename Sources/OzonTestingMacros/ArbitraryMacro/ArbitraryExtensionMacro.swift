//
//  ArbitraryExtensionMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension ArbitraryMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [ExtensionDeclSyntax] {
        guard let declGroup = declaration.asProtocol(DeclGroupSyntax.self), let typeName = getTypeNameFromDecl(declGroup) else {
            return []
        }

        do {
            let context = try makeContext(
                node: node,
                declaration: declaration,
                declGroup: declGroup,
                typeName: typeName
            )

            let arbitraryMethod: FunctionDeclSyntax? = switch context.arbitraryType {
            case .mock:
                /// No `extension` generation needed for protocols as it can't be used.
                nil
            case .model:
                makeArbitraryMethodForModel(
                    type: .init(type),
                    accessModifier: context.accessModifier,
                    typeName: typeName,
                    parameters: context.parameters,
                    arbitraryConfig: context.arbitraryConfig,
                    declMembers: declGroup.memberBlock.members
                )
            case .enumeration:
                try makeArbitraryMethodForEnum(
                    type: .init(type),
                    accessModifier: declGroup.accessModifier,
                    enumDecl: declGroup,
                    arbitraryConfig: context.arbitraryConfig
                )
            }

            guard let arbitraryMethod else {
                return []
            }

            let leadingTrivia = Trivia.ifDebug.ifNeeded(context.buildType == .debug)
            let trailingTrivia = Trivia.endif.ifNeeded(context.buildType == .debug)
            let extensionDecl = ExtensionDeclSyntax(
                leadingTrivia: leadingTrivia,
                extendedType: type,
                memberBlock: .init(
                    members: .init(
                        arrayLiteral: .init(
                            decl: arbitraryMethod
                        )
                    )
                ),
                trailingTrivia: trailingTrivia
            )

            return [extensionDecl]
        } catch {
            /// Returns an empty array of declarations to avoid duplicate error reporting.
            return []
        }
    }
}
