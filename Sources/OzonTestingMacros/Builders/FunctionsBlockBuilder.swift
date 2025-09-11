//
//  FunctionsBlockBuilder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

enum FunctionsBlockBuilder {
    private struct FunctionSignature: Equatable {
        let functionName: String
        let argumentNames: [(String, String?)]

        static func == (lhs: FunctionSignature, rhs: FunctionSignature) -> Bool {
            lhs.functionName == rhs.functionName &&
                lhs.argumentNames.count == rhs.argumentNames.count &&
                zip(lhs.argumentNames, rhs.argumentNames).allSatisfy { first, second in
                    first.0 == second.0 && first.1 == second.1
                }
        }
    }

    private nonisolated(unsafe) static var signatures: [FunctionSignature] = []

    /// Generates a block with methods and properties for these methods.
    /// Receives as input a function syntax representation:
    ///
    ///     func makeWork(arg: String) async throws -> Int
    ///
    /// It outputs an array of the blocks:
    ///
    ///     private let lock = AtomicLock()
    ///
    ///     func makeWork(arg: String) async throws -> Int {
    ///        lock.performLockedAction {
    ///             makeWorkArgCallsCount += 1
    ///        }
    ///        if let makeWorkArgError {
    ///           throw makeWorkArgError
    ///        }
    ///        if let makeWorkArgClosure {
    ///           return makeWorkArgClosure(arg)
    ///        } else {
    ///           return makeWorkArgReturnValue
    ///        }
    ///     }
    ///     var makeWorkArgCallsCount = 0
    ///     var makeWorkArgError: Error?
    ///     var makeWorkArgClosure: ((String) -> Int)?
    ///     var makeWorkArgReturnValue: Int!
    ///
    static func makeFunctionsBlock(
        clearMethodBuilder: ClearMethodBuilder? = nil,
        functions: [FunctionDeclSyntax],
        accessModifiers: DeclModifierListSyntax,
        functionsModifiers: DeclModifierListSyntax = .init([]),
        isActor: Bool
    ) -> [MemberBlockItemSyntax] {
        var result: [MemberBlockItemSyntax] = []

        if !functions.isEmpty {
            result.append(.init(decl: MissingDeclSyntax(placeholder: .init(stringLiteral: ""))))
        }

        if !isActor, !functions.isEmpty {
            result.append(.init(decl: VariablesFactory.makeNSLockProperty()))
        }

        functions.enumerated().forEach { index, function in
            let hasEqualSignaturesYet = checkEqualSignatures(for: function)
            let markStringLiteral: String
            var setPropertyFunctions: [FunctionDeclSyntax] = []

            if index == 0, isActor {
                markStringLiteral = "// MARK: - \(function.name)\n"
            } else {
                markStringLiteral = "\n    // MARK: - \(function.name)\n"
            }

            result.append(
                .init(
                    decl: MissingDeclSyntax(
                        placeholder: .init(stringLiteral: markStringLiteral)
                    )
                )
            )

            let genericTypes = function.genericParameterClause?.parameters.compactMap { $0.name.text } ?? []
            let accessModifiers = insertNonisolatedUnsafeModifierFirstTo(
                accessModifiers,
                shouldInsertModifier: !genericTypes.isEmpty && isActor
            )
            let genericFinder = GenericFinder(genericTypes: genericTypes)
            let functionReturnType = function.signature.returnClause?.type
            let hasReturnValue = functionReturnType != nil && functionReturnType?.as(IdentifierTypeSyntax.self)?.name
                .text != .void
            let invocationArguments = function.signature.parameterClause.parameters
                .map {
                    $0.secondName == nil ? $0.firstName.text : $0.secondName?.text ?? ""
                }
                .filter { !$0.isEmpty }
            let genericArgumentNames = function.signature.parameterClause.parameters
                .filter { genericFinder.hasGenerics($0.type) }
                .reduce(into: [String: TypeSyntax]()) { partialResult, parameter in
                    let type = VariablesFactory.removeEscapingAttribute(from: parameter.type)
                    let name = parameter.secondName == nil ? parameter.firstName.text : parameter.secondName?.text ?? ""
                    partialResult[name] = replaceGenericsWithAny(type: type, genericTypes: genericTypes)
                }
            let invocationArgumentsTypes = function.signature.parameterClause.parameters
                .map { $0.type }
            let propertiesShortName = function.signature.parameterClause.parameters
                .compactMap {
                    let argumentName = if $0.firstName.text == "_" {
                        $0.secondName?.text.capitalizedFirstLetter ?? ""
                    } else {
                        $0.firstName.text.capitalizedFirstLetter + ($0.secondName?.text.capitalizedFirstLetter ?? "")
                    }

                    return if hasEqualSignaturesYet {
                        argumentName + $0.type.prettyName
                    } else {
                        argumentName
                    }
                }
                .reduce(function.name.text) { partialResult, parameter in
                    partialResult.appending(parameter)
                }
            let isFuncThrowable = function.signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil
            let isAsyncFunc = function.signature.effectSpecifiers?.asyncSpecifier != nil

            let funcModifiers: DeclModifierListSyntax

            if !functionsModifiers.isEmpty {
                funcModifiers = functionsModifiers
            } else {
                funcModifiers = accessModifiers
            }

            let hasReturnTypeGenerics = genericFinder.hasGenerics(functionReturnType)
            let newFunc = FunctionFactory.makeMockFunctionWithBody(
                from: function,
                accessModifiers: funcModifiers,
                propertiesShortName: propertiesShortName,
                invocationArguments: invocationArguments,
                genericReturnType: hasReturnTypeGenerics ? .init(stringLiteral: functionReturnType?.name ?? "") : nil,
                genericArguments: genericArgumentNames,
                hasReturnValue: hasReturnValue,
                isThrowable: isFuncThrowable,
                isAsync: isAsyncFunc,
                isActor: isActor
            )
            result.append(.init(decl: newFunc))

            let callsCountProperty = VariablesFactory.makeCallsCountProperty(
                varName: propertiesShortName,
                accessModifiers: accessModifiers
            )
            result.append(.init(decl: callsCountProperty))

            if !invocationArguments.isEmpty {
                result.append(
                    .init(
                        decl: VariablesFactory.makeReceivedArgumentsProperty(
                            clearMethodBuilder: clearMethodBuilder,
                            propertiesShortName: propertiesShortName,
                            receivedArgumentTypes: invocationArgumentsTypes,
                            genericTypes: genericTypes,
                            accessModifiers: accessModifiers
                        )
                    )
                )
            }
            if isFuncThrowable {
                var _accessModifiers = accessModifiers

                if isActor {
                    _accessModifiers = insertNonisolatedUnsafeModifierFirstTo(
                        DeclModifierListSyntax([.init(name: .keyword(.private))]),
                        shouldInsertModifier: !genericTypes.isEmpty
                    )
                }

                let errorProperty = VariablesFactory.makeErrorProperty(
                    clearMethodBuilder: clearMethodBuilder,
                    varName: propertiesShortName,
                    accessModifiers: _accessModifiers
                )
                result.append(.init(decl: errorProperty))

                if isActor {
                    let setErrorMethod = SetPropertyFunctionBuilder.makeSetMethod(
                        for: .error,
                        propertyName: propertiesShortName,
                        accessModifiers: accessModifiers,
                        type: TypeSyntax(stringLiteral: .error)
                    )
                    setPropertyFunctions.append(setErrorMethod)
                }
            }

            var closureAccessModifiers = accessModifiers
            if isActor {
                closureAccessModifiers = insertNonisolatedUnsafeModifierFirstTo(
                    DeclModifierListSyntax([.init(name: .keyword(.private))]),
                    shouldInsertModifier: !genericTypes.isEmpty
                )
            }
            let arguments = function.signature.parameterClause.parameters.compactMap { $0.type }
            let closureProperty = VariablesFactory.makeClosureProperty(
                clearMethodBuilder: clearMethodBuilder,
                varName: propertiesShortName,
                inputArguments: arguments,
                returnType: functionReturnType,
                genericTypes: genericTypes,
                accessModifiers: closureAccessModifiers,
                isThrowable: isFuncThrowable,
                isAsync: isAsyncFunc
            )

            result.append(.init(decl: closureProperty))

            if isActor, let closureType = VariablesFactory.closureType {
                let sendableType = AttributedTypeSyntax(
                    specifiers: [],
                    attributes: [
                        .attribute(.init(stringLiteral: .sendableWrapper)),
                    ],
                    baseType: closureType
                )

                let attributedType = AttributedTypeSyntax(
                    specifiers: .init([]),
                    attributes: .init(
                        arrayLiteral: .attribute(
                            .init(atSign: .atSignToken(), attributeName: TypeSyntax(stringLiteral: .escaping))
                        )
                    ),
                    baseType: sendableType.toTupleTypeSyntax()
                )
                let setClosureMethod = SetPropertyFunctionBuilder.makeSetMethod(
                    for: .closure,
                    propertyName: propertiesShortName,
                    accessModifiers: accessModifiers,
                    type: attributedType
                )
                setPropertyFunctions.append(setClosureMethod)
            }

            if let functionReturnType, hasReturnValue {
                var _accessModifiers = accessModifiers

                if isActor {
                    let setReturnValueMethod = SetPropertyFunctionBuilder.makeSetMethod(
                        for: .returnValue,
                        propertyName: propertiesShortName,
                        accessModifiers: accessModifiers,
                        type: replaceGenericsWithAny(
                            type: functionReturnType,
                            genericTypes: genericTypes
                        )
                    )
                    _accessModifiers = insertNonisolatedUnsafeModifierFirstTo(
                        DeclModifierListSyntax([.init(name: .keyword(.private))]),
                        shouldInsertModifier: !genericTypes.isEmpty
                    )

                    setPropertyFunctions.append(setReturnValueMethod)
                }

                let returnValueProperty = VariablesFactory.makeReturnValueProperty(
                    clearMethodBuilder: clearMethodBuilder,
                    varName: propertiesShortName,
                    type: replaceGenericsWithAny(type: functionReturnType, genericTypes: genericTypes),
                    accessModifiers: _accessModifiers
                )
                result.append(.init(decl: returnValueProperty))
            }

            if !setPropertyFunctions.isEmpty {
                result.append(.init(
                    decl: MissingDeclSyntax(placeholder: .identifier(""))
                ))

                setPropertyFunctions.forEach {
                    result.append(.init(decl: $0))
                }
            }
        }

        signatures = []

        return result
    }

