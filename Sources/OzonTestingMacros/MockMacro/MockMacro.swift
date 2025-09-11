//
//  MockMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - MockMacroError

/// The `Compile-time` error that macro may throw.
enum MockMacroError: CustomStringConvertible, Error {
    case appliedOnlyWithProtocols

    var description: String {
        switch self {
        case .appliedOnlyWithProtocols:
            "@Mock should only be used with protocols"
        }
    }
}

// MARK: - MockMacro

public struct MockMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let decl = declaration.as(ProtocolDeclSyntax.self) else {
            throw MockMacroError.appliedOnlyWithProtocols
        }
        // Gets the input parameters of the macro.
        let inputParameters = MockMacroInputParametersHandler.getInputParameters(from: node)

        // Generates a mock name: protocol name + mock prefix.
        let newTypeName = TokenSyntax(stringLiteral: decl.name.text + .mock.capitalizedFirstLetter)

        // Extracts a block containing properties, methods, inherited types, initializers.
        let variables = decl.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        let functions = decl.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }
        let initializers = decl.memberBlock.members.compactMap { $0.decl.as(InitializerDeclSyntax.self) }
        let inheritedTypes = decl.inheritanceClause?.inheritedTypes ?? []
        let isMainActor = !decl.attributes
            .filter { $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == .mainActor }
            .isEmpty

        var inheritedClause: InheritanceClauseSyntax
        let isInheriting: Bool

        // Generates the mock inheritance syntax.
        if let inheritedProtocol = getInheritedProtocol(from: inheritedTypes) {
            let inheritedProtocolConformance = InheritedTypeSyntax(
                type: IdentifierTypeSyntax(name: .init(stringLiteral: inheritedProtocol + .mock.capitalizedFirstLetter)),
                trailingComma: .commaToken()
            )
            let mockConformance = InheritedTypeSyntax(type: IdentifierTypeSyntax(name: decl.name))

            inheritedClause = .init(inheritedTypes: .init(arrayLiteral: inheritedProtocolConformance, mockConformance))
            isInheriting = true
        } else {
            let mockConformance = InheritedTypeSyntax(type: IdentifierTypeSyntax(name: decl.name))

            inheritedClause = .init(inheritedTypes: .init(arrayLiteral: mockConformance))
            isInheriting = false
        }

        // Checks if the mock should be an actor.
        let isActor = inheritedTypes
            .map { $0.type.as(IdentifierTypeSyntax.self)?.name.text }
            .contains(.actor)

        // Determines whether to generate @unchecked Sendable conformance.
        if shouldGenerateSendableConformance(
            sendableMode: inputParameters.sendableMode,
            isActor: isActor,
            inheritedTypes: inheritedTypes
        ) {
            let uncheckedAttribute = AttributeSyntax(
                atSign: .atSignToken(),
                attributeName: IdentifierTypeSyntax(name: .identifier(.unchecked))
            )
            let sendableType = AttributedTypeSyntax(
                specifiers: .init([]),
                attributes: AttributeListSyntax([.attribute(uncheckedAttribute)]),
                baseType: IdentifierTypeSyntax(name: .identifier(.sendable))
            )

            inheritedClause.inheritedTypes.addLastElementComma()
            inheritedClause.inheritedTypes.append(.init(type: sendableType))
        }

        // Generates a declaration of access modifiers.
        var accessModifiers = DeclModifierListSyntax()
        // Default empty initializer block.
        var emptyInitBlock: [MemberBlockItemSyntax] = []

        // Adds an access modifier if it's specified in the macro parameters.
        if inputParameters.accessModifier == .open, isActor {
            accessModifiers.append(AccessModifier.public.modifierDecl)
        } else if inputParameters.accessModifier != .internal {
            accessModifiers.append(inputParameters.accessModifier.modifierDecl)
        }

        let shouldBeFinal = inputParameters.accessModifier != .open && inputParameters.heritability == .final

        if !initializers.contains(where: \.isEmptyInit) {
            var initAccessModifier = DeclModifierListSyntax([])

            if inputParameters.accessModifier == .open || inputParameters.accessModifier == .public {
                initAccessModifier.append(.init(name: .keyword(.public)))
            }

            if isInheriting {
                initAccessModifier.append(.init(name: .keyword(.override)))
            }

            emptyInitBlock = InitializerBlockBuilder.makeInitializer(accessModifiers: initAccessModifier)
        }

        var parameters: [ClearMethodBuilder.Parameters] = []

        if isInheriting {
            parameters.append(.overriding)
        }
        if inputParameters.accessModifier == .public {
            parameters.append(.public)
        } else if inputParameters.accessModifier == .open, isActor {
            parameters.append(.public)
        } else if inputParameters.accessModifier == .open {
            parameters.append(.open)
        }

        let funcMethodBuilder = ClearMethodBuilder(
            methodName: .clearFunctionProperties,
            parameters: parameters
        )
        let varMethodBuilder = ClearMethodBuilder(
            methodName: .clearVariableProperties,
            parameters: parameters
        )

        // Builds a block with properties, methods, or `typalias` for mock.
        let variablesBlock = VariablesBlockBuilder.makeVariablesBlock(
            clearMethodBuilder: varMethodBuilder,
            variables: variables,
            accessModifiers: accessModifiers,
            generateDefaultValues: inputParameters.defaultValues == .static,
            isActor: isActor
        )
        let typealiaseBlock = TypealiasBlockBuilder.makeTypealiasBlock(
            associatedTypes: inputParameters.associatedTypes,
            accessModifier: inputParameters.accessModifier
        )
        let functionsBlock = FunctionsBlockBuilder.makeFunctionsBlock(
            clearMethodBuilder: funcMethodBuilder,
            functions: functions,
            accessModifiers: accessModifiers,
            isActor: isActor
        )

        // Adds the `final` modifier if `shouldBeInherited` is `false` and the protocol doesn’t inherit `Actor`.
        if shouldBeFinal, !isActor {
            accessModifiers.append(.init(name: .keyword(.final)))
        }

        // Generates the block with initializers.
        let initBlock = InitializerBlockBuilder.makeInitializerBlock(
            with: initializers,
            mockName: newTypeName.text,
            isActor: isActor,
            accessModifiers: accessModifiers
        )

        let dataStructure = if isActor || isMainActor {
            ClearMethodBuilder.DataStructure.actor
        } else if shouldBeFinal {
            ClearMethodBuilder.DataStructure.finalClass
        } else {
            ClearMethodBuilder.DataStructure.nonFinalClass
        }

        // Generates a block with deinitializers.
        let deinitBlock = DeinitBlockBuilder.makeDeinitBlock(
            clearMethodBuilders: [funcMethodBuilder, varMethodBuilder],
            dataStructure: dataStructure
        )

        // Generates a list of declarations for mock entity.
        let members = typealiaseBlock + variablesBlock + initBlock + emptyInitBlock + deinitBlock + functionsBlock

        // Collects a syntax of the macro body.
        let memberBlock = MemberBlockSyntax(members: .init(members))

        return if isActor {
            // Generates an actor's declaration for the mock.
            [
                .init(ActorDeclSyntax(
                    modifiers: accessModifiers,
                    name: newTypeName,
                    inheritanceClause: inheritedClause,
                    memberBlock: memberBlock
                )),
            ]
        } else {
            // Generates a class declaration for mock.
            [
                .init(ClassDeclSyntax(
                    modifiers: accessModifiers,
                    name: newTypeName,
                    inheritanceClause: inheritedClause,
                    memberBlock: memberBlock
                )),
            ]
        }
    }

    /// Gets inherited types for the protocol.
    private static func getInheritedProtocol(from inheritedTypes: InheritedTypeListSyntax) -> String? {
        inheritedTypes
            .filter {
                if let inheritedTypeName = $0.type.as(IdentifierTypeSyntax.self)?.name.text {
                    return !(inheritedTypeName.contains(String.anyObject) || inheritedTypeName
                        .contains(String.actor) || inheritedTypeName.contains(String.sendable)
                    )
                }
                return false
            }
            .compactMap { $0.type.as(IdentifierTypeSyntax.self)?.name.text }
            .first
    }

    private static func shouldGenerateSendableConformance(
        sendableMode: SendableMode,
        isActor: Bool,
        inheritedTypes: InheritedTypeListSyntax
    ) -> Bool {
        guard sendableMode != .enabled else { return true }
        guard !isActor, sendableMode != .disabled else { return false }

        return inheritedTypes.contains { $0.type.isSendable }
    }
}
