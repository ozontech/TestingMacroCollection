//
//  SetPropertyFunctionBuilder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax

/// A method collector for assigning a value to a property.
/// Generates methods for the `returnValue`, `error`, and `closure` properties.
///
///     func setMakeWorkReturnValue(_ returnValue: Bool) {
///         makeWorkReturnValue = returnValue
///     }
///
enum SetPropertyFunctionBuilder {
    enum PropertyType: String {
        /// The `returnValue` property
        case returnValue
        /// The `closure` property
        case closure
        /// The `error` property
        case error
        /// A property is added to the protocol on the client
        case client
    }

    /// Generates a method for assigning a value.
    ///
    ///  - Parameters:
    ///     - propertyType: property type.
    ///     - propertyName: property name without prefixes.
    ///     - accessModifiers: method access modifiers.
    ///     - type: property type.
    ///  - Returns: the method syntax with a signature and body.
    ///
    static func makeSetMethod(
        for propertyType: SetPropertyFunctionBuilder.PropertyType,
        propertyName: String,
        accessModifiers: DeclModifierListSyntax,
        type: TypeSyntaxProtocol
    ) -> FunctionDeclSyntax {
        guard propertyType != .client else {
            return makeSetMethodForClientVariable(
                propertyName: propertyName,
                accessModifiers: accessModifiers,
                type: type
            )
        }

        let propertyPrefix = propertyType.rawValue.capitalizedFirstLetter

        let assignment = InfixOperatorExprSyntax(
            leftOperand: DeclReferenceExprSyntax(
                baseName: .identifier(propertyName + propertyPrefix)
            ),
            operator: AssignmentExprSyntax(),
            rightOperand: DeclReferenceExprSyntax(baseName: .identifier(propertyType.rawValue))
        )
        let assignmentItem = CodeBlockItemSyntax(item: .init(assignment))

        return FunctionDeclSyntax(
            modifiers: accessModifiers,
            name: .identifier(.set.lowercased() + propertyName.capitalizedFirstLetter + propertyPrefix),
            signature: .init(
                parameterClause: .init(
                    parameters: .init(arrayLiteral: .init(
                        firstName: .identifier("_"),
                        secondName: .identifier(propertyType.rawValue),
                        type: type
                    ))
                )
            ),
            body: .init(statements: .init(arrayLiteral: assignmentItem))
        )
    }

    /// Generates a method for assigning a value to a property for protocol properties.
    ///
    ///  - Parameters:
    ///   - propertyName: protocol property name.
    ///   - accessModifiers: method access modifiers.
    ///   - type: property type.
    ///  - Returns: the method declaration for assigning the value of the protocol property.
    ///
    private static func makeSetMethodForClientVariable(
        propertyName: String,
        accessModifiers: DeclModifierListSyntax,
        type: TypeSyntaxProtocol
    ) -> FunctionDeclSyntax {
        let leftOperand = MemberAccessExprSyntax(
            base: DeclReferenceExprSyntax(baseName: .identifier(._self)),
            period: .periodToken(),
            declName: .init(baseName: .identifier(propertyName))
        )
        let assignment = InfixOperatorExprSyntax(
            leftOperand: leftOperand,
            operator: AssignmentExprSyntax(),
            rightOperand: DeclReferenceExprSyntax(baseName: .identifier(.value))
        )
        let assignmentItem = CodeBlockItemSyntax(item: .init(assignment))

        let _type = if type.is(FunctionTypeSyntax.self) {
            AttributedTypeSyntax(
                specifiers: .init([]),
                attributes: .init(
                    arrayLiteral: .attribute(
                        AttributeSyntax(
                            atSign: .atSignToken(),
                            attributeName: IdentifierTypeSyntax(name: .keyword(.escaping))
                        )
                    )
                ),
                baseType: type
            )
        } else {
            type
        }

        return FunctionDeclSyntax(
            modifiers: accessModifiers,
            name: .identifier(.set.lowercased() + propertyName.capitalizedFirstLetter),
            signature: .init(
                parameterClause: .init(
                    parameters: .init(arrayLiteral: .init(
                        firstName: .identifier("_"),
                        secondName: .identifier(.value),
                        type: _type
                    ))
                )
            ),
            body: .init(statements: .init(arrayLiteral: assignmentItem))
        )
    }
}