    /// Prepends the `nonisolated(unsafe)` modifier when `shouldInsertModifier` returns `true`.
    ///
    /// - Parameters:
    ///  - accessModifiers: the access modifiers to process.
    ///  - shouldInsertModifier: a predicate determining whether to add the `nonisolated` modifier.
    /// - Returns: the modified or unmodified sequence of modifiers.
    ///
    private static func insertNonisolatedUnsafeModifierFirstTo(
        _ accessModifiers: DeclModifierListSyntax,
        shouldInsertModifier: Bool
    ) -> DeclModifierListSyntax {
        guard shouldInsertModifier else { return accessModifiers }

        var _accessModifiers: [DeclModifierSyntax] = [
            .init(name: String.nonisolatedUnsafe.toTokenSyntax()),
        ]

        _accessModifiers += accessModifiers

        return .init(_accessModifiers)
    }

    // MARK: - Functions

    private enum FunctionFactory {
        ///
        /// Generates the method body.
        /// Adds an increment of the `callsCount` property, calls the `closure` property.
        /// Throws error or returns `returnValue` if needed.
        ///
        static func makeMockFunctionWithBody(
            from function: FunctionDeclSyntax,
            accessModifiers: DeclModifierListSyntax,
            propertiesShortName: String,
            invocationArguments: [String],
            genericReturnType: TokenSyntax?,
            genericArguments: [String: TypeSyntax],
            hasReturnValue: Bool,
            isThrowable: Bool,
            isAsync: Bool,
            isActor: Bool
        ) -> FunctionDeclSyntax {
            var statements = CodeBlockItemListSyntax([])

            if isAsync {
                statements.append(
                    CodeBlockItemFactory.makeCallsCountIncrementSyntax(propertiesShortName: propertiesShortName)
                )

                if !invocationArguments.isEmpty {
                    statements.append(
                        CodeBlockItemFactory.makeAppendArgumentsSyntax(
                            propertyiesShortName: propertiesShortName,
                            receivedArguments: invocationArguments,
                            genericArgumentNames: genericArguments
                        )
                    )
                }
            } else {
                statements.append(
                    CodeBlockItemFactory.makePerformLockedActionCall(
                        propertiesShortName: propertiesShortName,
                        receivedArguments: invocationArguments,
                        genericArguments: genericArguments
                    )
                )
            }

            if isThrowable {
                statements.append(
                    CodeBlockItemFactory.makeThrowErrorSyntax(propertyShortName: propertiesShortName)
                )
            }

            if hasReturnValue {
                statements.append(
                    CodeBlockItemFactory.makeReturnSyntaxWithReturnValue(
                        propertyShortName: propertiesShortName,
                        invocationArguments: invocationArguments,
                        genericReturnType: genericReturnType,
                        genericArgumentNames: genericArguments,
                        isThrowable: isThrowable,
                        isAsync: isAsync
                    )
                )
            } else {
                statements.append(
                    CodeBlockItemFactory.makeClosureCallingSyntax(
                        propertyShortName: propertiesShortName,
                        invocationArguments: invocationArguments,
                        genericReturnType: genericReturnType,
                        genericArgumentNames: genericArguments,
                        isThrowable: isThrowable,
                        isAsync: isAsync,
                        isOptional: true,
                        hasReturnValue: false
                    )
                )
            }

            var genericParameterClause = function.genericParameterClause

            if isActor, !genericArguments.isEmpty {
                let parameters = function.genericParameterClause?.parameters.enumerated().compactMap {
                    let parametersCount = function.genericParameterClause?.parameters.count ?? 0
                    let isLastParameter = $0.offset == parametersCount - 1
                    let newParameter = GenericParameterSyntax(
                        name: $0.element.name,
                        colon: .colonToken(),
                        inheritedType: IdentifierTypeSyntax(name: String.sendable.toTokenSyntax()),
                        trailingComma: isLastParameter ? nil : .commaToken()
                    )
                    return newParameter
                }
                let sendableLimiterGenerics = GenericParameterClauseSyntax(
                    parameters: GenericParameterListSyntax(parameters ?? [])
                )

                genericParameterClause = sendableLimiterGenerics
            }

            let codeBlockSyntax = CodeBlockSyntax(statements: statements)
            return FunctionDeclSyntax(
                modifiers: accessModifiers,
                name: .identifier(function.name.text),
                genericParameterClause: genericParameterClause,
                signature: function.signature,
                body: codeBlockSyntax
            )
        }
    }

