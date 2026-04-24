//
//  ArbitraryMacro+Extension.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension ArbitraryMacro {
    static func makeContext(
        node: AttributeSyntax,
        declaration: some DeclSyntaxProtocol,
        declGroup: DeclGroupSyntax,
        typeName: TokenSyntax
    ) throws -> ArbitraryMacroContext {
        let arbitraryType = try defineArbitraryTypeForDecl(declaration)
        let arbitraryInputParameters = ArbitraryMacroInputParameters(
            node: node,
            declGroup: declGroup
        )

        let parameters = declGroup.variables
            .reduce(into: [ArbitraryParameter]()) { partialResult, variable in
                guard let name = variable.name?.identifier,
                      let type = variable.type?.type else { return }
                partialResult.append(
                    ArbitraryParameter(
                        name: name,
                        type: type,
                        isIgnored: variable.isIgnored,
                        isNilable: variable.isNilable,
                        isEmpted: variable.isEmpted,
                        isWithAccessor: variable.bindings.first?.accessorBlock != nil
                    )
                )
            }

        return ArbitraryMacroContext(
            arbitraryType: arbitraryType,
            arbitraryConfig: arbitraryInputParameters.arbitraryConfig,
            accessModifier: arbitraryInputParameters.accessModifier,
            buildType: arbitraryInputParameters.buildType,
            typeName: typeName,
            parameters: parameters,
            declMembers: declGroup.memberBlock.members
        )
    }

    static func defineArbitraryTypeForDecl(_ declaration: DeclSyntaxProtocol) throws -> ArbitaryType {
        if declaration.is(ProtocolDeclSyntax.self) {
            return .mock
        } else if declaration.is(StructDeclSyntax.self) ||
            declaration.is(ClassDeclSyntax.self) ||
            declaration.is(ActorDeclSyntax.self) {
            return .model
        } else if declaration.is(EnumDeclSyntax.self) {
            return .enumeration
        } else {
            throw ArbitraryMacroError.unsupportedType
        }
    }

    /// Extracts the type name of the declaration.
    ///
    /// - Parameter decl: Declaration from which to extract the type.
    /// - Returns: Syntax of the declaration name.
    static func getTypeNameFromDecl(_ decl: DeclGroupSyntax) -> TokenSyntax? {
        switch decl.kind {
        case .classDecl:
            decl.as(ClassDeclSyntax.self)?.name
        case .structDecl:
            decl.as(StructDeclSyntax.self)?.name
        case .extensionDecl:
            decl.as(ExtensionDeclSyntax.self)?.extendedType.as(IdentifierTypeSyntax.self)?.name
        case .actorDecl:
            decl.as(ActorDeclSyntax.self)?.name
        case .enumDecl:
            decl.as(EnumDeclSyntax.self)?.name
        case .protocolDecl:
            decl.as(ProtocolDeclSyntax.self)?.name
        default:
            nil
        }
    }
}
