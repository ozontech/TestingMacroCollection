//
//  ArbitraryMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
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
        let arbitraryType = try defineArbitraryTypeForDecl(declaration)
        let arbitraryConfig = try defineArbitraryConfig(from: node)
        let accessModifier = declGroup.accessModifier

        let parameters = declGroup.variables
            .reduce(into: [ArbitraryParameter]()) { partialResult, variable in
                guard let name = variable.name?.identifier, let type = variable.type?.type else { return }

                partialResult.append(.init(name: name, type: type, isIgnored: variable.isIgnored, isNilable: variable.isNilable))
            }
        let arbitraryMethod: FunctionDeclSyntax

        switch arbitraryType {
        case .mock:
            arbitraryMethod = makeArbitraryMethodForMock(
                accessModifier: accessModifier,
                typeName: typeName,
                parameters: parameters,
                arbitraryConfig: arbitraryConfig,
                declMembers: declGroup.memberBlock.members
            )
        case .model:
            arbitraryMethod = makeArbitraryMethodForModel(
                accessModifier: accessModifier,
                typeName: typeName,
                parameters: parameters,
                arbitraryConfig: arbitraryConfig,
                declMembers: declGroup.memberBlock.members
            )
        }

        return [
            .init(
                makeEnumDecl(
                    accessModifier: accessModifier,
                    typeName: typeName.text,
                    arbitraryMethod: arbitraryMethod
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
        accessModifier: DeclModifierSyntax,
        typeName: String,
        arbitraryMethod: FunctionDeclSyntax
    ) -> EnumDeclSyntax {
        var accessModifiers = DeclModifierListSyntax()

        if !accessModifier.isInternal {
            accessModifiers.append(accessModifier)
        }

        return EnumDeclSyntax(
            modifiers: accessModifiers,
            name: .init(stringLiteral: typeName + String.arbitrary.capitalized),
            memberBlock: .init(members: .init(arrayLiteral: .init(decl: arbitraryMethod)))
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
            return .optional
        } else if let optionalType = type.as(OptionalTypeSyntax.self), optionalType.wrappedType.is(MemberTypeSyntax.self) {
            return .nested(cleanType: optionalType.wrappedType)
        } else if isSwiftOrFoundationType(type) {
            return .foundation
        } else if type.is(ArrayTypeSyntax.self) || type.as(IdentifierTypeSyntax.self)?.name.text == String.array {
            return .array
        } else if let forceUnwrappedType = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            return getVariableType(forceUnwrappedType.wrappedType)
        } else if let functionType = type.findSyntaxInTree(FunctionTypeSyntax.self) {
            return .closure(cleanType: functionType)
        } else if type.is(TupleTypeSyntax.self) {
            return .tuple
        } else if type.is(DictionaryTypeSyntax.self) || type.as(IdentifierTypeSyntax.self)?.name.text == String.dictionary {
            return .dictionary
        } else if let type = type.as(IdentifierTypeSyntax.self)?.name.text, type == String.set {
            return .set
        } else if type.is(MemberTypeSyntax.self) {
            return .nested(cleanType: type)
        } else if let attributedType = type.as(AttributedTypeSyntax.self) {
            return getVariableType(attributedType.baseType)
        } else {
            return .custom
        }
    }

    /// Defines the `Arbitrary` type: `static` or `dynamic`.
    private static func defineArbitraryConfig(from node: AttributeSyntax) throws -> ArbitraryConfig {
        let strokeType = node.arguments?
            .as(LabeledExprListSyntax.self)?
            .filter { $0.expression.as(MemberAccessExprSyntax.self) != nil }.first?
            .expression
            .as(MemberAccessExprSyntax.self)?
            .declName
            .baseName
            .text ?? String.static

        if strokeType == String.static {
            return .static
        } else if strokeType == String.dynamic {
            return .dynamic
        } else {
            throw ArbitraryMacroError.wrongArbitraryType
        }
    }

    /// Defines generated `Arbitrary` type.
    private static func defineArbitraryTypeForDecl(_ declaration: DeclSyntaxProtocol) throws -> ArbitaryType {
        if declaration.is(ProtocolDeclSyntax.self) {
            return .mock
        } else if declaration.is(StructDeclSyntax.self) ||
            declaration.is(ClassDeclSyntax.self) ||
            declaration.is(ActorDeclSyntax.self) {
            return .model
        } else {
            throw ArbitraryMacroError.unsupportedType
        }
    }

    /// Returns the declaration type name.
    ///
    /// - Parameter decl: the declaration to extract the type name from.
    /// - Returns: the syntax of the declaration's type name.
    /// - Throws: an error if the macro is applied to an unsupported declaration.
    ///
    private static func getTypeNameFromDecl(_ decl: DeclGroupSyntax) -> TokenSyntax? {
        switch decl.kind {
        case .classDecl:
            return decl.as(ClassDeclSyntax.self)?.name
        case .structDecl:
            return decl.as(StructDeclSyntax.self)?.name
        case .extensionDecl:
            return decl.as(ExtensionDeclSyntax.self)?.extendedType.as(IdentifierTypeSyntax.self)?.name
        case .actorDecl:
            return decl.as(ActorDeclSyntax.self)?.name
        case .enumDecl:
            return decl.as(EnumDeclSyntax.self)?.name
        case .protocolDecl:
            return decl.as(ProtocolDeclSyntax.self)?.name
        default:
            return nil
        }
    }
}