    // MARK: - Variables

    private enum VariablesFactory {
        nonisolated(unsafe) static var closureType: FunctionTypeSyntax?

        /// Generates `AtomicLock` syntax.
        ///
        ///     private let lock = AtomicLock()
        ///
        static func makeNSLockProperty() -> VariableDeclSyntax {
            let name = IdentifierPatternSyntax(identifier: .identifier(.lock))

            let typeIdentifier = TokenSyntax.identifier(.atomicLock)

            let initValue = FunctionCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(baseName: typeIdentifier),
                leftParen: .leftParenToken(),
                arguments: .init([]),
                rightParen: .rightParenToken()
            )
            let initializer = InitializerClauseSyntax(equal: .equalToken(), value: initValue)

            let binding = PatternBindingSyntax(
                pattern: name,
                initializer: initializer
            )

            return VariableDeclSyntax(
                modifiers: .init(arrayLiteral: .init(name: .keyword(.private))),
                bindingSpecifier: .keyword(.let),
                bindings: .init(arrayLiteral: binding)
            )
        }

        /// Generates `funcNameArgCallsCount` property.
        ///
        ///     var funcNameArgumentCallsCount = 0
        ///
        static func makeCallsCountProperty(varName: String, accessModifiers: DeclModifierListSyntax) -> VariableDeclSyntax {
            let value = IntegerLiteralExprSyntax(0)
            let initializer = InitializerClauseSyntax(equal: .equalToken(), value: value)
            let name = varName + .callsCount
            return VariableDeclSyntax(
                modifiers: accessModifiers,
                Keyword.var,
                name: .init(stringLiteral: name),
                initializer: initializer
            )
        }

