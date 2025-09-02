//
//  ClearFunctionBlockBuilder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

/// Builder of properties clearing methods.
/// Clears `optional` and `force-unwrapped` properties in mocks.
///
///     func clearFunctionProperties() {
///         makeWorkClosure = nil
///         makeWorkThrowableError = nil
///         makeWorkReturnValue = nil
///     }
///
final class ClearMethodBuilder {
    enum PropertyType {
        /// Property initialized as `nil.
        case nilable(propertyName: String)
        /// Property initialized with empty array.
        case collection(propertyName: String)

        var propertyName: String {
            switch self {
            case let .collection(propertyName),
                 let .nilable(propertyName):
                return propertyName
            }
        }
    }

    /// Method parameters.
    enum Parameters {
        /// Method overrides a superclass method.
        case overriding
        /// Method should have `public` visibility.
        case `public`
        /// Method should have `open` visibility.
        case open
    }

    /// Data structure for which the methods are being created.
    enum DataStructure {
        /// Methods are created in the actor.
        case actor
        /// Methods are created in the `final` class.
        case finalClass
        /// Methods are created in an inherited class.
        case nonFinalClass
    }

    private var propertiesStorage: [PropertyType] = []
    private let methodName: String
    private let parameters: [Parameters]
    private var shouldCallSuper: Bool {
        parameters.contains { $0 == .overriding }
    }

    /// Generates a property clearing method builder.
    ///
    ///  - Parameters:
    ///      - methodName: name of the method to be created.
    ///      - `parameters`: method parameters.
    ///  - Returns: method of properties clearing.
    ///
    init(methodName: String, parameters: [Parameters]) {
        self.methodName = methodName
        self.parameters = parameters
    }

    /// - Adds the property to the clearing repository.
    ///
    ///  - Parameter propertyName: property name.
    ///
    func addProperty(_ propertyName: PropertyType) {
        propertiesStorage.append(propertyName)
    }

    /// - Generates a clearing method unless the type is a `final` class or `actor`.
    /// - For non-final classes, generates empty methods so subclasses can override them.
    ///
    ///  - Parameter dataStructure: data structure in which the method is created.
    ///  - Returns: declaration of the property clearing method.
    ///
    func makeClearMethodIfNeeded(dataStructure: DataStructure) -> FunctionDeclSyntax? {
        if dataStructure != .nonFinalClass, propertiesStorage.isEmpty {
            return nil
        }

        let modifiers = parameters.reduce(into: DeclModifierListSyntax()) { partialResult, parameter in
            let modifier: DeclModifierSyntax

            switch parameter {
            case .open:
                modifier = .init(name: .keyword(.open))
            case .overriding:
                modifier = .init(name: .keyword(.override))
            case .public:
                modifier = .init(name: .keyword(.public))
            }

            partialResult.append(modifier)
        }

        return .init(
            modifiers: modifiers,
            name: .identifier(methodName),
            signature: .init(
                parameterClause: .init(parameters: .init()),
                effectSpecifiers: dataStructure == .actor ? .init(asyncSpecifier: .keyword(.async)) : nil
            ),
            body: makeClearMethodBody(dataStructure: dataStructure)
        )
    }

    /// Generates the body of the property clearing method.
    ///
    /// - Returns: the body of the property clearing method.
    ///
    private func makeClearMethodBody(dataStructure: DataStructure) -> CodeBlockSyntax {
        let body = CodeBlockSyntax(
            statements: propertiesStorage.enumerated()
                .reduce(into: CodeBlockItemListSyntax()) { partialResult, item in
                    if item.offset == 0, shouldCallSuper {
                        let memberAccessExpr = MemberAccessExprSyntax(
                            base: SuperExprSyntax(),
                            declName: .init(baseName: .identifier(methodName))
                        )
                        let functionCallExpr = FunctionCallExprSyntax(
                            calledExpression: memberAccessExpr,
                            leftParen: .leftParenToken(),
                            arguments: .init([]),
                            rightParen: .rightParenToken()
                        )
                        if dataStructure == .actor {
                            let item = CodeBlockItemSyntax.Item(AwaitExprSyntax(expression: functionCallExpr))
                            let codeBlockItem = CodeBlockItemSyntax(item: item)
                            partialResult.append(codeBlockItem)
                        } else {
                            let item = CodeBlockItemSyntax.Item(functionCallExpr)
                            let codeBlockItem = CodeBlockItemSyntax(item: item)
                            partialResult.append(codeBlockItem)
                        }
                    }

                    let rightOperand: ExprSyntaxProtocol

                    switch item.element {
                    case .nilable:
                        rightOperand = NilLiteralExprSyntax()
                    case .collection:
                        rightOperand = ArrayExprSyntax(elements: .init([]))
                    }

                    let expr = InfixOperatorExprSyntax(
                        leftOperand: DeclReferenceExprSyntax(baseName: .identifier(item.element.propertyName)),
                        operator: AssignmentExprSyntax(equal: .equalToken()),
                        rightOperand: rightOperand
                    )
                    let item = CodeBlockItemSyntax.Item(expr)
                    let codeBlockItem = CodeBlockItemSyntax(item: item)
                    partialResult.append(codeBlockItem)
                }
        )

        propertiesStorage = []

        return body
    }
}
