//
//  AutoEquatableMacro.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

// MARK: - EnumCase

/// Enum case information.
struct EnumCase {
    /// Title of the enum case.
    let title: String

    /// Parameters of the enum case.
    let parameters: [String]
}

// MARK: - MemberListType

/// Declaration type.
enum MemberListType {
    /// Enum type.
    case `enum`(enumCases: [EnumCase], variables: [VariableDeclSyntax])

    /// Any other data structure other than `enum` is used.
    ///
    ///  - Parameter variables: variables of the data structure.
    ///
    case other(variables: [VariableDeclSyntax])
}

// MARK: - AutoEquatableMacro

public struct AutoEquatableMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        var accessModifiers = DeclModifierListSyntax()
        let memberBlock = declaration.memberBlock
        let funcShouldBePublic = !declaration.modifiers
            .filter { $0.name.text == .public || $0.name.text == .open }
            .isEmpty
        let variables = memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { !$0.isIgnored }

        if funcShouldBePublic {
            accessModifiers.append(.init(name: .keyword(.public)))
        }

        accessModifiers.append(.init(name: .keyword(.static)))

        if declaration.as(EnumDeclSyntax.self) != nil {
            let enumCases = mapMembersToEnumCases(declaration.memberBlock)

            return [
                makeExtensionDecl(
                    type: type,
                    accessModifiers: accessModifiers,
                    bodyContentType: .enum(enumCases: enumCases, variables: variables)
                ),
            ]
        }

        return [
            makeExtensionDecl(
                type: type,
                accessModifiers: accessModifiers,
                bodyContentType: .other(variables: variables)
            ),
        ]
    }

    /// Generates an extension declaration by filling in either using class properties, structures, or `enum` cases.
    ///
    ///  - Parameters:
    ///     - type: expandable type.
    ///     - bodyContentType: content for filling the `==` method.
    ///  - Returns: an extension declaration.
    ///
    private static func makeExtensionDecl(
        type: some TypeSyntaxProtocol,
        accessModifiers: DeclModifierListSyntax,
        bodyContentType: MemberListType
    ) -> ExtensionDeclSyntax {
        let resultMemberBlock = MemberBlockSyntax(
            members: .init(
                arrayLiteral: .init(
                    decl: makeEqualFunc(
                        type: type,
                        accessModifiers: accessModifiers,
                        bodyContentType: bodyContentType
                    )
                )
            )
        )
        let equatableInheritedType = InheritedTypeSyntax(
            type: IdentifierTypeSyntax(name: .identifier(.equatable))
        )
        let resultInheritanceClause = InheritanceClauseSyntax(
            inheritedTypes: .init(arrayLiteral: equatableInheritedType)
        )

        return .init(
            extendedType: type,
            inheritanceClause: resultInheritanceClause,
            memberBlock: resultMemberBlock
        )
    }

    /// Maps `MemberBlockSyntax` to the `EnumCase` array.
    ///
    ///  - Parameter memberBlock: a block with methods or properties in the data structure.
    ///  - Returns: an array of the `EnumCase` with the names and parameters of the cases.
    ///
    private static func mapMembersToEnumCases(_ memberBlock: MemberBlockSyntax) -> [EnumCase] {
        memberBlock.members
            .map {
                guard let decl = $0.decl.as(EnumCaseDeclSyntax.self),
                      let title = decl.elements.first?.name.text else { return nil }

                let parameters = decl.elements.first?.parameterClause?.parameters
                    .compactMap { makeParameterName($0) } ?? []

                return EnumCase(title: title, parameters: parameters)
            }
            .compactMap(\.self)
    }

    /// Generates the name of the parameter based on the associative type of the case parameter.
    /// For uniqueness, the suffix is used in the form of the first 4 characters of the `UUID`.
    ///
    ///  - Parameter parameter: the `enum` case parameter.
    ///  - Returns: the name of the parameter by associative type.
    ///
    private static func makeParameterName(_ parameter: EnumCaseParameterSyntax) -> String {
        if parameter.firstName == nil, parameter.secondName == nil {
            return (parameter.type.as(IdentifierTypeSyntax.self)?.name.text ?? .empty) + UUID().uuidString.prefix(4)
        }
        if parameter.firstName?.text == .underscore {
            return parameter.secondName?.text ?? .empty
        } else {
            return parameter.firstName?.text ?? .empty
        }
    }

    /// Generates a declaration of the `==` method.
    ///
    ///    - Parameters:
    ///      - type: expandable type.
    ///      - bodyContentType: content for filling the `==` method.
    ///    - Returns: the method declaration.
    ///
    private static func makeEqualFunc(
        type: some TypeSyntaxProtocol,
        accessModifiers: DeclModifierListSyntax,
        bodyContentType: MemberListType
    ) -> FunctionDeclSyntax {
        let parameters = FunctionParameterListSyntax(
            arrayLiteral: .init(firstName: .identifier(.lhs), type: type, trailingComma: .commaToken()),
            .init(firstName: .identifier(.rhs), type: type)
        )
        let returnClause = ReturnClauseSyntax(type: IdentifierTypeSyntax(name: .identifier(.bool)))
        let signature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: parameters),
            returnClause: returnClause
        )

        let codeBlock: CodeBlockSyntax

        switch bodyContentType {
        case .enum(let enumCases, let variables):
            let switchExpr = makeSwitchExpr(enumCases: enumCases, enumHasVariables: !variables.isEmpty)
            let item = ExpressionStmtSyntax(expression: switchExpr)
            let codeBlockItem = CodeBlockItemSyntax.Item(item)

            var stmnts = CodeBlockItemListSyntax()

            if !variables.isEmpty {
                let otherVariablesCheckVariable = makeOtherVariablesCheckVariable(variables: variables)
                stmnts.append(.init(item: .init(otherVariablesCheckVariable)))
            }

            stmnts.append(.init(item: codeBlockItem))
            codeBlock = CodeBlockSyntax(statements: stmnts)
        case .other(let variables):
            codeBlock = makeFuncBody(variables: variables)
        }

        return .init(
            modifiers: accessModifiers,
            name: .identifier("== "),
            signature: signature,
            body: codeBlock
        )
    }

    /// Generates a constant `otherVariablesCheck` in which the `enum` properties are checked for equivalence.
    ///
    ///   - Parameter variables: the `enum` properties.
    ///   - Returns: a declaration of the `otherVariablesCheck` constant.
    ///
    private static func makeOtherVariablesCheckVariable(
        variables: [VariableDeclSyntax]
    ) -> VariableDeclSyntax {
        let variablesNames = variables
            .map { $0.name?.identifier.text ?? .empty }
            .filter { !$0.isEmpty }
        let exprListSyntax: ExprListSyntax = variablesNames
            .enumerated()
            .reduce(into: ExprListSyntax()) { partialResult, item in
                let lhsDecl = MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .identifier(.lhs)),
                    period: .periodToken(),
                    declName: .init(baseName: .identifier(item.element))
                )
                partialResult.append(.init(lhsDecl))

                let `operator` = BinaryOperatorExprSyntax(operator: .binaryOperator("=="))
                partialResult.append(.init(`operator`))

                let rhsDecl = MemberAccessExprSyntax(
                    base: DeclReferenceExprSyntax(baseName: .identifier(.rhs)),
                    period: .periodToken(),
                    declName: .init(baseName: .identifier(item.element))
                )
                partialResult.append(.init(rhsDecl))

                if item.offset != variablesNames.count - 1 {
                    let `operator` = BinaryOperatorExprSyntax(operator: .binaryOperator("&&"))
                    partialResult.append(.init(`operator`))
                }
            }

        let sequenceExpr = SequenceExprSyntax(elements: exprListSyntax)

        let initializer = InitializerClauseSyntax(
            equal: .equalToken(),
            value: sequenceExpr
        )
        return VariableDeclSyntax(
            Keyword.let,
            name: .init(stringLiteral: .otherVariablesCheck),
            initializer: initializer
        )
    }

    /// Generates the `Switch` expression.
    ///
    ///  - Parameter enumCases: the `enum` cases.
    ///  - Returns: the `Switch` expression.
    ///
    private static func makeSwitchExpr(enumCases: [EnumCase], enumHasVariables: Bool) -> SwitchExprSyntax {
        .init(
            subject: TupleExprSyntax(
                elements: .init([
                    .init(
                        expression: DeclReferenceExprSyntax(baseName: .identifier(.lhs)),
                        trailingComma: .commaToken()
                    ),
                    .init(expression: DeclReferenceExprSyntax(baseName: .identifier(.rhs))),
                ])
            ),
            cases: makeEnumCases(enumCases, enumHasVariables: enumHasVariables)
        )
    }

    /// Generates the `enum` cases to check equivalence.
    ///
    ///  - Parameter cases: an `EnumCase` array.
    ///  - Returns: the syntax of the cases list in the `Switch` expression.
    ///
    private static func makeEnumCases(_ cases: [EnumCase], enumHasVariables: Bool) -> SwitchCaseListSyntax {
        var caseList = cases
            .map { makeEnumCase($0, enumHasVariables: enumHasVariables) }
            .reduce(into: SwitchCaseListSyntax()) { $0.append(.switchCase($1)) }
        caseList.append(.switchCase(makeDefaultCase()))

        return caseList
    }

    /// Generates an `enum` case with or without parameters for use in a `Switch` expression.
    ///
    ///   - Parameter caseModel: the `enum` case model.
    ///   - Returns: the syntax of the case for the `Switch` expression.
    ///
    private static func makeEnumCase(_ caseModel: EnumCase, enumHasVariables: Bool) -> SwitchCaseSyntax {
        let tupleExpr: TupleExprSyntax = if caseModel.parameters.isEmpty {
            makeEnumCaseTupleExprWithoutParameter(caseModel)
        } else {
            makeEnumCaseTupleExprWithParameters(caseModel)
        }

        let switchCaseItem = SwitchCaseItemSyntax(
            pattern: ExpressionPatternSyntax(expression: tupleExpr)
        )
        let label = SwitchCaseLabelSyntax(
            caseItems: .init([switchCaseItem])
        )

        let returnStmt: ReturnStmtSyntax = if caseModel.parameters.isEmpty, !enumHasVariables {
            ReturnStmtSyntax(
                returnKeyword: .keyword(.return),
                expression: BooleanLiteralExprSyntax(literal: .keyword(.true))
            )
        } else if enumHasVariables, caseModel.parameters.isEmpty {
            ReturnStmtSyntax(
                returnKeyword: .keyword(.return),
                expression: DeclReferenceExprSyntax(baseName: .identifier(.otherVariablesCheck))
            )
        } else {
            makeReturnStmt(parameters: caseModel.parameters, enumHasVariables: enumHasVariables)
        }

        let codeBlockItem = CodeBlockItemSyntax.Item(returnStmt)
        let stmts = CodeBlockItemListSyntax([.init(item: codeBlockItem)])

        return SwitchCaseSyntax(
            label: SwitchCaseSyntax.Label(label),
            statements: stmts
        )
    }

    /// Generates a `TupleExprSyntax` syntax without parameters.
    ///
    ///   - Parameter caseModel: a case model with no parameters.
    ///   - Returns: the tuple syntax.
    ///
    private static func makeEnumCaseTupleExprWithoutParameter(_ caseModel: EnumCase) -> TupleExprSyntax {
        let leftCase = LabeledExprSyntax(
            expression: MemberAccessExprSyntax(
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(caseModel.title))
            ),
            trailingComma: .commaToken()
        )

        let rightCase = LabeledExprSyntax(
            expression: MemberAccessExprSyntax(
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(caseModel.title))
            )
        )

        return TupleExprSyntax(elements: LabeledExprListSyntax([leftCase, rightCase]))
    }

    /// Generates a `TupleExprSyntax` syntax with parameters.
    ///
    ///   - Parameter caseModel: a case model with parameters.
    ///   - Returns: the case syntax.
    ///
    private static func makeEnumCaseTupleExprWithParameters(_ caseModel: EnumCase) -> TupleExprSyntax {
        var leftExpr = makeLabeledExprWithParameters(caseModel, prefix: .lhs)
        leftExpr.trailingComma = .commaToken()
        let rightExpr = makeLabeledExprWithParameters(caseModel, prefix: .rhs)

        let elements = LabeledExprListSyntax([leftExpr, rightExpr])

        return TupleExprSyntax(
            leftParen: .leftParenToken(),
            elements: elements,
            rightParen: .rightParenToken()
        )
    }

    /// Generates a string of cases inside the `Switch`.
    ///
    ///  - Parameters:
    ///     - enumCase: the `enum` case to create a string for.
    ///     - prefix: `lhs` or `rhs`.
    ///  - Returns: the string with the case inside the `Switch`.
    ///
    private static func makeLabeledExprWithParameters(
        _ enumCase: EnumCase,
        prefix: String
    ) -> LabeledExprSyntax {
        let arguments = enumCase.parameters
            .enumerated()
            .reduce(into: LabeledExprListSyntax()) { partialResult, item in
                let isLast = item.offset + 1 == enumCase.parameters.count

                let labeledExpr = LabeledExprSyntax(
                    expression: PatternExprSyntax(
                        pattern: IdentifierPatternSyntax(identifier: .identifier(prefix + item.element.capitalizedFirstLetter))
                    ),
                    trailingComma: isLast ? nil : .commaToken()
                )

                partialResult.append(labeledExpr)
            }

        let calledExpr = MemberAccessExprSyntax(
            period: .periodToken(),
            declName: DeclReferenceExprSyntax(baseName: .identifier(enumCase.title))
        )

        let funcExpr = FunctionCallExprSyntax(
            calledExpression: calledExpr,
            leftParen: .leftParenToken(),
            arguments: arguments,
            rightParen: .rightParenToken(),
            additionalTrailingClosures: MultipleTrailingClosureElementListSyntax()
        )

        let pattern = ValueBindingPatternSyntax(
            bindingSpecifier: .keyword(.let),
            pattern: ExpressionPatternSyntax(expression: funcExpr)
        )
        let expr = PatternExprSyntax(pattern: pattern)

        return LabeledExprSyntax(expression: expr)
    }

    /// Generates the `default` syntax of a case with a `return false` expression.
    ///
    ///  - Returns: the syntax of `case` inside the `Switch`.
    ///
    private static func makeDefaultCase() -> SwitchCaseSyntax {
        let label = SwitchDefaultLabelSyntax(defaultKeyword: .keyword(.default), colon: .colonToken())

        let returnStmt = ReturnStmtSyntax(
            returnKeyword: .keyword(.return),
            expression: BooleanLiteralExprSyntax(booleanLiteral: false)
        )
        let codeBlockItem = CodeBlockItemSyntax.Item(returnStmt)
        let item = CodeBlockItemSyntax(item: codeBlockItem)
        let stmts = CodeBlockItemListSyntax([item])

        return .init(
            label: SwitchCaseSyntax.Label(label),
            statements: stmts
        )
    }

    /// Generates a string with the return value in the `enum` case with parameters.
    ///
    ///    - Parameter parameters: case arguments.
    ///    - Returns: the return statement syntax.
    ///
    private static func makeReturnStmt(parameters: [String], enumHasVariables: Bool) -> ReturnStmtSyntax {
        let elements: ExprListSyntax = parameters
            .enumerated()
            .reduce(into: ExprListSyntax()) { partialResult, item in
                let lhsDecl = DeclReferenceExprSyntax(baseName: .identifier(.lhs + item.element.capitalizedFirstLetter))
                partialResult.append(.init(lhsDecl))

                let lhsBinaryOperator = BinaryOperatorExprSyntax(operator: .binaryOperator("=="))
                partialResult.append(.init(lhsBinaryOperator))

                let rhsDecl = DeclReferenceExprSyntax(baseName: .identifier(.rhs + item.element.capitalizedFirstLetter))
                partialResult.append(.init(rhsDecl))

                if item.offset + 1 != parameters.count {
                    let rhsBinaryOperator = BinaryOperatorExprSyntax(operator: .binaryOperator("&&"))
                    partialResult.append(.init(rhsBinaryOperator))
                } else {
                    if enumHasVariables {
                        let binaryOperator = BinaryOperatorExprSyntax(operator: .binaryOperator("&&"))
                        partialResult.append(.init(binaryOperator))

                        let otherVariablesCheck = DeclReferenceExprSyntax(
                            baseName: .identifier(.otherVariablesCheck)
                        )
                        partialResult.append(.init(otherVariablesCheck))
                    }
                }
            }
        let expr = SequenceExprSyntax(elements: elements)

        return .init(returnKeyword: .keyword(.return), expression: expr)
    }

    /// Generates the `==` method body.
    ///
    ///  - Parameter variables: list of data type properties.
    ///  - Returns: the syntax of the code block for the method.
    ///
    private static func makeFuncBody(variables: [VariableDeclSyntax]) -> CodeBlockSyntax {
        var elements = ExprListSyntax()

        for (index, member) in variables.enumerated() {
            if index != 0 {
                elements.append(.init(BinaryOperatorExprSyntax(operator: .binaryOperator("&&"))))
            }

            let firstMember = MemberAccessExprSyntax(
                base: DeclReferenceExprSyntax(baseName: .identifier(.lhs)),
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(member.name?.description ?? .empty))
            )

            let binaryOperator = BinaryOperatorExprSyntax(operator: .binaryOperator("=="))

            let secondMember = MemberAccessExprSyntax(
                base: DeclReferenceExprSyntax(baseName: .identifier(.rhs)),
                period: .periodToken(),
                declName: DeclReferenceExprSyntax(baseName: .identifier(member.name?.description ?? .empty))
            )

            if member.type?.type.is(FunctionTypeSyntax.self) == true {
                let firstMemberClosureCalling = FunctionCallExprSyntax(
                    calledExpression: firstMember,
                    leftParen: .leftParenToken(),
                    arguments: .init(),
                    rightParen: .rightParenToken()
                )
                let secondMemberClosureCalling = FunctionCallExprSyntax(
                    calledExpression: secondMember,
                    leftParen: .leftParenToken(),
                    arguments: .init(),
                    rightParen: .rightParenToken()
                )
                elements.append(.init(firstMemberClosureCalling))
                elements.append(.init(binaryOperator))
                elements.append(.init(secondMemberClosureCalling))
            } else {
                elements.append(.init(firstMember))
                elements.append(.init(binaryOperator))
                elements.append(.init(secondMember))
            }
        }

        let item = CodeBlockItemSyntax.Item(SequenceExprSyntax(elements: elements))
        let codeBlockItem = CodeBlockItemSyntax(item: item)

        let statements = CodeBlockItemListSyntax(arrayLiteral: codeBlockItem)

        return .init(statements: statements)
    }
}