        /// Generates a property with an error that can be thrown out of the method.
        /// Property is added only if the `throws` method is used.
        ///
        ///     var funcNameArgError: Error?
        ///
        static func makeErrorProperty(
            clearMethodBuilder: ClearMethodBuilder?,
            varName: String,
            accessModifiers: DeclModifierListSyntax
        ) -> VariableDeclSyntax {
            let name = varName + .error
            clearMethodBuilder?.addProperty(.nilable(propertyName: name))
            let type = OptionalTypeSyntax(wrappedType: IdentifierTypeSyntax(name: .identifier(.error)))
            return VariableDeclSyntax(
                modifiers: accessModifiers,
                Keyword.var,
                name: .init(stringLiteral: name),
                type: .init(type: type)
            )
        }

        /// Generates the `funcNameArgReturnValue` property if the method has a return value.
        /// The property is an implicitly unwrapped optional.
        /// - Warning: Use only for pre-initialized properties.
        ///
        ///     var funcNameArgumentReturnValue: Value!
        ///
        static func makeReturnValueProperty(
            clearMethodBuilder: ClearMethodBuilder?,
            varName: String,
            type: TypeSyntax,
            accessModifiers: DeclModifierListSyntax
        ) -> VariableDeclSyntax {
            let name = varName + .returnValue
            clearMethodBuilder?.addProperty(.nilable(propertyName: name))

            var returnValueType: TypeSyntaxProtocol = type

            if type.isSomeOrAny || type.isClosure, !type.isOptional {
                returnValueType = type.tupledForceUnwrapped
            } else if !type.isOptional {
                returnValueType = type.forceUnwrapped
            }

            return VariableDeclSyntax(
                modifiers: accessModifiers,
                Keyword.var,
                name: .init(stringLiteral: name),
                type: .init(type: TypeSyntax(returnValueType))
            )
        }

