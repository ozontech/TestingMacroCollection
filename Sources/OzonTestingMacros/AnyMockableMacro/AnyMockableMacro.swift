//
//  AnyMockableMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - AnyMockableMacro

public struct AnyMockableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let inputParameters = AnyMockableParametersHandler.getInputParameters(from: node)

        let functions = declaration.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
        let functionsBlock = FunctionsBlockBuilder.makeFunctionsBlock(
            functions: functions,
            accessModifiers: .init([]),
            functionsModifiers: .init([.init(name: .keyword(.fileprivate))]),
            isActor: false
        )

        let variables = declaration.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let varBlock = VariablesBlockBuilder.makeVariablesBlock(
            variables: variables,
            accessModifiers: .init([]),
            generateOnlyUnderlying: true,
            generateDefaultValues: inputParameters.defaultValue == .static,
            isActor: false
        )

        let members = MemberBlockSyntax(members: .init(varBlock + functionsBlock))
        let accessModifier = declaration.accessModifier

        return [
            .init(makeMockVar(accessModifier: accessModifier)),
            .init(ClassDeclSyntax(
                modifiers: makeModifiersForMockClass(accessModifier),
                name: String.mock.capitalizedFirstLetter.toTokenSyntax(),
                inheritanceClause: makeUncheckedSendableConfrom(),
                memberBlock: members
            )),
        ]
    }

    /// Generates a declaration defining the `Mock()` property inside the mock declaration.
    ///
    ///  - Parameter accessModifier: access modifier for the `Mock()` property.
    ///  - Returns: a variable declaration of the `Mock()` instance.
    ///
    private static func makeMockVar(accessModifier: DeclModifierSyntax) -> VariableDeclSyntax {
        let expr = TypeExprSyntax(type: IdentifierTypeSyntax(name: .identifier(.mock.capitalizedFirstLetter + "()")))
        let mockVarInit = InitializerClauseSyntax(value: expr)

        let keyword = accessModifier.isOpen ? Keyword.var : Keyword.let

        return VariableDeclSyntax(
            modifiers: .init(arrayLiteral: accessModifier),
            keyword,
            name: .init(stringLiteral: .mock),
            initializer: mockVarInit
        )
    }

    /// Generates `@unchecked Sendable` conformance to the `Mock` class.
    ///
    ///  - Returns: `@unchecked Sendable` inheritance declaration.
    ///
    private static func makeUncheckedSendableConfrom() -> InheritanceClauseSyntax {
        let uncheckedAttribute = AttributeSyntax(
            atSign: .atSignToken(),
            attributeName: IdentifierTypeSyntax(name: .identifier(.unchecked))
        )
        let sendableType = AttributedTypeSyntax(
            specifiers: .init([]),
            attributes: AttributeListSyntax([.attribute(uncheckedAttribute)]),
            baseType: IdentifierTypeSyntax(name: .identifier(.sendable))
        )

        return InheritanceClauseSyntax(
            inheritedTypes: .init(
                [.init(type: sendableType)]
            )
        )
    }

    /// Generates a list of access modifiers for the mock class.
    ///
    ///  - Parameter declAccessModifier: declaration access modifier.
    ///  - Returns: a list of modifiers for the nested mock class.
    ///
    private static func makeModifiersForMockClass(_ declAccessModifier: DeclModifierSyntax) -> DeclModifierListSyntax {
        if declAccessModifier.isOpen {
            .init(arrayLiteral: declAccessModifier)
        } else {
            .init(arrayLiteral: declAccessModifier, .init(name: .keyword(.final)))
        }
    }
}

// MARK: - MemberAttributeMacro

/// `MemberAttributeMacro` conformance for adding `@MockAccessor` macro to all non-optional properties
/// and `@FunctionBodyMock` macro to all methods.
extension AnyMockableMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        if member.is(VariableDeclSyntax.self) {
            return mockAccessorFlow(declaration: declaration, member: member)
        } else if member.is(FunctionDeclSyntax.self) {
            return [.init(atSign: .atSignToken(), attributeName: IdentifierTypeSyntax(name: .identifier(.functionBodyMock)))]
        }

        return []
    }

    private static func mockAccessorFlow(
        declaration: some DeclGroupSyntax,
        member: some DeclSyntaxProtocol
    ) -> [AttributeSyntax] {
        guard !declaration.variables.isEmpty,
              let property = member.as(VariableDeclSyntax.self),
              let propertyType = property.type?.type,
              !propertyType.isOptional,
              !propertyType.isForceUnwrapped else { return [] }

        return [.init(atSign: .atSignToken(), attributeName: IdentifierTypeSyntax(name: .identifier(.mockAccessor)))]
    }
}

// MARK: - ExtensionMacro

/// Automatically adds the conformance of the `ProxybleMock` protocol to the mock.
extension AnyMockableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        let inheritanceClause = InheritanceClauseSyntax(
            inheritedTypes: .init(arrayLiteral: .init(type: IdentifierTypeSyntax(name: .identifier(.proxyableMock))))
        )
        return [
            .init(
                extendedType: type,
                inheritanceClause: inheritanceClause,
                memberBlock: .init(members: .init([]))
            ),
        ]
    }
}
