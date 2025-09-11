//
//  ArbitraryProtocolFlow.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

extension ArbitraryMacro {
    /// Generates the `Arbitrary` method for protocol using mock.
    ///
    ///  - Parameters:
    ///   - accessModifier: access modifier for the `Arbitrary` method.
    ///   - typeName: name of the type for which the `Arbitrary` is generated.
    ///   - parameters: type properties.
    ///   - arbitraryConfig: the `Arbitrary` type, can be `static` or `dynamic`.
    ///   - declMembers: all declarations are within the original declaration.
    ///  - Returns: the `Arbitrary` method.
    ///
    static func makeArbitraryMethodForMock(
        accessModifier: DeclModifierSyntax?,
        typeName: TokenSyntax,
        parameters: [ArbitraryParameter],
        arbitraryConfig: ArbitraryConfig,
        declMembers: MemberBlockItemListSyntax
    ) -> FunctionDeclSyntax {
        var modifiers = DeclModifierListSyntax()

        if let accessModifier, !accessModifier.isInternal {
            modifiers.append(accessModifier)
        }

        modifiers.append(.init(name: .keyword(.static)))

        return FunctionDeclSyntax(
            modifiers: modifiers,
            name: .identifier(String.arbitrary),
            signature: .init(
                parameterClause: makeArbitraryMethodSignatureParameterClause(
                    parentTypeName: typeName,
                    parameters: parameters,
                    arbitararyConfig: arbitraryConfig,
                    declMembers: declMembers
                ),
                returnClause: .init(type: IdentifierTypeSyntax(name: typeName))
            ),
            body: makeArbitraryMethodBody(typeName: typeName, parameters: parameters.map { $0.name })
        )
    }

    /// Generates a list of arguments for the `Arbitrary` method.
    ///
    /// - Parameters:
    ///  - parentTypeName: name of the parent declaration.
    ///  - parameters: property type.
    ///  - arbitraryConfig: the `Arbitrary` type, can be `static` or `dynamic`.
    ///  - declMembers: all declarations within the original declaration.
    /// - Returns: the method input argument list syntax.
    ///
    static func makeArbitraryMethodSignatureParameterClause(
        parentTypeName: TokenSyntax,
        parameters: [ArbitraryParameter],
        arbitararyConfig: ArbitraryConfig,
        declMembers: MemberBlockItemListSyntax
    ) -> FunctionParameterClauseSyntax {
        let parameterListSyntax = parameters.enumerated().reduce(into: FunctionParameterListSyntax()) { partialResult, item in
            var parameter = item.element

            let type: TypeSyntaxProtocol

            if parameter.type.is(FunctionTypeSyntax.self) {
                type = AttributedTypeSyntax(
                    specifiers: [],
                    attributes: .init(arrayLiteral: .attribute(
                        .init(
                            atSign: .atSignToken(),
                            attributeName: IdentifierTypeSyntax(name: .keyword(.escaping))
                        )
                    )),
                    baseType: parameter.type
                )
            } else {
                let handledType = handleMemberTypeSyntax(
                    parameter.type,
                    declMembers: declMembers,
                    parentTypeName: parentTypeName.text
                )
                parameter.type = handledType
                type = handledType
            }

            let parameterSyntax = FunctionParameterSyntax(
                firstName: parameter.name,
                type: type,
                defaultValue: makeDefaultValueForParameterIfNeeded(
                    parameter,
                    parentTypeName: parentTypeName,
                    arbitraryConfig: arbitararyConfig
                ),
                trailingComma: item.offset == parameters.count - 1 ? nil : .commaToken()
            )

            partialResult.append(parameterSyntax)
        }
        return .init(parameters: parameterListSyntax)
    }