        /// Generates a `funcNameArgClosure` property with a type that copies the method signature.
        /// Is added to all methods.
        ///
        ///     var funcNameArgumentClosure: ((String) -> Void)?
        ///
        static func makeClosureProperty(
            clearMethodBuilder: ClearMethodBuilder?,
            varName: String,
            inputArguments: [TypeSyntax],
            returnType: TypeSyntax?,
            genericTypes: [String],
            accessModifiers: DeclModifierListSyntax,
            isThrowable: Bool,
            isAsync: Bool
        ) -> VariableDeclSyntax {
            let name = varName + .closure
            clearMethodBuilder?.addProperty(.nilable(propertyName: name))

            var arguments: [TupleTypeElementSyntax] = []
            for (index, argument) in inputArguments.enumerated() {
                let isLast = index == inputArguments.count - 1

                if let someAnyArg = argument.as(SomeOrAnyTypeSyntax.self),
                   someAnyArg.someOrAnySpecifier.text == .some {
                    arguments.append(.init(type: someAnyArg.constraint, trailingComma: !isLast ? .commaToken() : nil))
                    continue
                }

                arguments.append(
                    TupleTypeElementSyntax(
                        type: replaceGenericsWithAny(type: argument, genericTypes: genericTypes),
                        trailingComma: !isLast ? .commaToken() : nil
                    )
                )
            }
            let effectSpecifiers = TypeEffectSpecifiersSyntax(
                asyncSpecifier: isAsync ? .keyword(.async) : nil,
                throwsClause: isThrowable ? .init(throwsSpecifier: .keyword(.throws)) : nil
            )
            let functionTypeSyntax = FunctionTypeSyntax(
                parameters: .init(arguments),
                effectSpecifiers: effectSpecifiers,
                returnClause: .init(
                    type: replaceGenericsWithAny(
                        type: returnType ?? .init(stringLiteral: .void),
                        genericTypes: genericTypes
                    )
                )
            )
            let tupleTypeElement = TupleTypeElementSyntax(type: functionTypeSyntax)
            let wrappedType = TupleTypeSyntax(elements: .init(arrayLiteral: tupleTypeElement))
            let type = TypeAnnotationSyntax(
                type: OptionalTypeSyntax(wrappedType: wrappedType, questionMark: .postfixQuestionMarkToken())
            )

            closureType = functionTypeSyntax

            return VariableDeclSyntax(
                modifiers: accessModifiers,
                Keyword.var,
                name: .init(stringLiteral: name),
                type: type
            )
        }

        /// Adds a property storing the method call arguments.
        /// Is added only with input parameters.
        ///
        ///     var funcNameArgReceivedArguments: [String] = []
        ///
        static func makeReceivedArgumentsProperty(
            clearMethodBuilder: ClearMethodBuilder?,
            propertiesShortName: String,
            receivedArgumentTypes: [TypeSyntax],
            genericTypes: [String],
            accessModifiers: DeclModifierListSyntax
        ) -> VariableDeclSyntax {
            let name = TokenSyntax.identifier(propertiesShortName + .receivedArguments)
            clearMethodBuilder?.addProperty(.collection(propertyName: name.text))
            let pattern = IdentifierPatternSyntax(identifier: name)
            var tupleTypeElementListSyntax = TupleTypeElementListSyntax([])
            var typeSyntax: TypeSyntaxProtocol

            if receivedArgumentTypes.count == 1 {
                if var attributedType = receivedArgumentTypes.first?.as(AttributedTypeSyntax.self),
                   let escapingIndex = escapingAttributeIndex(attributedType.attributes) {
                    attributedType.attributes.remove(at: escapingIndex)

                    let rewritedGenericsWithAnyType = AttributedTypeSyntax(
                        specifiers: [],
                        attributes: attributedType.attributes,
                        baseType: replaceGenericsWithAny(
                            type: attributedType.baseType,
                            genericTypes: genericTypes
                        )
                    )

                    typeSyntax = rewritedGenericsWithAnyType
                } else if let someAnyType = receivedArgumentTypes.first?.as(SomeOrAnyTypeSyntax.self),
                          someAnyType.someOrAnySpecifier.text == .some {
                    typeSyntax = replaceGenericsWithAny(
                        type: someAnyType.constraint,
                        genericTypes: genericTypes
                    )
                } else {
                    typeSyntax = replaceGenericsWithAny(
                        type: receivedArgumentTypes.first ?? .init(stringLiteral: .void),
                        genericTypes: genericTypes
                    )
                }
            } else {
                receivedArgumentTypes.enumerated().forEach { index, element in
                    let isLastElement = index == receivedArgumentTypes.count - 1

                    let element = replaceGenericsWithAny(type: element, genericTypes: genericTypes)

                    if var attributedType = element.as(AttributedTypeSyntax.self),
                       let escIndex = escapingAttributeIndex(attributedType.attributes) {
                        attributedType.attributes.remove(at: escIndex)

                        tupleTypeElementListSyntax.append(
                            .init(
                                type: attributedType,
                                trailingComma: !isLastElement ? .commaToken() : nil
                            )
                        )
                        return
                    }

                    if let someAnyArg = element.as(SomeOrAnyTypeSyntax.self), someAnyArg.someOrAnySpecifier.text == .some {
                        tupleTypeElementListSyntax.append(
                            .init(
                                type: someAnyArg.constraint,
                                trailingComma: !isLastElement ? .commaToken() : nil
                            )
                        )
                        return
                    }

                    tupleTypeElementListSyntax.append(
                        .init(
                            type: replaceGenericsWithAny(type: element, genericTypes: genericTypes),
                            trailingComma: !isLastElement ? .commaToken() : nil
                        )
                    )
                }

                let tupleTypeSynax = TupleTypeSyntax(
                    leftParen: .leftParenToken(),
                    elements: tupleTypeElementListSyntax,
                    rightParen: .rightParenToken()
                )

                typeSyntax = tupleTypeSynax
            }

            let arrayTypeSyntax = ArrayTypeSyntax(
                leftSquare: .leftSquareToken(),
                element: typeSyntax,
                rightSquare: .rightSquareToken()
            )
            let type = TypeAnnotationSyntax(type: arrayTypeSyntax)

            let initValue = ArrayExprSyntax(
                leftSquare: .leftSquareToken(),
                elements: .init([]),
                rightSquare: .rightSquareToken()
            )
            let initializer = InitializerClauseSyntax(equal: .equalToken(), value: initValue)

            let binding = PatternBindingSyntax(
                pattern: pattern,
                typeAnnotation: type,
                initializer: initializer
            )
            return VariableDeclSyntax(
                modifiers: accessModifiers,
                bindingSpecifier: .keyword(.var),
                bindings: .init(arrayLiteral: binding)
            )
        }

