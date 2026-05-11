//
//  ArbitraryMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

public struct ArbitraryMacro: PeerMacro {
    /// Property type.
    enum VariableType {
        case foundation
        case optional
        case forceUnwrapped
        case array
        case dictionary
        case set
        case tuple
        case custom
        /// `cleanType` is the wrappedType of `OptionalTypeSyntax`/`ImplicitlyUnwrappedTypeSyntax`.
        /// If non-optional, it's just the type itself.
        case nested(cleanType: TypeSyntax)
        case closure(cleanType: FunctionTypeSyntax)
    }

    /// Generated `Arbitrary` type.
    enum ArbitaryType {
        /// Generates `Arbitrary` with random value.
        case mock
        /// Generates `Arbitrary` for the model using initializer.
        case model
        /// Generates `Arbitrary` for one of the cases depending on the generation type.
        case enumeration
    }

    enum ArbitraryConfig: String {
        /// Generates static `Arbitrary`.
        case `static`
        // Generates `Arbitrary` with random value.
        case dynamic
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declGroup = declaration.asProtocol(DeclGroupSyntax.self), let typeName = getTypeNameFromDecl(declGroup) else {
            throw ArbitraryMacroError.unsupportedType
        }

        let context = try makeContext(
            node: node,
            declaration: declaration,
            declGroup: declGroup,
            typeName: typeName
        )

        let arbitraryMethod: FunctionDeclSyntax = switch context.arbitraryType {
        case .mock:
            makeArbitraryMethodForMock(
                accessModifier: context.accessModifier,
                typeName: typeName,
                parameters: context.parameters,
                arbitraryConfig: context.arbitraryConfig,
                declMembers: declGroup.memberBlock.members
            )
        case .model:
            makeArbitraryMethodForModel(
                accessModifier: context.accessModifier,
                typeName: typeName,
                parameters: context.parameters,
                arbitraryConfig: context.arbitraryConfig,
                declMembers: declGroup.memberBlock.members
            )
        case .enumeration:
            try makeArbitraryMethodForEnum(
                accessModifier: context.accessModifier,
                enumDecl: declGroup,
                arbitraryConfig: context.arbitraryConfig
            )
        }

        let leadingTrivia = Trivia.ifDebug.ifNeeded(context.buildType == .debug)
        let trailingTrivia = Trivia.endif.ifNeeded(context.buildType == .debug)

        return [
            .init(
                makeEnumDecl(
                    leadingTrivia: leadingTrivia,
                    accessModifier: context.accessModifier,
                    typeName: typeName.text,
                    arbitraryMethod: arbitraryMethod,
                    trailingTrivia: trailingTrivia
                )
            ),
        ]
    }

    /// Generates an `enum` declaration.
    ///
    ///  - Parameters:
    ///   - accessModifier: access modifier for `enum`.
    ///   - typeName: name of type for which `Arbitrary` is generated.
    ///   - arbitraryMethod: `Arbitrary` method.
    ///  - Returns: `enum` declaration with `arbitrary` method.
    ///
    static func makeEnumDecl(
        leadingTrivia: Trivia? = nil,
        accessModifier: DeclModifierSyntax,
        typeName: String,
        arbitraryMethod: FunctionDeclSyntax,
        trailingTrivia: Trivia? = nil,
    ) -> EnumDeclSyntax {
        var accessModifiers = DeclModifierListSyntax()

        if !accessModifier.isInternal {
            accessModifiers.append(accessModifier)
        }

        return EnumDeclSyntax(
            leadingTrivia: leadingTrivia,
            modifiers: accessModifiers,
            name: .init(stringLiteral: typeName + String.arbitrary.capitalized),
            memberBlock: .init(members: .init(arrayLiteral: .init(decl: arbitraryMethod))),
            trailingTrivia: trailingTrivia
        )
    }

    /// Checks if the type is `Foundation` or standard swift.
    ///
    /// - Parameter type: the type to check.
    /// - Returns: `true`, if the type is from `Foundation`. `false`, if it's a custom type.
    ///
    static func isSwiftOrFoundationType(_ type: TypeSyntax?) -> Bool {
        guard let stringType = type?.as(IdentifierTypeSyntax.self)?.name.text, `Type`(rawValue: stringType) != nil else {
            return false
        }

        return true
    }

    /// Checks if the type can be `static` or `dynamic`.
    ///
    ///  - Parameter type: the type to check.
    ///
    static func typeCanBeStaticOrDynamic(_ type: TypeSyntax) -> Bool {
        guard let stringType = type.as(IdentifierTypeSyntax.self)?.name.text,
              let type = `Type`(rawValue: stringType) else { return false }

        return type.isDynamicOrStatic()
    }

    /// Returns the property type.
    ///
    ///  - Parameter type: type of data to define the type for.
    ///  - Returns: the property type.
    ///
    static func getVariableType(_ type: TypeSyntax) -> VariableType {
        if let optionalType = type.as(OptionalTypeSyntax.self), !optionalType.wrappedType.is(MemberTypeSyntax.self) {
            .optional
        } else if let optionalType = type.as(OptionalTypeSyntax.self), optionalType.wrappedType.is(MemberTypeSyntax.self) {
            .nested(cleanType: optionalType.wrappedType)
        } else if isSwiftOrFoundationType(type) {
            .foundation
        } else if type.is(ArrayTypeSyntax.self) || type.as(IdentifierTypeSyntax.self)?.name.text == String.array {
            .array
        } else if let forceUnwrappedType = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            getVariableType(forceUnwrappedType.wrappedType)
        } else if let functionType = type.findSyntaxInTree(FunctionTypeSyntax.self) {
            .closure(cleanType: functionType)
        } else if type.is(TupleTypeSyntax.self) {
            .tuple
        } else if type.is(DictionaryTypeSyntax.self) || type.as(IdentifierTypeSyntax.self)?.name.text == String.dictionary {
            .dictionary
        } else if let type = type.as(IdentifierTypeSyntax.self)?.name.text, type == String.set {
            .set
        } else if type.is(MemberTypeSyntax.self) {
            .nested(cleanType: type)
        } else if let attributedType = type.as(AttributedTypeSyntax.self) {
            getVariableType(attributedType.baseType)
        } else {
            .custom
        }
    }

    static func getReturnClause(
        type: TypeSyntax?,
        typeName: TokenSyntax
    ) -> ReturnClauseSyntax {
        guard let type else {
            return ReturnClauseSyntax(type: IdentifierTypeSyntax(name: typeName))
        }

        return ReturnClauseSyntax(type: type)
    }
}
