//
//  PrettyNameTypeFinder.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax

// MARK: - TypeNameGenerator

enum TypeNameGenerator {
    static func readableName(for type: TypeSyntax) -> String {
        let visitor = TypeNameVisitor(viewMode: .sourceAccurate)
        visitor.walk(type)
        return visitor.result
    }
}

// MARK: - TypeNameVisitor

private class TypeNameVisitor: SyntaxVisitor {
    var result = ""

    override func visit(_ node: OptionalTypeSyntax) -> SyntaxVisitorContinueKind {
        result = "Optional" + TypeNameGenerator.readableName(for: node.wrappedType)
        return .skipChildren
    }

    override func visit(_ node: AttributedTypeSyntax) -> SyntaxVisitorContinueKind {
        result = "Attributed" + TypeNameGenerator.readableName(for: node.baseType)
        return .skipChildren
    }

    override func visit(_ node: ImplicitlyUnwrappedOptionalTypeSyntax) -> SyntaxVisitorContinueKind {
        result = "Optional" + TypeNameGenerator.readableName(for: node.wrappedType)
        return .skipChildren
    }

    override func visit(_ node: ArrayTypeSyntax) -> SyntaxVisitorContinueKind {
        result = "Array" + TypeNameGenerator.readableName(for: node.element).capitalizedFirstLetter
        return .skipChildren
    }

    override func visit(_ node: DictionaryTypeSyntax) -> SyntaxVisitorContinueKind {
        let keyName = TypeNameGenerator.readableName(for: node.key)
        let valueName = TypeNameGenerator.readableName(for: node.value)
        result = "Dict\(keyName.capitalizedFirstLetter)\(valueName.capitalizedFirstLetter)"
        return .skipChildren
    }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        result = node.name.text
        return .skipChildren
    }

    override func visit(_ node: TupleTypeSyntax) -> SyntaxVisitorContinueKind {
        result = "Tuple"
        return .skipChildren
    }

    override func visit(_ node: FunctionTypeSyntax) -> SyntaxVisitorContinueKind {
        result = "Function"
        return .skipChildren
    }

    override func visit(_ node: SomeOrAnyTypeSyntax) -> SyntaxVisitorContinueKind {
        result = node.someOrAnySpecifier.text + TypeNameGenerator.readableName(for: node.constraint)
        return .skipChildren
    }
}