    /// Generates a default value for the method's input argument.
    ///
    ///  - Parameters:
    ///   - parameter: input parameter for the `Arbitrary` method.
    ///   - parentTypeName: name of the parent declaration.
    ///   - arbitraryConfig: the `Arbitrary` type, can be `static` or `dynamic`.
    ///  - Returns: syntax for initializing a default value if necessary.
    ///
    private static func makeDefaultValueForParameterIfNeeded(
        _ parameter: ArbitraryParameter,
        parentTypeName: TokenSyntax,
        arbitraryConfig: ArbitraryConfig
    ) -> InitializerClauseSyntax? {
        if parameter.isNilable {
            return InitializerClauseSyntax(value: NilLiteralExprSyntax())
        }

        guard !parameter.isIgnored, let defaultValue = makeDefaultValueExprSyntaxForType(
            parameter.type,
            parentTypeName: parentTypeName,
            arbitraryConfig: arbitraryConfig
        ) else {
            return nil
        }

        return .init(equal: .equalToken(), value: defaultValue)
    }

    /// Generates a default value expression for an input parameter.
    ///
    ///  - Parameters:
    ///   - type: input argument type.
    ///   - parentTypeName: name of the parent declaration.
    ///   - arbitraryConfig: the `Arbitrary` type, can be `static` or `dynamic`.
    ///  - Returns: default value expression.
    ///
    private static func makeDefaultValueExprSyntaxForType(
        _ type: TypeSyntax,
        parentTypeName: TokenSyntax,
        arbitraryConfig: ArbitraryConfig
    ) -> ExprSyntaxProtocol? {
        let variableType = getVariableType(type)

        switch variableType {
        case .foundation:
            let arbitraryIdentifier = "\(String.arbitrary)" +
                (typeCanBeStaticOrDynamic(type) ? "(.\(arbitraryConfig.rawValue))" : "()")

            return MemberAccessExprSyntax(
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(arbitraryIdentifier))
            )
        case let .nested(cleanType):
            let typeName: String
            let type = cleanType.as(MemberTypeSyntax.self)
            let baseTypeName = type?.baseType.as(IdentifierTypeSyntax.self)?.name.text

            if let type, let baseTypeName {
                typeName = baseTypeName + "." + type.name.text
            } else {
                return nil
            }

            return FunctionCallExprSyntax(
                calledExpression: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(
                        baseName: .identifier(typeName + String.arbitrary.capitalized)
                    ),
                    declName: .init(baseName: .identifier(String.arbitrary))
                ),
                leftParen: .leftParenToken(),
                arguments: .init([]),
                rightParen: .rightParenToken()
            )
        case let .closure(functionType):
            var wildcards: ClosureShorthandParameterListSyntax = .init()

            functionType.parameters.forEach { element in
                let isLastElement = functionType.parameters.last == element
                wildcards.append(
                    .init(name: .wildcardToken(), trailingComma: isLastElement ? nil : .commaToken())
                )
            }

            var returnStmts = CodeBlockItemListSyntax()
            let returnType = functionType.returnClause.type

            if var returnTypeName = returnType.findSyntaxInTree(IdentifierTypeSyntax.self)?.name.text, returnTypeName != .void {
                var arguments = LabeledExprListSyntax()

                if typeCanBeStaticOrDynamic(returnType) {
                    arguments.append(LabeledExprSyntax(
                        expression: MemberAccessExprSyntax(
                            period: .periodToken(),
                            declName: .init(baseName: .identifier(arbitraryConfig.rawValue))
                        )
                    )
                    )
                } else if !isSwiftOrFoundationType(returnType) {
                    returnTypeName += .arbitrary.capitalizedFirstLetter
                }

                let returnExpr = FunctionCallExprSyntax(
                    calledExpression: MemberAccessExprSyntax(
                        base: DeclReferenceExprSyntax(baseName: .identifier(returnTypeName)),
                        period: .periodToken(),
                        name: .identifier(String.arbitrary)
                    ),
                    leftParen: .leftParenToken(),
                    arguments: arguments,
                    rightParen: .rightParenToken()
                )

                returnStmts.append(.init(item: CodeBlockItemSyntax.Item(returnExpr)))
            }

            return ClosureExprSyntax(
                signature: ClosureSignatureSyntax(
                    parameterClause: .simpleInput(wildcards),
                    inKeyword: !functionType.parameters.isEmpty ? .keyword(.in) : .init(stringLiteral: "")
                ),
                statements: returnStmts
            )
        case .optional:
            guard let wrappedType = type.as(OptionalTypeSyntax.self)?.wrappedType else {
                return NilLiteralExprSyntax(nilKeyword: .keyword(.nil))
            }