        static func removeEscapingAttribute(from type: TypeSyntax) -> TypeSyntax {
            guard let attributedType = type.as(AttributedTypeSyntax.self),
                  let escapingIndex = escapingAttributeIndex(attributedType.attributes) else {
                return type
            }

            var resultType = attributedType
            resultType.attributes.remove(at: escapingIndex)
            return TypeSyntax(resultType)
        }

        private static func escapingAttributeIndex(_ attributes: AttributeListSyntax) -> SyntaxChildrenIndex? {
            var index: SyntaxChildrenIndex?

            attributes
                .forEach {
                    if $0.as(AttributeSyntax.self)?.attributeName.as(IdentifierTypeSyntax.self)?.name.text == .escaping {
                        index = attributes.index(of: $0)
                    }
                }

            return index
        }
    }

    // MARK: - CodeBlockItems

    private enum CodeBlockItemFactory {
        /// Generates an error throwing syntax.
        /// Is added if the method has the `throws` function.
        ///
        ///     throw funcNameError
        ///
        static func makeThrowErrorSyntax(propertyShortName: String) -> CodeBlockItemSyntax {
            let propertyName = propertyShortName + .error
            let optionalBindingCondition = OptionalBindingConditionSyntax(
                bindingSpecifier: .keyword(.let),
                pattern: IdentifierPatternSyntax(identifier: .identifier(propertyName))
            )
            let condition = ConditionElementSyntax(condition: .optionalBinding(optionalBindingCondition))

            let declExpr = DeclReferenceExprSyntax(baseName: .identifier(propertyName))
            let throwStmt = ThrowStmtSyntax(expression: declExpr)
            let codeBlockItem = CodeBlockItemSyntax(item: .stmt(.init(throwStmt)))
            let ifBody = CodeBlockSyntax(statements: .init(arrayLiteral: codeBlockItem))
            let ifExpr = IfExprSyntax(conditions: .init(arrayLiteral: condition), body: ifBody)

            let ifBlockExpr = ExpressionStmtSyntax(expression: ifExpr)
            let ifBlockItemSyntax = CodeBlockItemSyntax.Item(ifBlockExpr)
            return CodeBlockItemSyntax(item: ifBlockItemSyntax)
        }

        /// Generates an `if/else` construction with a return value.
        /// If the `closure` property isn't `nil`, the `closure` is called and it returns the value.
        /// Otherwise, it returns the `returnValue` property.
        /// The syntax is added only if the method returns a value.
        ///
        ///     if let funcNameArgClosure {
        ///         return funcNameArgClosure(arg)
        ///     } else {
        ///         return funcNameArgReturnValue
        ///     }
        ///
        static func makeReturnSyntaxWithReturnValue(
            propertyShortName: String,
            invocationArguments: [String],
            genericReturnType: TokenSyntax?,
            genericArgumentNames: [String: TypeSyntax],
            isThrowable: Bool,
            isAsync: Bool
        ) -> CodeBlockItemSyntax {
            let optionalBindingCondition = OptionalBindingConditionSyntax(
                bindingSpecifier: .keyword(.let),
                pattern: IdentifierPatternSyntax(identifier: .identifier(propertyShortName + .closure))
            )
            let condition = ConditionElementSyntax(condition: .optionalBinding(optionalBindingCondition))

            let ifBody = makeClosureCallingSyntax(
                propertyShortName: propertyShortName,
                invocationArguments: invocationArguments,
                genericReturnType: genericReturnType,
                genericArgumentNames: genericArgumentNames,
                isThrowable: isThrowable,
                isAsync: isAsync
            )
            let elseBody = IfExprSyntax.ElseBody(
                CodeBlockSyntax(statements: .init(
                    arrayLiteral: makeElseBody(propertyShortName: propertyShortName, genericReturnType: genericReturnType)
                )
                )
            )

            let ifExpr = IfExprSyntax(
                conditions: .init(arrayLiteral: condition),
                body: CodeBlockSyntax(statements: .init(arrayLiteral: ifBody)),
                elseKeyword: .keyword(.else),
                elseBody: elseBody
            )
            let item = ExpressionStmtSyntax(expression: ifExpr)
            let ifElseItem = CodeBlockItemSyntax.Item(item)
            return CodeBlockItemSyntax(item: ifElseItem)
        }

        /// Generates the syntax for calling the `closure` property.
        /// Adds the `try` and `await` keywords, if necessary.
        ///
        ///     try await funcNameArgClosure?(arg)
        ///
        static func makeClosureCallingSyntax(
            propertyShortName: String,
            invocationArguments: [String],
            genericReturnType: TokenSyntax?,
            genericArgumentNames: [String: TypeSyntax],
            isThrowable: Bool,
            isAsync: Bool,
            isOptional: Bool = false,
            hasReturnValue: Bool = true
        ) -> CodeBlockItemSyntax {
            let arguments = invocationArguments.enumerated().reduce(into: [LabeledExprSyntax]()) { partialResult, item in
                let index = item.offset
                let element = item.element
                let isLast = index == invocationArguments.count - 1
                var baseExpression: ExprSyntaxProtocol = DeclReferenceExprSyntax(baseName: .identifier(element))

                if let genericType = genericArgumentNames[element], genericType.isClosure {
                    baseExpression = AsExprSyntax(
                        expression: baseExpression,
                        questionOrExclamationMark: .exclamationMarkToken(),
                        type: genericType
                    )
                }

                partialResult.append(
                    .init(
                        expression: baseExpression,
                        trailingComma: isLast ? nil : .commaToken()
                    )
                )
            }

            var expression: ExprSyntaxProtocol = FunctionCallExprSyntax(
                calledExpression: DeclReferenceExprSyntax(baseName: .identifier(propertyShortName + .closure))
                    .convertToOptionalIfNeeded(isOptional),
                leftParen: .leftParenToken(),
                arguments: .init(arguments),
                rightParen: .rightParenToken()
            )

            if let genericReturnType {
                expression = AsExprSyntax(
                    expression: expression,
                    questionOrExclamationMark: .exclamationMarkToken(),
                    type: IdentifierTypeSyntax(name: genericReturnType)
                )
            }

            var exprSyntax: ExprSyntaxProtocol

            if isAsync && isThrowable {
                let awaitExpr = AwaitExprSyntax(expression: expression)
                exprSyntax = TryExprSyntax(expression: awaitExpr)
            } else if isAsync {
                exprSyntax = AwaitExprSyntax(expression: expression)
            } else if isThrowable {
                exprSyntax = TryExprSyntax(expression: expression)
            } else {
                exprSyntax = expression
            }

            if hasReturnValue {
                let returnStatement = ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: exprSyntax)
                let returnStmtItem = CodeBlockItemSyntax.Item(returnStatement)
                return CodeBlockItemSyntax(item: returnStmtItem)
            } else {
                return CodeBlockItemSyntax(item: .expr(ExprSyntax(exprSyntax)))
            }
        }

        /// Generates an `else` body for the `if/else` value return construction.
        /// Adds the return of the `returnValue` property.
        ///
        ///     return funcNameArgReturnValue
        ///
        static func makeElseBody(propertyShortName: String, genericReturnType: TokenSyntax?) -> CodeBlockItemSyntax {
            var declExpr: ExprSyntaxProtocol = DeclReferenceExprSyntax(baseName: .identifier(propertyShortName + .returnValue))

            if let genericReturnType {
                declExpr = AsExprSyntax(
                    expression: declExpr,
                    questionOrExclamationMark: .exclamationMarkToken(),
                    type: IdentifierTypeSyntax(name: genericReturnType)
                )
            }

            let returnStatement = ReturnStmtSyntax(returnKeyword: .keyword(.return), expression: declExpr)
            let returnStmtItem = CodeBlockItemSyntax.Item(returnStatement)
            return CodeBlockItemSyntax(item: returnStmtItem)
        }

        /// Generates a `performLockedAction { }` call whose closure increments the `callsCount` property and adds arguments if any.
        ///
        ///     lock.performLockedAction {
        ///         makeWorkArgumentCallsCount += 1
        ///         makeWorkArgumentReceivedArguments.append(argument)
        ///     }
        ///
        static func makePerformLockedActionCall(
            propertiesShortName: String,
            receivedArguments: [String],
            genericArguments: [String: TypeSyntax]
        ) -> CodeBlockItemSyntax {
            let lockObjectName = DeclReferenceExprSyntax(baseName: .identifier(.lock))
            let performLockedActionCall = DeclReferenceExprSyntax(baseName: .identifier(.performLockedAction))
            let lockedFuncCallWithClosure = MemberAccessExprSyntax(
                base: lockObjectName,
                period: .periodToken(),
                declName: performLockedActionCall
            )

            var closureExpr = ClosureExprSyntax(
                statements: .init(
                    arrayLiteral: makeCallsCountIncrementSyntax(propertiesShortName: propertiesShortName)
                )
            )

            if !receivedArguments.isEmpty {
                closureExpr.statements.append(
                    makeAppendArgumentsSyntax(
                        propertyiesShortName: propertiesShortName,
                        receivedArguments: receivedArguments,
                        genericArgumentNames: genericArguments
                    )
                )
            }

            let funcCall = FunctionCallExprSyntax(
                calledExpression: lockedFuncCallWithClosure,
                arguments: .init([]),
                trailingClosure: closureExpr,
                additionalTrailingClosures: .init([])
            )

            return .init(item: CodeBlockItemSyntax.Item(funcCall))
        }

        /// Adds the increment syntax of the `CallsCount` property.
        ///
        ///     funcNameCallsCount += 1
        ///
        static func makeCallsCountIncrementSyntax(propertiesShortName: String) -> CodeBlockItemSyntax {
            let declExpr = DeclReferenceExprSyntax(baseName: .identifier(propertiesShortName + .callsCount))
            let incrementOperator = BinaryOperatorExprSyntax(operator: .binaryOperator("+="))
            let literalValue = IntegerLiteralExprSyntax(1)
            let exprListSyntax = ExprListSyntax([
                ExprListSyntax.Element(declExpr),
                ExprListSyntax.Element(incrementOperator),
                ExprListSyntax.Element(literalValue),
            ])
            let sequence = SequenceExprSyntax(elements: exprListSyntax)
            let item = CodeBlockItemSyntax.Item(sequence)
            return CodeBlockItemSyntax(item: item)
        }

        /// Adds the added argument syntax with the help of which the method was called to the `ReceivedArguments` property.
        ///
        ///     funcNameArg1Arg2ReceivedArguments.append((arg1, arg2))
        ///
        static func makeAppendArgumentsSyntax(
            propertyiesShortName: String,
            receivedArguments: [String],
            genericArgumentNames: [String: TypeSyntax]
        ) -> CodeBlockItemSyntax {
            let propertyName = TokenSyntax.identifier(propertyiesShortName + .receivedArguments)
            let calledExpr = MemberAccessExprSyntax(
                base: DeclReferenceExprSyntax(baseName: propertyName),
                period: .periodToken(),
                declName: .init(baseName: .init(stringLiteral: .append))
            )

            let argumentNames = receivedArguments.enumerated().reduce(into: [LabeledExprSyntax]()) { partialResult, element in
                let isLastElement = element.offset == receivedArguments.count - 1
                var baseExpression: ExprSyntaxProtocol = DeclReferenceExprSyntax(baseName: .identifier(element.element))

                if let genericType = genericArgumentNames[element.element], genericType.isClosure {
                    baseExpression = AsExprSyntax(
                        expression: baseExpression,
                        questionOrExclamationMark: .exclamationMarkToken(),
                        type: genericType
                    )
                }

                partialResult.append(
                    .init(
                        expression: baseExpression,
                        trailingComma: !isLastElement ? .commaToken() : nil
                    )
                )
            }
            let arguments = LabeledExprListSyntax(argumentNames)
            var tupleArguments = LabeledExprListSyntax([])

            if receivedArguments.count > 1 {
                let tupleExpr = TupleExprSyntax(
                    leftParen: .leftParenToken(),
                    elements: arguments,
                    rightParen: .rightParenToken()
                )
                tupleArguments.append(.init(expression: tupleExpr))
            }

            let funcCallExpr = FunctionCallExprSyntax(
                calledExpression: calledExpr,
                leftParen: .leftParenToken(),
                arguments: receivedArguments.count > 1 ? tupleArguments : arguments,
                rightParen: .rightParenToken()
            )
            let item = CodeBlockItemSyntax.Item(funcCallExpr)

            return CodeBlockItemSyntax(item: item)
        }
    }

    /// Replaces generic types in `TypeSyntax` with `Any`.
    ///
    ///  - Parameters:
    ///   - type: the `TypeSyntax` entity.
    ///   - genericTypes: the specified generic types.
    ///  - Returns: modified `TypeSyntax` with all generic types replaced by `Any`.
    ///
    ///  Example:
    /// ```[(Int, T, E)] -> [(Int, Any, Any)]```
    ///
    private static func replaceGenericsWithAny(type: TypeSyntax, genericTypes: [String]) -> TypeSyntax {
        let rewriter = GenericTypeRewriter(genericNames: genericTypes)
        return rewriter.visit(type)
    }

    private static func checkEqualSignatures(for function: FunctionDeclSyntax) -> Bool {
        let signature = FunctionSignature(
            functionName: function.name.text,
            argumentNames: function.signature.parameterClause.parameters.map { ($0.firstName.text, $0.secondName?.text) }
        )

        let containsEqualSignature = signatures.contains(signature)

        if !containsEqualSignature {
            signatures.append(signature)
        }

        return containsEqualSignature
    }
}
