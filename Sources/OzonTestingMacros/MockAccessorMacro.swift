//
//  MockAccessorMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - MockAccessorError

/// `Compile-time` error thrown by the `MockAccessor` macro.
enum MockAccessorError: CustomStringConvertible, Error {
    case notFoundName
    case appliedNotToProperty

    var description: String {
        switch self {
        case .notFoundName:
            "Property name not found"
        case .appliedNotToProperty:
            "@MockAccessor can only be attached to a property"
        }
    }
}

// MARK: - MockAccessorMacro

public struct MockAccessorMacro: AccessorMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            throw MockAccessorError.appliedNotToProperty
        }
        guard let name = varDecl.name?.identifier.text else {
            throw MockAccessorError.notFoundName
        }

        let getter = makeGetter(propertyName: name)
        let setter = makeSetter(propertyName: name)

        return [getter, setter]
    }

    /// Generates a getter declaration.
    ///
    ///  - Parameter propertyName: name of the property for which the getter is being created.
    ///  - Returns: a getter declaration.
    ///
    private static func makeGetter(propertyName: String) -> AccessorDeclSyntax {
        let memberAccessExpr = MemberAccessExprSyntax(
            base: DeclReferenceExprSyntax(baseName: .identifier(.mock)),
            declName: .init(
                baseName: .identifier(.init(stringLiteral: "underlying" + propertyName.capitalizedFirstLetter))
            )
        )
        let item = CodeBlockItemSyntax.Item(memberAccessExpr)
        let codeBlock = CodeBlockSyntax(
            statements: .init(arrayLiteral: .init(item: item))
        )
        return AccessorDeclSyntax(accessorSpecifier: .keyword(.get), body: codeBlock)
    }

    /// Generates a setter declaration.
    ///
    ///  - Parameter propertyName: name of the property for which the setter is being created.
    ///  - Returns: a setter declaration.
    ///
    private static func makeSetter(propertyName: String) -> AccessorDeclSyntax {
        let memberAccessExpr = MemberAccessExprSyntax(
            base: DeclReferenceExprSyntax(baseName: .identifier(.mock)),
            declName: .init(
                baseName: .identifier(.init(stringLiteral: .underlying + propertyName.capitalizedFirstLetter))
            )
        )
        let infix = InfixOperatorExprSyntax(
            leftOperand: memberAccessExpr,
            operator: AssignmentExprSyntax(equal: .equalToken()),
            rightOperand: DeclReferenceExprSyntax(baseName: .identifier(.newValue))
        )
        let item = CodeBlockItemSyntax.Item(infix)
        let codeBlock = CodeBlockSyntax(statements: .init(arrayLiteral: .init(item: item)))
        return AccessorDeclSyntax(
            accessorSpecifier: .keyword(.set),
            parameters: .init(name: .identifier(.newValue)),
            body: codeBlock
        )
    }
}
