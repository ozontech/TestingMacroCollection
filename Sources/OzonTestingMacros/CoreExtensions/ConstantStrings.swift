//
//  ConstantStrings.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import SwiftSyntax

extension String {
    static let arbitrary = "arbitrary"
    static let `static` = "static"
    static let dynamic = "dynamic"
    static let array = "Array"
    static let dictionary = "Dictionary"
    static let set = "Set"
    static let ignored = "Ignored"
    static let nilable = "Nilable"
    static let mock = "mock"
    static let mainActor = "MainActor"
    static let actor = "Actor"
    static let bool = "Bool"
    static let anyObject = "AnyObject"
    static let sendable = "Sendable"
    static let equatable = "Equatable"
    static let sendableWrapper = "@Sendable"
    static let nonisolated = "nonisolated"
    static let unsafe = "unsafe"
    static let nonisolatedUnsafe = "nonisolated(unsafe)"
    static let task = "Task"
    static let some = "some"
    static let void = "Void"
    static let escaping = "escaping"
    static let error = "Error"
    static let append = "append"

    static let callsCount = "CallsCount"
    static let returnValue = "ReturnValue"
    static let closure = "Closure"
    static let receivedArguments = "ReceivedArguments"
    static let underlying = "underlying"

    static let newValue = "newValue"
    static let value = "value"
    static let lock = "lock"
    static let lhs = "lhs"
    static let rhs = "rhs"
    static let otherVariablesCheck = "otherVariablesCheck"
    static let performLockedAction = "performLockedAction"
    static let assertionFailure = "assertionFailure"
    static let clearFunctionProperties = "clearFunctionProperties"
    static let clearVariableProperties = "clearVariableProperties"
    static let atomicLock = "AtomicLock"

    static let `public` = "public"
    static let `private` = "private"
    static let `fileprivate` = "fileprivate"
    static let open = "open"
    static let `internal` = "internal"
    static let final = "final"

    static let _self = "self"
    static let delegate = "delegate"

    static let associatedTypes = "associatedTypes"
    static let heritability = "heritability"
    static let sendableMode = "sendableMode"
    static let auto = "auto"
    static let unchecked = "unchecked"
    static let defaultValue = "defaultValue"
    static let buildType = "buildType"
    static let unlabeledParam = "unlabeled_param"

    static let mockAccessor = "MockAccessor"
    static let proxyableMock = "ProxyableMock"
    static let functionBodyMock = "FunctionBodyMock"
    static let arbitraryDefaultCaseMacro = "ArbitraryDefaultCase"
    static let arbitraryType = "arbitraryType"
    static let accessModifier = "accessModifier"

    static let randomElementFunctionName = "randomElement"

    static let empted = "Empted"
    static let underscore = "_"
    static let empty = ""
}

extension String {
    func toTokenSyntax() -> TokenSyntax {
        .init(stringLiteral: self)
    }
}