            return makeDefaultValueExprSyntaxForType(
                wrappedType,
                parentTypeName: parentTypeName,
                arbitraryConfig: arbitraryConfig
            )
        case .array,
             .set:
            return ArrayExprSyntax(leftSquare: .leftSquareToken(), elements: .init([]), rightSquare: .rightSquareToken())
        case .tuple:
            guard let typesInTuple = type.as(TupleTypeSyntax.self)?.elements else { return nil }

            return typesInTuple.enumerated().reduce(into: TupleExprSyntax(elements: .init([]))) { partialResult, item in
                guard let defaultValue = makeDefaultValueExprSyntaxForType(
                    item.element.type,
                    parentTypeName: parentTypeName,
                    arbitraryConfig: arbitraryConfig
                ) else { return }

                partialResult.elements.append(
                    .init(
                        expression: defaultValue,
                        trailingComma: item.offset == typesInTuple.count - 1 ? nil : .commaToken()
                    )
                )
            }
        case .dictionary:
            return DictionaryExprSyntax(content: .colon(.colonToken()))
        case .custom:
            let typeName: String

            if let name = type.as(IdentifierTypeSyntax.self)?.name.text {
                typeName = name
            } else if let name = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)?.wrappedType.as(IdentifierTypeSyntax.self)?
                .name.text {
                typeName = name
            } else {
                return nil
            }

            return FunctionCallExprSyntax(
                calledExpression: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .identifier(typeName + String.arbitrary.capitalized)),
                    period: .periodToken(),
                    declName: .init(baseName: .identifier(String.arbitrary))
                ),
                leftParen: .leftParenToken(),
                arguments: .init([]),
                rightParen: .rightParenToken()
            )
        case .forceUnwrapped:
            guard let wrappedType = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self)?.wrappedType else {
                return nil
            }

            return makeDefaultValueExprSyntaxForType(
                wrappedType,
                parentTypeName: parentTypeName,
                arbitraryConfig: arbitraryConfig
            )
        }
    }

    /// Generates a body for the `Arbitrary` method.
    ///
    ///  - Parameters:
    ///   - typeName: type name.
    ///   - parameters: type properties.
    ///  - Returns: a body for the `Arbitrary` method.
    ///
    private static func makeArbitraryMethodBody(typeName: TokenSyntax, parameters: [TokenSyntax]) -> CodeBlockSyntax {
        guard !parameters.isEmpty else { return makeMockInit(typeName: typeName.text) }

        let mockPropertyInit = makeMockPropertyInitializer(typeName: typeName.text)
        let mockPropertyInitItem = CodeBlockItemSyntax.Item(mockPropertyInit)

        let propertyInitializing = parameters.reduce(into: CodeBlockItemListSyntax()) { partialResult, parameter in
            let propertyInit = InfixOperatorExprSyntax(
                leftOperand: MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .identifier(String.mock)),
                    period: .periodToken(),
                    declName: .init(baseName: parameter)
                ),
                operator: AssignmentExprSyntax(equal: .equalToken()),
                rightOperand: DeclReferenceExprSyntax(baseName: parameter)
            )
            let propertyInitItem = CodeBlockItemSyntax.Item(propertyInit)
            partialResult.append(.init(item: propertyInitItem))
        }

        let returnStmt = ReturnStmtSyntax(
            returnKeyword: .keyword(.return),
            expression: DeclReferenceExprSyntax(baseName: .identifier(String.mock))
        )
        let returnStmtItem = CodeBlockItemSyntax.Item(returnStmt)

        var stmts = CodeBlockItemListSyntax()

        stmts.append(.init(item: mockPropertyInitItem))
        stmts.append(contentsOf: propertyInitializing)
        stmts.append(.init(item: returnStmtItem))

        return .init(statements: stmts)
    }

    /// Generates the `mock` initialization syntax of the object for which the `Arbitrary` is created.
    ///
    /// Example: `ServiceMock()`.
    ///
    /// - Parameter typeName: type name.
    /// - Returns: mock type initialization syntax.
    ///
    private static func makeMockInit(typeName: String) -> CodeBlockSyntax {
        let mockName = TokenSyntax(stringLiteral: typeName + String.mock.capitalized)
        let mockObjectInit = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: mockName),
            leftParen: .leftParenToken(),
            arguments: .init([]),
            rightParen: .rightParenToken()
        )
        let item = CodeBlockItemSyntax.Item(mockObjectInit)
        let codeBlockItemList = CodeBlockItemListSyntax(arrayLiteral: .init(item: item))
        return .init(statements: codeBlockItemList)
    }

    /// Generates a syntax for initializing a `mock` object with parameters for which an `Arbitrary` is created.
    ///
    /// Example: `let mock = ServiceMock()`.
    ///
    /// - Parameter typeName: type name.
    /// - Returns: syntax for initializing a `mock` object to a constant.
    ///
    private static func makeMockPropertyInitializer(typeName: String) -> VariableDeclSyntax {
        let mockPropertyName = IdentifierPatternSyntax(
            identifier: .identifier(String.mock)
        )
        let typeIdentifier = TokenSyntax(stringLiteral: typeName + String.mock.capitalized)
        let initializerSyntax = FunctionCallExprSyntax(
            calledExpression: DeclReferenceExprSyntax(baseName: typeIdentifier),
            leftParen: .leftParenToken(),
            arguments: .init([]),
            rightParen: .rightParenToken()
        )
        let initializer = InitializerClauseSyntax(
            equal: .equalToken(),
            value: initializerSyntax
        )
        let binding = PatternBindingSyntax(
            pattern: mockPropertyName,
            initializer: initializer
        )
        return VariableDeclSyntax(
            bindingSpecifier: .keyword(.let),
            bindings: .init(arrayLiteral: binding)
        )
    }

    /// Processes the parameter type if it's `MemberTypeSyntax` to generate the full path of a type. For example, if it's nested.
    /// Defines the parent type and create the full type via `MemberTypeSyntax`.
    ///
    ///  - Parameters:
    ///   - type: original type.
    ///   - declMembers: members of the declaration for which `Arbitrary` is attached.
    ///   - parentTypeName: name of the parent type.
    ///  - Returns: the original type for flat structures or `MemberTypeSyntax` for nested types.
    ///
    private static func handleMemberTypeSyntax(
        _ type: TypeSyntax,
        declMembers: MemberBlockItemListSyntax,
        parentTypeName: String
    ) -> TypeSyntax {
        let innerTypes = getInnerTypesFromMembers(declMembers)

        guard !innerTypes.isEmpty else { return type }

        var cleanType = type

        if let optionalType = type.as(OptionalTypeSyntax.self) {
            cleanType = optionalType.wrappedType
        } else if let forceUnwrappedType = type.as(ImplicitlyUnwrappedOptionalTypeSyntax.self) {
            cleanType = forceUnwrappedType.wrappedType
        }

        if let parameterTypeName = cleanType.as(IdentifierTypeSyntax.self)?.name.text,
           innerTypes.contains(parameterTypeName) {
            let memberType = TypeSyntax(stringLiteral: parentTypeName + "." + parameterTypeName)

            if type.isOptional {
                cleanType = TypeSyntax(OptionalTypeSyntax(wrappedType: memberType))
            } else if type.isForceUnwrapped {
                cleanType = TypeSyntax(ImplicitlyUnwrappedOptionalTypeSyntax(wrappedType: memberType))
            } else {
                cleanType = memberType
            }

            return cleanType
        } else {
            return type
        }
    }

    /// Get nested declarations in the original declaration.
    ///
    ///  - Parameter members: declarations within the original declaration.
    ///  - Returns: names of attached declarations.
    ///
    private static func getInnerTypesFromMembers(_ members: MemberBlockItemListSyntax) -> [String] {
        members
            .filter { $0.decl.isTypeSyntax }
            .compactMap { member in
                let decl = member.decl

                if let classDecl = decl.as(ClassDeclSyntax.self) {
                    return classDecl.name.text
                } else if let actorDecl = decl.as(ActorDeclSyntax.self) {
                    return actorDecl.name.text
                } else if let structDecl = decl.as(StructDeclSyntax.self) {
                    return structDecl.name.text
                } else {
                    return nil
                }
            }
    }
}
