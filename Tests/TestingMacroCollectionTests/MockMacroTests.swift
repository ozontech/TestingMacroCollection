//
//  MockMacroTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class MockMacroTests: XCTestCase {
    func testMockMacro_withEqualSignatures() {
        assertMacroExpansion(
        """
        @Mock
        protocol MethodOverloading {
            func job<T>(arg: T)
            func job<T>(arg: T?)
            
            func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate)
            func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService)
            func jobOne(_ arg1: [String: Int], _ arg2: (Bool, Int), _ arg3: @Sendable @escaping () -> Void)
        }
        """,
        expandedSource:
        """
        protocol MethodOverloading {
            func job<T>(arg: T)
            func job<T>(arg: T?)
            
            func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate)
            func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService)
            func jobOne(_ arg1: [String: Int], _ arg2: (Bool, Int), _ arg3: @Sendable @escaping () -> Void)
        }
        
        final class MethodOverloadingMock: MethodOverloading {
        
            // MARK: - Default Empty Init

            init() {
            }

            // MARK: - Deinit

            func clearFunctionProperties() {
                jobArgReceivedArguments = []
                jobArgClosure = nil
                jobArgOptionalTReceivedArguments = []
                jobArgOptionalTClosure = nil
                jobOneArg1Arg2Arg3ReceivedArguments = []
                jobOneArg1Arg2Arg3Closure = nil
                jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceReceivedArguments = []
                jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceClosure = nil
                jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionReceivedArguments = []
                jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionClosure = nil
            }

            deinit {
                clearFunctionProperties()
            }

            private let lock = AtomicLock()

            // MARK: - job

            func job<T>(arg: T) {
                lock.performLockedAction {
                    jobArgCallsCount += 1
                    jobArgReceivedArguments.append(arg)
                }
                jobArgClosure?(arg)
            }
            var jobArgCallsCount = 0
            var jobArgReceivedArguments: [Any] = []
            var jobArgClosure: ((Any) -> Void)?

            // MARK: - job

            func job<T>(arg: T?) {
                lock.performLockedAction {
                    jobArgOptionalTCallsCount += 1
                    jobArgOptionalTReceivedArguments.append(arg)
                }
                jobArgOptionalTClosure?(arg)
            }
            var jobArgOptionalTCallsCount = 0
            var jobArgOptionalTReceivedArguments: [Any?] = []
            var jobArgOptionalTClosure: ((Any?) -> Void)?

            // MARK: - jobOne

            func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate) {
                lock.performLockedAction {
                    jobOneArg1Arg2Arg3CallsCount += 1
                    jobOneArg1Arg2Arg3ReceivedArguments.append((arg1, arg2, arg3))
                }
                jobOneArg1Arg2Arg3Closure?(arg1, arg2, arg3)
            }
            var jobOneArg1Arg2Arg3CallsCount = 0
            var jobOneArg1Arg2Arg3ReceivedArguments: [(Character, SecTrust, SecCertificate)] = []
            var jobOneArg1Arg2Arg3Closure: ((Character, SecTrust, SecCertificate) -> Void)?

            // MARK: - jobOne

            func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService) {
                lock.performLockedAction {
                    jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceCallsCount += 1
                    jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceReceivedArguments.append((arg1, arg2, arg3))
                }
                jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceClosure?(arg1, arg2, arg3)
            }
            var jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceCallsCount = 0
            var jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceReceivedArguments: [(Int?, [Bool], IParentService)] = []
            var jobOneArg1OptionalIntArg2ArrayBoolArg3someIParentServiceClosure: ((Int?, [Bool], IParentService) -> Void)?

            // MARK: - jobOne

            func jobOne(_ arg1: [String: Int], _ arg2: (Bool, Int), _ arg3: @Sendable @escaping () -> Void) {
                lock.performLockedAction {
                    jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionCallsCount += 1
                    jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionReceivedArguments.append((arg1, arg2, arg3))
                }
                jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionClosure?(arg1, arg2, arg3)
            }
            var jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionCallsCount = 0
            var jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionReceivedArguments: [([String: Int], (Bool, Int), @Sendable () -> Void)] = []
            var jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionClosure: (([String: Int], (Bool, Int), @Sendable @escaping () -> Void) -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_withActorGeneric() {
        assertMacroExpansion(
        """
        @Mock
        protocol GenericActor: Actor {
            func test_simple<T>(value: T) async -> T
            func test_complex<T, E>(value: [T], argument: (T, E)) async throws -> [String: E]
            func test_closure<T, E>(closure: @escaping (@Sendable (T, E) -> E)) async
            func test_closure_with_return_value<T, E>(closure: @escaping (@Sendable (T, E) -> E)) async -> [T]
        }
        """,
        expandedSource:
        """
        protocol GenericActor: Actor {
            func test_simple<T>(value: T) async -> T
            func test_complex<T, E>(value: [T], argument: (T, E)) async throws -> [String: E]
            func test_closure<T, E>(closure: @escaping (@Sendable (T, E) -> E)) async
            func test_closure_with_return_value<T, E>(closure: @escaping (@Sendable (T, E) -> E)) async -> [T]
        }
        
        actor GenericActorMock: GenericActor {
        
            // MARK: - Default Empty Init

            init() {
            }

            // MARK: - Deinit

            func clearFunctionProperties() async {
                test_simpleValueReceivedArguments = []
                test_simpleValueClosure = nil
                test_simpleValueReturnValue = nil
                test_complexValueArgumentReceivedArguments = []
                test_complexValueArgumentError = nil
                test_complexValueArgumentClosure = nil
                test_complexValueArgumentReturnValue = nil
                test_closureClosureReceivedArguments = []
                test_closureClosureClosure = nil
                test_closure_with_return_valueClosureReceivedArguments = []
                test_closure_with_return_valueClosureClosure = nil
                test_closure_with_return_valueClosureReturnValue = nil
            }

            deinit {
                Task { [weak self] in
                    await self?.clearFunctionProperties()
                }
            }

            // MARK: - test_simple

            nonisolated(unsafe) func test_simple<T: Sendable>(value: T) async -> T {
                test_simpleValueCallsCount += 1
                test_simpleValueReceivedArguments.append(value)
                if let test_simpleValueClosure {
                    return await test_simpleValueClosure(value) as! T
                } else {
                    return test_simpleValueReturnValue as! T
                }
            }
            nonisolated(unsafe) var test_simpleValueCallsCount = 0
            nonisolated(unsafe) var test_simpleValueReceivedArguments: [Any] = []
            nonisolated(unsafe) private var test_simpleValueClosure: ((Any) async -> Any)?
            nonisolated(unsafe) private var test_simpleValueReturnValue: Any!

            nonisolated(unsafe) func setTest_simpleValueClosure(_ closure: @escaping (@Sendable (Any) async -> Any)) {
                test_simpleValueClosure = closure
            }
            nonisolated(unsafe) func setTest_simpleValueReturnValue(_ returnValue: Any) {
                test_simpleValueReturnValue = returnValue
            }

            // MARK: - test_complex

            nonisolated(unsafe) func test_complex<T: Sendable, E: Sendable>(value: [T], argument: (T, E)) async throws -> [String: E] {
                test_complexValueArgumentCallsCount += 1
                test_complexValueArgumentReceivedArguments.append((value, argument))
                if let test_complexValueArgumentError {
                    throw test_complexValueArgumentError
                }
                if let test_complexValueArgumentClosure {
                    return try await test_complexValueArgumentClosure(value, argument) as! [String: E]
                } else {
                    return test_complexValueArgumentReturnValue as! [String: E]
                }
            }
            nonisolated(unsafe) var test_complexValueArgumentCallsCount = 0
            nonisolated(unsafe) var test_complexValueArgumentReceivedArguments: [([Any], (Any, Any))] = []
            nonisolated(unsafe) private var test_complexValueArgumentError: Error?
            nonisolated(unsafe) private var test_complexValueArgumentClosure: (([Any], (Any, Any)) async throws -> [String: Any])?
            nonisolated(unsafe) private var test_complexValueArgumentReturnValue: [String: Any]!

            nonisolated(unsafe) func setTest_complexValueArgumentError(_ error: Error) {
                test_complexValueArgumentError = error
            }
            nonisolated(unsafe) func setTest_complexValueArgumentClosure(_ closure: @escaping (@Sendable ([Any], (Any, Any)) async throws -> [String: Any])) {
                test_complexValueArgumentClosure = closure
            }
            nonisolated(unsafe) func setTest_complexValueArgumentReturnValue(_ returnValue: [String: Any]) {
                test_complexValueArgumentReturnValue = returnValue
            }

            // MARK: - test_closure

            nonisolated(unsafe) func test_closure<T: Sendable, E: Sendable>(closure: @escaping (@Sendable (T, E) -> E)) async {
                test_closureClosureCallsCount += 1
                test_closureClosureReceivedArguments.append(closure as! (@Sendable (Any, Any) -> Any))
                await test_closureClosureClosure?(closure as! (@Sendable (Any, Any) -> Any))
            }
            nonisolated(unsafe) var test_closureClosureCallsCount = 0
            nonisolated(unsafe) var test_closureClosureReceivedArguments: [(@Sendable (Any, Any) -> Any)] = []
            nonisolated(unsafe) private var test_closureClosureClosure: ((@escaping (@Sendable (Any, Any) -> Any)) async -> Void)?

            nonisolated(unsafe) func setTest_closureClosureClosure(_ closure: @escaping (@Sendable (@escaping (@Sendable (Any, Any) -> Any)) async -> Void)) {
                test_closureClosureClosure = closure
            }

            // MARK: - test_closure_with_return_value

            nonisolated(unsafe) func test_closure_with_return_value<T: Sendable, E: Sendable>(closure: @escaping (@Sendable (T, E) -> E)) async -> [T] {
                test_closure_with_return_valueClosureCallsCount += 1
                test_closure_with_return_valueClosureReceivedArguments.append(closure as! (@Sendable (Any, Any) -> Any))
                if let test_closure_with_return_valueClosureClosure {
                    return await test_closure_with_return_valueClosureClosure(closure as! (@Sendable (Any, Any) -> Any)) as! [T]
                } else {
                    return test_closure_with_return_valueClosureReturnValue as! [T]
                }
            }
            nonisolated(unsafe) var test_closure_with_return_valueClosureCallsCount = 0
            nonisolated(unsafe) var test_closure_with_return_valueClosureReceivedArguments: [(@Sendable (Any, Any) -> Any)] = []
            nonisolated(unsafe) private var test_closure_with_return_valueClosureClosure: ((@escaping (@Sendable (Any, Any) -> Any)) async -> [Any])?
            nonisolated(unsafe) private var test_closure_with_return_valueClosureReturnValue: [Any]!

            nonisolated(unsafe) func setTest_closure_with_return_valueClosureClosure(_ closure: @escaping (@Sendable (@escaping (@Sendable (Any, Any) -> Any)) async -> [Any])) {
                test_closure_with_return_valueClosureClosure = closure
            }
            nonisolated(unsafe) func setTest_closure_with_return_valueClosureReturnValue(_ returnValue: [Any]) {
                test_closure_with_return_valueClosureReturnValue = returnValue
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_withGeneric() {
        assertMacroExpansion(
        """
        @Mock
        protocol Generic {
            func test_simple<T>(value: T) -> T
            func test_complex<T, E>(value: [T], argument: (T, E)) -> [String: E]
            func test_closure<T, E>(closure: @escaping (T, E) -> E)
            func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T]
        }
        """,
        expandedSource:
        """
        protocol Generic {
            func test_simple<T>(value: T) -> T
            func test_complex<T, E>(value: [T], argument: (T, E)) -> [String: E]
            func test_closure<T, E>(closure: @escaping (T, E) -> E)
            func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T]
        }
        
        final class GenericMock: Generic {
        
            // MARK: - Default Empty Init

            init() {
            }

            // MARK: - Deinit

            func clearFunctionProperties() {
                test_simpleValueReceivedArguments = []
                test_simpleValueClosure = nil
                test_simpleValueReturnValue = nil
                test_complexValueArgumentReceivedArguments = []
                test_complexValueArgumentClosure = nil
                test_complexValueArgumentReturnValue = nil
                test_closureClosureReceivedArguments = []
                test_closureClosureClosure = nil
                test_closure_with_return_valueClosureReceivedArguments = []
                test_closure_with_return_valueClosureClosure = nil
                test_closure_with_return_valueClosureReturnValue = nil
            }

            deinit {
                clearFunctionProperties()
            }

            private let lock = AtomicLock()

            // MARK: - test_simple

            func test_simple<T>(value: T) -> T {
                lock.performLockedAction {
                    test_simpleValueCallsCount += 1
                    test_simpleValueReceivedArguments.append(value)
                }
                if let test_simpleValueClosure {
                    return test_simpleValueClosure(value) as! T
                } else {
                    return test_simpleValueReturnValue as! T
                }
            }
            var test_simpleValueCallsCount = 0
            var test_simpleValueReceivedArguments: [Any] = []
            var test_simpleValueClosure: ((Any) -> Any)?
            var test_simpleValueReturnValue: Any!

            // MARK: - test_complex

            func test_complex<T, E>(value: [T], argument: (T, E)) -> [String: E] {
                lock.performLockedAction {
                    test_complexValueArgumentCallsCount += 1
                    test_complexValueArgumentReceivedArguments.append((value, argument))
                }
                if let test_complexValueArgumentClosure {
                    return test_complexValueArgumentClosure(value, argument) as! [String: E]
                } else {
                    return test_complexValueArgumentReturnValue as! [String: E]
                }
            }
            var test_complexValueArgumentCallsCount = 0
            var test_complexValueArgumentReceivedArguments: [([Any], (Any, Any))] = []
            var test_complexValueArgumentClosure: (([Any], (Any, Any)) -> [String: Any])?
            var test_complexValueArgumentReturnValue: [String: Any]!

            // MARK: - test_closure

            func test_closure<T, E>(closure: @escaping (T, E) -> E) {
                lock.performLockedAction {
                    test_closureClosureCallsCount += 1
                    test_closureClosureReceivedArguments.append(closure as! (Any, Any) -> Any)
                }
                test_closureClosureClosure?(closure as! (Any, Any) -> Any)
            }
            var test_closureClosureCallsCount = 0
            var test_closureClosureReceivedArguments: [(Any, Any) -> Any] = []
            var test_closureClosureClosure: ((@escaping (Any, Any) -> Any) -> Void)?

            // MARK: - test_closure_with_return_value

            func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T] {
                lock.performLockedAction {
                    test_closure_with_return_valueClosureCallsCount += 1
                    test_closure_with_return_valueClosureReceivedArguments.append(closure as! (Any, Any) -> Any)
                }
                if let test_closure_with_return_valueClosureClosure {
                    return test_closure_with_return_valueClosureClosure(closure as! (Any, Any) -> Any) as! [T]
                } else {
                    return test_closure_with_return_valueClosureReturnValue as! [T]
                }
            }
            var test_closure_with_return_valueClosureCallsCount = 0
            var test_closure_with_return_valueClosureReceivedArguments: [(Any, Any) -> Any] = []
            var test_closure_with_return_valueClosureClosure: ((@escaping (Any, Any) -> Any) -> [Any])?
            var test_closure_with_return_valueClosureReturnValue: [Any]!
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_underlyingVarTypeWhenDefaultValueDisabled() {
        assertMacroExpansion(
        """
        @Mock(defaultValue: .none)
        protocol IService {
            var int: Int { get set }

            var array: [String] { get set }
            var dictionary: [Int: String] { get set }
            var tuple: (String, NSError) { get set }
        }
        """,
        expandedSource:
        """
        protocol IService {
            var int: Int { get set }

            var array: [String] { get set }
            var dictionary: [Int: String] { get set }
            var tuple: (String, NSError) { get set }
        }
        
        final class IServiceMock: IService {

            // MARK: - int

            var int: Int {
                get {
                    return underlyingInt
                }
                set(value) {
                    underlyingInt = value
                }
            }
            var underlyingInt: Int!

            // MARK: - array

            var array: [String] {
                get {
                    return underlyingArray
                }
                set(value) {
                    underlyingArray = value
                }
            }
            var underlyingArray: [String]!

            // MARK: - dictionary

            var dictionary: [Int: String] {
                get {
                    return underlyingDictionary
                }
                set(value) {
                    underlyingDictionary = value
                }
            }
            var underlyingDictionary: [Int: String]!
        
            // MARK: - tuple
        
            var tuple: (String, NSError) {
                get {
                    return underlyingTuple
                }
                set(value) {
                    underlyingTuple = value
                }
            }
            var underlyingTuple: (String, NSError)!

            // MARK: - Default Empty Init

            init() {
            }

            // MARK: - Deinit

            func clearVariableProperties() {
                underlyingInt = nil
                underlyingArray = nil
                underlyingDictionary = nil
                underlyingTuple = nil
            }

            deinit {
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_underlyingVarDefaultValues() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            var int: Int { get set }
            var double: Double { get set }
            var someType: any SomeType { get set }
            var string: String { get set }
            var bool: Bool { get set }
            var decimal: Decimal { get set }
            var float: Float { get set }
            var timeInterval: TimeInterval { get set }
            var date: Date { get set }
            var url: URL { get set }
            var data: Data { get set }
            var nsError: NSError { get set }
            var uuid: UUID { get set }
            var some: SomeClass { get set }
        
            var array: [String] { get set }
            var _array: [any SomeType] { get set }
            var set: Set<String> { get set }
            var _set: Set<SomeClass> { get set }
            var dictionary: [String: String] { get set }
            var _dictionary: [String: SomeClass] { get set }
            var __dictionary: [SomeClass: String] { get set }
            var tuple: (String, NSError) { get set }
        }
        """,
        expandedSource:
        """
        protocol IService {
            var int: Int { get set }
            var double: Double { get set }
            var someType: any SomeType { get set }
            var string: String { get set }
            var bool: Bool { get set }
            var decimal: Decimal { get set }
            var float: Float { get set }
            var timeInterval: TimeInterval { get set }
            var date: Date { get set }
            var url: URL { get set }
            var data: Data { get set }
            var nsError: NSError { get set }
            var uuid: UUID { get set }
            var some: SomeClass { get set }
        
            var array: [String] { get set }
            var _array: [any SomeType] { get set }
            var set: Set<String> { get set }
            var _set: Set<SomeClass> { get set }
            var dictionary: [String: String] { get set }
            var _dictionary: [String: SomeClass] { get set }
            var __dictionary: [SomeClass: String] { get set }
            var tuple: (String, NSError) { get set }
        }
        
        final class IServiceMock: IService {
        
            // MARK: - int
        
            var int: Int {
                get {
                    return underlyingInt
                }
                set(value) {
                    underlyingInt = value
                }
            }
            var underlyingInt: Int! = Int.arbitrary()
        
            // MARK: - double
        
            var double: Double {
                get {
                    return underlyingDouble
                }
                set(value) {
                    underlyingDouble = value
                }
            }
            var underlyingDouble: Double! = Double.arbitrary()
        
            // MARK: - someType
        
            var someType: any SomeType {
                get {
                    return underlyingSomeType
                }
                set(value) {
                    underlyingSomeType = value
                }
            }
            var underlyingSomeType: (any SomeType)!
        
            // MARK: - string
        
            var string: String {
                get {
                    return underlyingString
                }
                set(value) {
                    underlyingString = value
                }
            }
            var underlyingString: String! = String.arbitrary()
        
            // MARK: - bool
        
            var bool: Bool {
                get {
                    return underlyingBool
                }
                set(value) {
                    underlyingBool = value
                }
            }
            var underlyingBool: Bool! = Bool.arbitrary()
        
            // MARK: - decimal
        
            var decimal: Decimal {
                get {
                    return underlyingDecimal
                }
                set(value) {
                    underlyingDecimal = value
                }
            }
            var underlyingDecimal: Decimal! = Decimal.arbitrary()
        
            // MARK: - float
        
            var float: Float {
                get {
                    return underlyingFloat
                }
                set(value) {
                    underlyingFloat = value
                }
            }
            var underlyingFloat: Float! = Float.arbitrary()
        
            // MARK: - timeInterval
        
            var timeInterval: TimeInterval {
                get {
                    return underlyingTimeInterval
                }
                set(value) {
                    underlyingTimeInterval = value
                }
            }
            var underlyingTimeInterval: TimeInterval! = TimeInterval.arbitrary()
        
            // MARK: - date
        
            var date: Date {
                get {
                    return underlyingDate
                }
                set(value) {
                    underlyingDate = value
                }
            }
            var underlyingDate: Date! = Date.arbitrary()
        
            // MARK: - url
        
            var url: URL {
                get {
                    return underlyingUrl
                }
                set(value) {
                    underlyingUrl = value
                }
            }
            var underlyingUrl: URL! = URL.arbitrary()
        
            // MARK: - data
        
            var data: Data {
                get {
                    return underlyingData
                }
                set(value) {
                    underlyingData = value
                }
            }
            var underlyingData: Data! = Data.arbitrary()
        
            // MARK: - nsError
        
            var nsError: NSError {
                get {
                    return underlyingNsError
                }
                set(value) {
                    underlyingNsError = value
                }
            }
            var underlyingNsError: NSError! = NSError.arbitrary()
        
            // MARK: - uuid
        
            var uuid: UUID {
                get {
                    return underlyingUuid
                }
                set(value) {
                    underlyingUuid = value
                }
            }
            var underlyingUuid: UUID! = UUID.arbitrary()
        
            // MARK: - some
        
            var some: SomeClass {
                get {
                    return underlyingSome
                }
                set(value) {
                    underlyingSome = value
                }
            }
            var underlyingSome: SomeClass!
        
            // MARK: - array
        
            var array: [String] {
                get {
                    return underlyingArray
                }
                set(value) {
                    underlyingArray = value
                }
            }
            var underlyingArray: [String]! = [String.arbitrary()]
        
            // MARK: - _array
        
            var _array: [any SomeType] {
                get {
                    return underlying_array
                }
                set(value) {
                    underlying_array = value
                }
            }
            var underlying_array: [any SomeType]!
        
            // MARK: - set
        
            var set: Set<String> {
                get {
                    return underlyingSet
                }
                set(value) {
                    underlyingSet = value
                }
            }
            var underlyingSet: Set<String>! = [String.arbitrary()]
        
            // MARK: - _set
        
            var _set: Set<SomeClass> {
                get {
                    return underlying_set
                }
                set(value) {
                    underlying_set = value
                }
            }
            var underlying_set: Set<SomeClass>!
        
            // MARK: - dictionary
        
            var dictionary: [String: String] {
                get {
                    return underlyingDictionary
                }
                set(value) {
                    underlyingDictionary = value
                }
            }
            var underlyingDictionary: [String: String]! = [String.arbitrary(): String.arbitrary()]
        
            // MARK: - _dictionary
        
            var _dictionary: [String: SomeClass] {
                get {
                    return underlying_dictionary
                }
                set(value) {
                    underlying_dictionary = value
                }
            }
            var underlying_dictionary: [String: SomeClass]!
        
            // MARK: - __dictionary
        
            var __dictionary: [SomeClass: String] {
                get {
                    return underlying__dictionary
                }
                set(value) {
                    underlying__dictionary = value
                }
            }
            var underlying__dictionary: [SomeClass: String]!
        
            // MARK: - tuple
        
            var tuple: (String, NSError) {
                get {
                    return underlyingTuple
                }
                set(value) {
                    underlyingTuple = value
                }
            }
            var underlyingTuple: (String, NSError)! = (String.arbitrary(), NSError.arbitrary())
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit
        
            func clearVariableProperties() {
                underlyingInt = nil
                underlyingDouble = nil
                underlyingSomeType = nil
                underlyingString = nil
                underlyingBool = nil
                underlyingDecimal = nil
                underlyingFloat = nil
                underlyingTimeInterval = nil
                underlyingDate = nil
                underlyingUrl = nil
                underlyingData = nil
                underlyingNsError = nil
                underlyingUuid = nil
                underlyingSome = nil
                underlyingArray = nil
                underlying_array = nil
                underlyingSet = nil
                underlying_set = nil
                underlyingDictionary = nil
                underlying_dictionary = nil
                underlying__dictionary = nil
                underlyingTuple = nil
            }
        
            deinit {
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenHasAssociatedTypes_open() {
        assertMacroExpansion(
        """
        @Mock(associatedTypes: ["State": "Any"], .open)
        protocol ViewModel {
            associatedtype State
            var state: State { get set }
        }
        """,
        expandedSource:
        """
        protocol ViewModel {
            associatedtype State
            var state: State { get set }
        }
        
        open class ViewModelMock: ViewModel {
            // MARK: - Typealiases

            public typealias State = Any

            // MARK: - state

            open var state: State {
                get {
                    return underlyingState
                }
                set(value) {
                    underlyingState = value
                }
            }
            open var underlyingState: State!

            // MARK: - Default Empty Init

            public init() {
            }

            // MARK: - Deinit
        
            open func clearFunctionProperties() {
            }
        
            open func clearVariableProperties() {
                underlyingState = nil
            }

            deinit {
                clearFunctionProperties()
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenHasAssociatedTypes_public() {
        assertMacroExpansion(
        """
        @Mock(associatedTypes: ["State": "Any"], .public)
        protocol ViewModel {
            associatedtype State
            var state: State { get set }
        }
        """,
        expandedSource:
        """
        protocol ViewModel {
            associatedtype State
            var state: State { get set }
        }
        
        public final class ViewModelMock: ViewModel {
            // MARK: - Typealiases

            public typealias State = Any

            // MARK: - state

            public var state: State {
                get {
                    return underlyingState
                }
                set(value) {
                    underlyingState = value
                }
            }
            public var underlyingState: State!

            // MARK: - Default Empty Init

            public init() {
            }

            // MARK: - Deinit

            public func clearVariableProperties() {
                underlyingState = nil
            }

            deinit {
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenHasAssociatedTypes_internal() {
        assertMacroExpansion(
        """
        @Mock(associatedTypes: ["State": "Any"])
        protocol ViewModel {
            associatedtype State
            var state: State { get set }
        }
        """,
        expandedSource:
        """
        protocol ViewModel {
            associatedtype State
            var state: State { get set }
        }
        
        final class ViewModelMock: ViewModel {
            // MARK: - Typealiases

            typealias State = Any

            // MARK: - state

            var state: State {
                get {
                    return underlyingState
                }
                set(value) {
                    underlyingState = value
                }
            }
            var underlyingState: State!

            // MARK: - Default Empty Init

            init() {
            }

            // MARK: - Deinit

            func clearVariableProperties() {
                underlyingState = nil
            }

            deinit {
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenProtocolIsActorWithPropertiesAndMethods() {
        assertMacroExpansion(
        """
        @Mock
        protocol Actor: Actor {
            var simpleType: String { get async }
            var optional: String? { get async }
            var forceUnwrapped: String! { get async }
            var tuple: (String, Int) { get async }
            var optionalTuple: (String, Int)? { get async }
            var forceUnwrappedTuple: (String, Int)! { get async }
            var generic: Wrapper<Int> { get async }
            var optionalGeneric: Wrapper<String>? { get async }
            var forceUnwrappedGeneric: Wrapper<Bool>! { get async }
            var closure: () -> Void { get async }
            var optionalClosure: ((String, Int) -> Bool)? { get async }
            var forceUnwrappedClosure: ((Wrapper<Int>?, Wrapper<(String, Int)>?) -> Wrapper<() -> Void>)! { get async }
            
            func simpleMethod() async
            func throwsMethod() async throws
            func throwsReturningMethod() async throws -> Wrapper<Int>?
        }
        """,
        expandedSource:
        """
        protocol Actor: Actor {
            var simpleType: String { get async }
            var optional: String? { get async }
            var forceUnwrapped: String! { get async }
            var tuple: (String, Int) { get async }
            var optionalTuple: (String, Int)? { get async }
            var forceUnwrappedTuple: (String, Int)! { get async }
            var generic: Wrapper<Int> { get async }
            var optionalGeneric: Wrapper<String>? { get async }
            var forceUnwrappedGeneric: Wrapper<Bool>! { get async }
            var closure: () -> Void { get async }
            var optionalClosure: ((String, Int) -> Bool)? { get async }
            var forceUnwrappedClosure: ((Wrapper<Int>?, Wrapper<(String, Int)>?) -> Wrapper<() -> Void>)! { get async }
            
            func simpleMethod() async
            func throwsMethod() async throws
            func throwsReturningMethod() async throws -> Wrapper<Int>?
        }

        actor ActorMock: Actor {

            // MARK: - simpleType

            var simpleType: String {
                get {
                    return underlyingSimpleType
                }
                set(value) {
                    underlyingSimpleType = value
                }
            }
            var underlyingSimpleType: String! = String.arbitrary()
            func setSimpleType(_ value: String ) {
                self.simpleType = value
            }

            // MARK: - optional

            var optional: String?
            func setOptional(_ value: String? ) {
                self.optional = value
            }

            // MARK: - forceUnwrapped

            var forceUnwrapped: String!
            func setForceUnwrapped(_ value: String! ) {
                self.forceUnwrapped = value
            }

            // MARK: - tuple

            var tuple: (String, Int) {
                get {
                    return underlyingTuple
                }
                set(value) {
                    underlyingTuple = value
                }
            }
            var underlyingTuple: (String, Int)! = (String.arbitrary(), Int.arbitrary())
            func setTuple(_ value: (String, Int) ) {
                self.tuple = value
            }

            // MARK: - optionalTuple

            var optionalTuple: (String, Int)?
            func setOptionalTuple(_ value: (String, Int)? ) {
                self.optionalTuple = value
            }

            // MARK: - forceUnwrappedTuple

            var forceUnwrappedTuple: (String, Int)!
            func setForceUnwrappedTuple(_ value: (String, Int)! ) {
                self.forceUnwrappedTuple = value
            }

            // MARK: - generic

            var generic: Wrapper<Int> {
                get {
                    return underlyingGeneric
                }
                set(value) {
                    underlyingGeneric = value
                }
            }
            var underlyingGeneric: Wrapper<Int>!
            func setGeneric(_ value: Wrapper<Int> ) {
                self.generic = value
            }

            // MARK: - optionalGeneric

            var optionalGeneric: Wrapper<String>?
            func setOptionalGeneric(_ value: Wrapper<String>? ) {
                self.optionalGeneric = value
            }

            // MARK: - forceUnwrappedGeneric

            var forceUnwrappedGeneric: Wrapper<Bool>!
            func setForceUnwrappedGeneric(_ value: Wrapper<Bool>! ) {
                self.forceUnwrappedGeneric = value
            }

            // MARK: - closure

            var closure: () -> Void {
                get {
                    return underlyingClosure
                }
                set(value) {
                    underlyingClosure = value
                }
            }
            var underlyingClosure: (() -> Void)!
            func setClosure(_ value: @escaping () -> Void ) {
                self.closure = value
            }

            // MARK: - optionalClosure

            var optionalClosure: ((String, Int) -> Bool)?
            func setOptionalClosure(_ value: ((String, Int) -> Bool)? ) {
                self.optionalClosure = value
            }

            // MARK: - forceUnwrappedClosure

            var forceUnwrappedClosure: ((Wrapper<Int>?, Wrapper<(String, Int)>?) -> Wrapper<() -> Void>)!
            func setForceUnwrappedClosure(_ value: ((Wrapper<Int>?, Wrapper<(String, Int)>?) -> Wrapper<() -> Void>)! ) {
                self.forceUnwrappedClosure = value
            }

            // MARK: - Default Empty Init

            init() {
            }

            // MARK: - Deinit

            func clearFunctionProperties() async {
                simpleMethodClosure = nil
                throwsMethodError = nil
                throwsMethodClosure = nil
                throwsReturningMethodError = nil
                throwsReturningMethodClosure = nil
                throwsReturningMethodReturnValue = nil
            }

            func clearVariableProperties() async {
                underlyingSimpleType = nil
                underlyingTuple = nil
                underlyingGeneric = nil
                underlyingClosure = nil
            }

            deinit {
                Task { [weak self] in
                    await self?.clearFunctionProperties()
                    await self?.clearVariableProperties()
                }
            }

            // MARK: - simpleMethod

            func simpleMethod() async {
                simpleMethodCallsCount += 1
                await simpleMethodClosure?()
            }
            var simpleMethodCallsCount = 0
            private var simpleMethodClosure: (() async -> Void)?

            func setSimpleMethodClosure(_ closure: @escaping (@Sendable () async -> Void)) {
                simpleMethodClosure = closure
            }

            // MARK: - throwsMethod

            func throwsMethod() async throws {
                throwsMethodCallsCount += 1
                if let throwsMethodError {
                    throw throwsMethodError
                }
                try await throwsMethodClosure?()
            }
            var throwsMethodCallsCount = 0
            private var throwsMethodError: Error?
            private var throwsMethodClosure: (() async throws -> Void)?

            func setThrowsMethodError(_ error: Error) {
                throwsMethodError = error
            }
            func setThrowsMethodClosure(_ closure: @escaping (@Sendable () async throws -> Void)) {
                throwsMethodClosure = closure
            }

            // MARK: - throwsReturningMethod

            func throwsReturningMethod() async throws -> Wrapper<Int>? {
                throwsReturningMethodCallsCount += 1
                if let throwsReturningMethodError {
                    throw throwsReturningMethodError
                }
                if let throwsReturningMethodClosure {
                    return try await throwsReturningMethodClosure()
                } else {
                    return throwsReturningMethodReturnValue
                }
            }
            var throwsReturningMethodCallsCount = 0
            private var throwsReturningMethodError: Error?
            private var throwsReturningMethodClosure: (() async throws -> Wrapper<Int>?)?
            private var throwsReturningMethodReturnValue: Wrapper<Int>?

            func setThrowsReturningMethodError(_ error: Error) {
                throwsReturningMethodError = error
            }
            func setThrowsReturningMethodClosure(_ closure: @escaping (@Sendable () async throws -> Wrapper<Int>?)) {
                throwsReturningMethodClosure = closure
            }
            func setThrowsReturningMethodReturnValue(_ returnValue: Wrapper<Int>?) {
                throwsReturningMethodReturnValue = returnValue
            }
        }
        """,
        macros: testMacros
        )
    }
    
    func testMockMacro_whenProtocolActorAndHasInit() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService: Actor {
            init(argument: String)
        }
        """,
        expandedSource:
        """
        protocol IService: Actor {
            init(argument: String)
        }
        
        actor IServiceMock: IService {
        
            // MARK: - Protocol Inits
        
            init(argument: String) {
                assertionFailure("Do not use this init. Use IServiceMock() instead. ")
            }
        
            // MARK: - Default Empty Init
        
            init() {
            }
        }
        """,
        macros: testMacros
        )
    }
    
    func testMockMacro_whenNotFinalMockHasInit() {
        assertMacroExpansion(
        """
        @Mock(heritability: .inheritable)
        protocol IService {
            init(argument: String)
        }
        """,
        expandedSource:
        """
        protocol IService {
            init(argument: String)
        }
        
        class IServiceMock: IService {
        
            // MARK: - Protocol Inits
        
            required init(argument: String) {
                assertionFailure("Do not use this init. Use IServiceMock() instead. ")
            }
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit
        
            func clearFunctionProperties() {
            }

            func clearVariableProperties() {
            }

            deinit {
                clearFunctionProperties()
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenProtocolHasEmptyInit() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            init(argument: String)
            init()
        }
        """,
        expandedSource:
        """
        protocol IService {
            init(argument: String)
            init()
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Protocol Inits
        
            init(argument: String) {
                assertionFailure("Do not use this init. Use IServiceMock() instead. ")
            }
        
            init() {
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenProtocolHasInit() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            init(argument: String)
        }
        """,
        expandedSource:
        """
        protocol IService {
            init(argument: String)
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Protocol Inits
        
            init(argument: String) {
                assertionFailure("Do not use this init. Use IServiceMock() instead. ")
            }
        
            // MARK: - Default Empty Init
        
            init() {
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenProtocolHasDelegateProperty() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            @Ignored var ignoredDelegate: IgnoredDelegate? { get set }
            var serviceDelegate: IServiceDelegate? { get set }
            var delegate: IServiceDelegate? { get set }
        }
        """,
        expandedSource:
        """
        protocol IService {
            @Ignored var ignoredDelegate: IgnoredDelegate? { get set }
            var serviceDelegate: IServiceDelegate? { get set }
            var delegate: IServiceDelegate? { get set }
        }
        
        final class IServiceMock: IService {
        
            // MARK: - ignoredDelegate
        
            var ignoredDelegate: IgnoredDelegate?
        
            // MARK: - serviceDelegate
        
            // Add the @Ignored macro to the delegate property `serviceDelegate` to avoid making the property weak.
            weak var serviceDelegate: IServiceDelegate?
        
            // MARK: - delegate
        
            // Add the @Ignored macro to the delegate property `delegate` to avoid making the property weak.
            weak var delegate: IServiceDelegate?
        
            // MARK: - Default Empty Init
        
            init() {
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenProtocolHasPropertyOrFuncWithAnyType() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            var object: any IProtocol { get set }
        
            func someMethod(argument: some IProtocol, anotherArgument: String)
            func anotherSomeMethod() -> any IProtocol
        }
        """,
        expandedSource:
        """
        protocol IService {
            var object: any IProtocol { get set }
        
            func someMethod(argument: some IProtocol, anotherArgument: String)
            func anotherSomeMethod() -> any IProtocol
        }
        
        final class IServiceMock: IService {

            // MARK: - object
        
            var object: any IProtocol {
                get {
                    return underlyingObject
                }
                set(value) {
                    underlyingObject = value
                }
            }
            var underlyingObject: (any IProtocol)!
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit
        
            func clearFunctionProperties() {
                someMethodArgumentAnotherArgumentReceivedArguments = []
                someMethodArgumentAnotherArgumentClosure = nil
                anotherSomeMethodClosure = nil
                anotherSomeMethodReturnValue = nil
            }
        
            func clearVariableProperties() {
                underlyingObject = nil
            }
        
            deinit {
                clearFunctionProperties()
                clearVariableProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - someMethod
        
            func someMethod(argument: some IProtocol, anotherArgument: String) {
                lock.performLockedAction {
                    someMethodArgumentAnotherArgumentCallsCount += 1
                    someMethodArgumentAnotherArgumentReceivedArguments.append((argument, anotherArgument))
                }
                someMethodArgumentAnotherArgumentClosure?(argument, anotherArgument)
            }
            var someMethodArgumentAnotherArgumentCallsCount = 0
            var someMethodArgumentAnotherArgumentReceivedArguments: [(IProtocol, String)] = []
            var someMethodArgumentAnotherArgumentClosure: ((IProtocol, String) -> Void)?
        
            // MARK: - anotherSomeMethod
        
            func anotherSomeMethod() -> any IProtocol {
                lock.performLockedAction {
                    anotherSomeMethodCallsCount += 1
                }
                if let anotherSomeMethodClosure {
                    return anotherSomeMethodClosure()
                } else {
                    return anotherSomeMethodReturnValue
                }
            }
            var anotherSomeMethodCallsCount = 0
            var anotherSomeMethodClosure: (() -> any IProtocol)?
            var anotherSomeMethodReturnValue: (any IProtocol)!
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenFuncReturnsNestedType() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            func download(url: URL) -> Downloadable.File
        }
        """,
        expandedSource:
        """
        protocol IService {
            func download(url: URL) -> Downloadable.File
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit
        
            func clearFunctionProperties() {
                downloadUrlReceivedArguments = []
                downloadUrlClosure = nil
                downloadUrlReturnValue = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - download
        
            func download(url: URL) -> Downloadable.File {
                lock.performLockedAction {
                    downloadUrlCallsCount += 1
                    downloadUrlReceivedArguments.append(url)
                }
                if let downloadUrlClosure {
                    return downloadUrlClosure(url)
                } else {
                    return downloadUrlReturnValue
                }
            }
            var downloadUrlCallsCount = 0
            var downloadUrlReceivedArguments: [URL] = []
            var downloadUrlClosure: ((URL) -> Downloadable.File)?
            var downloadUrlReturnValue: Downloadable.File!
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenPropertyHasMemberTypeSyntax() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            var nested: Outer.Inner { get set }
        }
        """,
        expandedSource:
        """
        protocol IService {
            var nested: Outer.Inner { get set }
        }
        
        final class IServiceMock: IService {
        
            // MARK: - nested
        
            var nested: Outer.Inner {
                get {
                    return underlyingNested
                }
                set(value) {
                    underlyingNested = value
                }
            }
            var underlyingNested: Outer.Inner!
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit
        
            func clearVariableProperties() {
                underlyingNested = nil
            }
        
            deinit {
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }
    
    func testMockMacro_underlyingVarClosure() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            var closure: () -> Void { get set }
        }
        """,
        expandedSource:
        """
        protocol IService {
            var closure: () -> Void { get set }
        }
        
        final class IServiceMock: IService {
        
            // MARK: - closure
        
            var closure: () -> Void {
                get {
                    return underlyingClosure
                }
                set(value) {
                    underlyingClosure = value
                }
            }
            var underlyingClosure: (() -> Void)!
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearVariableProperties() {
                underlyingClosure = nil
            }

            deinit {
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }
    
    func testMockMacro_whenPublicMockInheritsFromAnotherMock_thenThereIsNoInit() {
        assertMacroExpansion(
        """
        @Mock(.public)
        protocol IService: IParentService {
            func makeWork()
        }
        """,
        expandedSource:
        """
        protocol IService: IParentService {
            func makeWork()
        }
        
        public final class IServiceMock: IParentServiceMock, IService {
        
            // MARK: - Default Empty Init
        
            public override init() {
            }
        
            // MARK: - Deinit

            override public func clearFunctionProperties() {
                super.clearFunctionProperties()
                makeWorkClosure = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - makeWork
        
            public func makeWork() {
                lock.performLockedAction {
                    makeWorkCallsCount += 1
                }
                makeWorkClosure?()
            }
            public var makeWorkCallsCount = 0
            public var makeWorkClosure: (() -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_forceUnwrappedProperties() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService: AnyObject {
            var worker: String { get set }
            var generic: AnyPublisher<Void, Never> { get set }
            var array: [String] { get set }
            var genericArray: [AnyPublisher<String?, Never>] { get set }
            var tuple: (String?, Int) { get set }
        }
        """,
        expandedSource:
        """
        protocol IService: AnyObject {
            var worker: String { get set }
            var generic: AnyPublisher<Void, Never> { get set }
            var array: [String] { get set }
            var genericArray: [AnyPublisher<String?, Never>] { get set }
            var tuple: (String?, Int) { get set }
        }
        
        final class IServiceMock: IService {
        
            // MARK: - worker
        
            var worker: String {
                get {
                    return underlyingWorker
                }
                set(value) {
                    underlyingWorker = value
                }
            }
            var underlyingWorker: String! = String.arbitrary()
        
            // MARK: - generic
        
            var generic: AnyPublisher<Void, Never> {
                get {
                    return underlyingGeneric
                }
                set(value) {
                    underlyingGeneric = value
                }
            }
            var underlyingGeneric: AnyPublisher<Void, Never>!
        
            // MARK: - array
        
            var array: [String] {
                get {
                    return underlyingArray
                }
                set(value) {
                    underlyingArray = value
                }
            }
            var underlyingArray: [String]! = [String.arbitrary()]
        
            // MARK: - genericArray
        
            var genericArray: [AnyPublisher<String?, Never>] {
                get {
                    return underlyingGenericArray
                }
                set(value) {
                    underlyingGenericArray = value
                }
            }
            var underlyingGenericArray: [AnyPublisher<String?, Never>]!

            // MARK: - tuple
        
            var tuple: (String?, Int) {
                get {
                    return underlyingTuple
                }
                set(value) {
                    underlyingTuple = value
                }
            }
            var underlyingTuple: (String?, Int)!
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearVariableProperties() {
                underlyingWorker = nil
                underlyingGeneric = nil
                underlyingArray = nil
                underlyingGenericArray = nil
                underlyingTuple = nil
            }

            deinit {
                clearVariableProperties()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_whenSeveralArguments_closurePropertyWithoutEscapingKeyword() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            func download(path: String, completion: @escaping ([String]) -> Void)
        }
        """,
        expandedSource:
        """
        protocol IService {
            func download(path: String, completion: @escaping ([String]) -> Void)
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearFunctionProperties() {
                downloadPathCompletionReceivedArguments = []
                downloadPathCompletionClosure = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - download
        
            func download(path: String, completion: @escaping ([String]) -> Void) {
                lock.performLockedAction {
                    downloadPathCompletionCallsCount += 1
                    downloadPathCompletionReceivedArguments.append((path, completion))
                }
                downloadPathCompletionClosure?(path, completion)
            }
            var downloadPathCompletionCallsCount = 0
            var downloadPathCompletionReceivedArguments: [(String, ([String]) -> Void)] = []
            var downloadPathCompletionClosure: ((String, @escaping ([String]) -> Void) -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_closurePropertyWithoutEscapingKeyword() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            func download(completion: @escaping ([String]) -> Void)
        }
        """,
        expandedSource:
        """
        protocol IService {
            func download(completion: @escaping ([String]) -> Void)
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearFunctionProperties() {
                downloadCompletionReceivedArguments = []
                downloadCompletionClosure = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - download
        
            func download(completion: @escaping ([String]) -> Void) {
                lock.performLockedAction {
                    downloadCompletionCallsCount += 1
                    downloadCompletionReceivedArguments.append(completion)
                }
                downloadCompletionClosure?(completion)
            }
            var downloadCompletionCallsCount = 0
            var downloadCompletionReceivedArguments: [([String]) -> Void] = []
            var downloadCompletionClosure: ((@escaping ([String]) -> Void) -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_shouldBeInheritedFalse() {
        assertMacroExpansion(
        """
        @Mock(shouldBeInherited: false)
        protocol IService {
            func makeWork()
        }
        """,
        expandedSource:
        """
        protocol IService {
            func makeWork()
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearFunctionProperties() {
                makeWorkClosure = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - makeWork
        
            func makeWork() {
                lock.performLockedAction {
                    makeWorkCallsCount += 1
                }
                makeWorkClosure?()
            }
            var makeWorkCallsCount = 0
            var makeWorkClosure: (() -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_withHeritabilityParameter() {
        assertMacroExpansion(
        """
        @Mock(heritability: .inheritable)
        protocol IService {
            func makeWork()
        }
        """,
        expandedSource:
        """
        protocol IService {
            func makeWork()
        }
        
        class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearFunctionProperties() {
                makeWorkClosure = nil
            }
        
            func clearVariableProperties() {
            }

            deinit {
                clearFunctionProperties()
                clearVariableProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - makeWork
        
            func makeWork() {
                lock.performLockedAction {
                    makeWorkCallsCount += 1
                }
                makeWorkClosure?()
            }
            var makeWorkCallsCount = 0
            var makeWorkClosure: (() -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_withAccessModifierOpen_whenMockIsActor() {
        assertMacroExpansion(
        """
        @Mock(.open)
        protocol IService: Actor {
            var customValue: String? { get async }

            func makeWork() async
            func doWork() async throws -> Bool
        }
        """,
        expandedSource: """
        protocol IService: Actor {
            var customValue: String? { get async }

            func makeWork() async
            func doWork() async throws -> Bool
        }
        
        public actor IServiceMock: IService {
        
            // MARK: - customValue

            public var customValue: String?
            public func setCustomValue(_ value: String? ) {
                self.customValue = value
            }
        
            // MARK: - Default Empty Init
        
            public init() {
            }
        
            // MARK: - Deinit

            public func clearFunctionProperties() async {
                makeWorkClosure = nil
                doWorkError = nil
                doWorkClosure = nil
                doWorkReturnValue = nil
            }

            deinit {
                Task { [weak self] in
                    await self?.clearFunctionProperties()
                }
            }
        
            // MARK: - makeWork
        
            public func makeWork() async {
                makeWorkCallsCount += 1
                await makeWorkClosure?()
            }
            public var makeWorkCallsCount = 0
            private var makeWorkClosure: (() async -> Void)?
        
            public func setMakeWorkClosure(_ closure: @escaping (@Sendable () async -> Void)) {
                makeWorkClosure = closure
            }
        
            // MARK: - doWork
        
            public func doWork() async throws -> Bool {
                doWorkCallsCount += 1
                if let doWorkError {
                    throw doWorkError
                }
                if let doWorkClosure {
                    return try await doWorkClosure()
                } else {
                    return doWorkReturnValue
                }
            }
            public var doWorkCallsCount = 0
            private var doWorkError: Error?
            private var doWorkClosure: (() async throws -> Bool)?
            private var doWorkReturnValue: Bool!
        
            public func setDoWorkError(_ error: Error) {
                doWorkError = error
            }
            public func setDoWorkClosure(_ closure: @escaping (@Sendable () async throws -> Bool)) {
                doWorkClosure = closure
            }
            public func setDoWorkReturnValue(_ returnValue: Bool) {
                doWorkReturnValue = returnValue
            }
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_withAccessModifier() {
        assertMacroExpansion(
        """
        @Mock(.open)
        protocol IService: AnyObject {
            var customValue: String? { get set }

            func makeWork(first argument: String, secondArgument: String) -> String
        }
        """,
        expandedSource: """
        protocol IService: AnyObject {
            var customValue: String? { get set }

            func makeWork(first argument: String, secondArgument: String) -> String
        }
        
        open class IServiceMock: IService {
        
            // MARK: - customValue

            open var customValue: String?
        
            // MARK: - Default Empty Init
        
            public init() {
            }
        
            // MARK: - Deinit

            open func clearFunctionProperties() {
                makeWorkFirstArgumentSecondArgumentReceivedArguments = []
                makeWorkFirstArgumentSecondArgumentClosure = nil
                makeWorkFirstArgumentSecondArgumentReturnValue = nil
            }

            open func clearVariableProperties() {
            }

            deinit {
                clearFunctionProperties()
                clearVariableProperties()
            }
        
            private let lock = AtomicLock()

            // MARK: - makeWork
        
            open func makeWork(first argument: String, secondArgument: String) -> String {
                lock.performLockedAction {
                    makeWorkFirstArgumentSecondArgumentCallsCount += 1
                    makeWorkFirstArgumentSecondArgumentReceivedArguments.append((argument, secondArgument))
                }
                if let makeWorkFirstArgumentSecondArgumentClosure {
                    return makeWorkFirstArgumentSecondArgumentClosure(argument, secondArgument)
                } else {
                    return makeWorkFirstArgumentSecondArgumentReturnValue
                }
            }
            open var makeWorkFirstArgumentSecondArgumentCallsCount = 0
            open var makeWorkFirstArgumentSecondArgumentReceivedArguments: [(String, String)] = []
            open var makeWorkFirstArgumentSecondArgumentClosure: ((String, String) -> String)?
            open var makeWorkFirstArgumentSecondArgumentReturnValue: String!
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_withAssociatedType() {
        assertMacroExpansion(
        """
        @Mock(associatedTypes: ["Value": "String"])
        protocol IService: AnyObject {
            associatedtype Value
            
            var customValue: Value? { get set }
        }
        """,
        expandedSource: """
        protocol IService: AnyObject {
            associatedtype Value
            
            var customValue: Value? { get set }
        }
        
        final class IServiceMock: IService {
            // MARK: - Typealiases

            typealias Value = String

            // MARK: - customValue

            var customValue: Value?
        
            // MARK: - Default Empty Init
        
            init() {
            }
        }
        """,
        macros: testMacros
        )
    }
    
    func testMockMacro_withReceivedArgumentsProperty() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService: AnyObject {
            func download()
            func download(file: URL)
            func download(file: URL, path: String)
            func download(file: URL, date: Date?)
            func download(fileAndPath: (URL, String))
            func upload(fileAndPath: (URL, String)?)
        }
        """,
        expandedSource:
        """
        protocol IService: AnyObject {
            func download()
            func download(file: URL)
            func download(file: URL, path: String)
            func download(file: URL, date: Date?)
            func download(fileAndPath: (URL, String))
            func upload(fileAndPath: (URL, String)?)
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearFunctionProperties() {
                downloadClosure = nil
                downloadFileReceivedArguments = []
                downloadFileClosure = nil
                downloadFilePathReceivedArguments = []
                downloadFilePathClosure = nil
                downloadFileDateReceivedArguments = []
                downloadFileDateClosure = nil
                downloadFileAndPathReceivedArguments = []
                downloadFileAndPathClosure = nil
                uploadFileAndPathReceivedArguments = []
                uploadFileAndPathClosure = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - download
        
            func download() {
                lock.performLockedAction {
                    downloadCallsCount += 1
                }
                downloadClosure?()
            }
            var downloadCallsCount = 0
            var downloadClosure: (() -> Void)?
        
            // MARK: - download
        
            func download(file: URL) {
                lock.performLockedAction {
                    downloadFileCallsCount += 1
                    downloadFileReceivedArguments.append(file)
                }
                downloadFileClosure?(file)
            }
            var downloadFileCallsCount = 0
            var downloadFileReceivedArguments: [URL] = []
            var downloadFileClosure: ((URL) -> Void)?
        
            // MARK: - download
        
            func download(file: URL, path: String) {
                lock.performLockedAction {
                    downloadFilePathCallsCount += 1
                    downloadFilePathReceivedArguments.append((file, path))
                }
                downloadFilePathClosure?(file, path)
            }
            var downloadFilePathCallsCount = 0
            var downloadFilePathReceivedArguments: [(URL, String)] = []
            var downloadFilePathClosure: ((URL, String) -> Void)?
        
            // MARK: - download
        
            func download(file: URL, date: Date?) {
                lock.performLockedAction {
                    downloadFileDateCallsCount += 1
                    downloadFileDateReceivedArguments.append((file, date))
                }
                downloadFileDateClosure?(file, date)
            }
            var downloadFileDateCallsCount = 0
            var downloadFileDateReceivedArguments: [(URL, Date?)] = []
            var downloadFileDateClosure: ((URL, Date?) -> Void)?
        
            // MARK: - download
        
            func download(fileAndPath: (URL, String)) {
                lock.performLockedAction {
                    downloadFileAndPathCallsCount += 1
                    downloadFileAndPathReceivedArguments.append(fileAndPath)
                }
                downloadFileAndPathClosure?(fileAndPath)
            }
            var downloadFileAndPathCallsCount = 0
            var downloadFileAndPathReceivedArguments: [(URL, String)] = []
            var downloadFileAndPathClosure: (((URL, String)) -> Void)?
        
            // MARK: - upload
        
            func upload(fileAndPath: (URL, String)?) {
                lock.performLockedAction {
                    uploadFileAndPathCallsCount += 1
                    uploadFileAndPathReceivedArguments.append(fileAndPath)
                }
                uploadFileAndPathClosure?(fileAndPath)
            }
            var uploadFileAndPathCallsCount = 0
            var uploadFileAndPathReceivedArguments: [(URL, String)?] = []
            var uploadFileAndPathClosure: (((URL, String)?) -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_argumentTuple() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            func funcWithTuple(arg: (String, Int))
        }
        """,
        expandedSource:
        """
        protocol IService {
            func funcWithTuple(arg: (String, Int))
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearFunctionProperties() {
                funcWithTupleArgReceivedArguments = []
                funcWithTupleArgClosure = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - funcWithTuple
        
            func funcWithTuple(arg: (String, Int)) {
                lock.performLockedAction {
                    funcWithTupleArgCallsCount += 1
                    funcWithTupleArgReceivedArguments.append(arg)
                }
                funcWithTupleArgClosure?(arg)
            }
            var funcWithTupleArgCallsCount = 0
            var funcWithTupleArgReceivedArguments: [(String, Int)] = []
            var funcWithTupleArgClosure: (((String, Int)) -> Void)?
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_returnValueTuple() {
        assertMacroExpansion(
        """
        @Mock
        protocol IService {
            func funcWithTuple() -> (String, Int)
        }
        """,
        expandedSource:
        """
        protocol IService {
            func funcWithTuple() -> (String, Int)
        }
        
        final class IServiceMock: IService {
        
            // MARK: - Default Empty Init
        
            init() {
            }
        
            // MARK: - Deinit

            func clearFunctionProperties() {
                funcWithTupleClosure = nil
                funcWithTupleReturnValue = nil
            }

            deinit {
                clearFunctionProperties()
            }
        
            private let lock = AtomicLock()
        
            // MARK: - funcWithTuple
        
            func funcWithTuple() -> (String, Int) {
                lock.performLockedAction {
                    funcWithTupleCallsCount += 1
                }
                if let funcWithTupleClosure {
                    return funcWithTupleClosure()
                } else {
                    return funcWithTupleReturnValue
                }
            }
            var funcWithTupleCallsCount = 0
            var funcWithTupleClosure: (() -> (String, Int))?
            var funcWithTupleReturnValue: (String, Int)!
        }
        """,
        macros: testMacros
        )
    }

    func testMockMacro_protocolConformingActor() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: Actor {
                var name: String { get async }
            
                func doWork() async
            }
            """,
            expandedSource:
            """
            protocol IService: Actor {
                var name: String { get async }
            
                func doWork() async
            }
            
            actor IServiceMock: IService {
            
                // MARK: - name
            
                var name: String {
                    get {
                        return underlyingName
                    }
                    set(value) {
                        underlyingName = value
                    }
                }
                var underlyingName: String! = String.arbitrary()
                func setName(_ value: String ) {
                    self.name = value
                }
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() async {
                    doWorkClosure = nil
                }

                func clearVariableProperties() async {
                    underlyingName = nil
                }

                deinit {
                    Task { [weak self] in
                        await self?.clearFunctionProperties()
                        await self?.clearVariableProperties()
                    }
                }
            
                // MARK: - doWork
            
                func doWork() async {
                    doWorkCallsCount += 1
                    await doWorkClosure?()
                }
                var doWorkCallsCount = 0
                private var doWorkClosure: (() async -> Void)?

                func setDoWorkClosure(_ closure: @escaping (@Sendable () async -> Void)) {
                    doWorkClosure = closure
                }
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_protocolWithAssociatedType() {
        assertMacroExpansion(
            """
            @Mock(associatedTypes: ["Input": "String", "Output": "Int"])
            protocol IService: AnyObject {
                associatedtype Input
                associatedtype Output
            
                func doWork(input: Input) -> Output
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                associatedtype Input
                associatedtype Output
            
                func doWork(input: Input) -> Output
            }
            
            final class IServiceMock: IService {
                // MARK: - Typealiases
            
                typealias Input = String
                typealias Output = Int
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkInputReceivedArguments = []
                    doWorkInputClosure = nil
                    doWorkInputReturnValue = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork(input: Input) -> Output {
                    lock.performLockedAction {
                        doWorkInputCallsCount += 1
                        doWorkInputReceivedArguments.append(input)
                    }
                    if let doWorkInputClosure {
                        return doWorkInputClosure(input)
                    } else {
                        return doWorkInputReturnValue
                    }
                }
                var doWorkInputCallsCount = 0
                var doWorkInputReceivedArguments: [Input] = []
                var doWorkInputClosure: ((Input) -> Output)?
                var doWorkInputReturnValue: Output!
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_asyncThrowsFunc() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWork() async throws -> String
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                func doWork() async throws -> String
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkError = nil
                    doWorkClosure = nil
                    doWorkReturnValue = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork() async throws -> String {
                    doWorkCallsCount += 1
                    if let doWorkError {
                        throw doWorkError
                    }
                    if let doWorkClosure {
                        return try await doWorkClosure()
                    } else {
                        return doWorkReturnValue
                    }
                }
                var doWorkCallsCount = 0
                var doWorkError: Error?
                var doWorkClosure: (() async throws -> String)?
                var doWorkReturnValue: String!
            }
            """,
            macros: testMacros
        )
    }
    func testMockMacro_throwsFunc() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWork() throws
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                func doWork() throws
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkError = nil
                    doWorkClosure = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork() throws {
                    lock.performLockedAction {
                        doWorkCallsCount += 1
                    }
                    if let doWorkError {
                        throw doWorkError
                    }
                    try doWorkClosure?()
                }
                var doWorkCallsCount = 0
                var doWorkError: Error?
                var doWorkClosure: (() throws -> Void)?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_asyncFunc() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWork() async
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                func doWork() async
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkClosure = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork() async {
                    doWorkCallsCount += 1
                    await doWorkClosure?()
                }
                var doWorkCallsCount = 0
                var doWorkClosure: (() async -> Void)?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_funcWithOptionalParameter() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService {
                func doWork(arg: String?)
            }
            """,
            expandedSource:
            """
            protocol IService {
                func doWork(arg: String?)
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkArgReceivedArguments = []
                    doWorkArgClosure = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork(arg: String?) {
                    lock.performLockedAction {
                        doWorkArgCallsCount += 1
                        doWorkArgReceivedArguments.append(arg)
                    }
                    doWorkArgClosure?(arg)
                }
                var doWorkArgCallsCount = 0
                var doWorkArgReceivedArguments: [String?] = []
                var doWorkArgClosure: ((String?) -> Void)?
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_funcWithOptionalReturnValue() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService {
                func doWork() -> String?
            }
            """,
            expandedSource:
            """
            protocol IService {
                func doWork() -> String?
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkClosure = nil
                    doWorkReturnValue = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork() -> String? {
                    lock.performLockedAction {
                        doWorkCallsCount += 1
                    }
                    if let doWorkClosure {
                        return doWorkClosure()
                    } else {
                        return doWorkReturnValue
                    }
                }
                var doWorkCallsCount = 0
                var doWorkClosure: (() -> String?)?
                var doWorkReturnValue: String?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_variablesWithFunctions() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService {
                var worker: String { get set }
                var optionalWorker: String? { get set }
                var forceUnwrappedWorker: String! { get set }
            
                func doWork()
                func doWorkWithArgs(string: String, arg2: Bool)
                func doWorkWithReturnValue() -> String
                func doWorkWithArgsAndReturnValue(string: String) -> [String: String]
            }
            """,
            expandedSource:
            """
            protocol IService {
                var worker: String { get set }
                var optionalWorker: String? { get set }
                var forceUnwrappedWorker: String! { get set }
            
                func doWork()
                func doWorkWithArgs(string: String, arg2: Bool)
                func doWorkWithReturnValue() -> String
                func doWorkWithArgsAndReturnValue(string: String) -> [String: String]
            }
            
            final class IServiceMock: IService {
            
                // MARK: - worker
            
                var worker: String {
                    get {
                        return underlyingWorker
                    }
                    set(value) {
                        underlyingWorker = value
                    }
                }
                var underlyingWorker: String! = String.arbitrary()
            
                // MARK: - optionalWorker
            
                var optionalWorker: String?
            
                // MARK: - forceUnwrappedWorker
            
                var forceUnwrappedWorker: String!
            
                // MARK: - Default Empty Init
            
                init() {
                }

                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkClosure = nil
                    doWorkWithArgsStringArg2ReceivedArguments = []
                    doWorkWithArgsStringArg2Closure = nil
                    doWorkWithReturnValueClosure = nil
                    doWorkWithReturnValueReturnValue = nil
                    doWorkWithArgsAndReturnValueStringReceivedArguments = []
                    doWorkWithArgsAndReturnValueStringClosure = nil
                    doWorkWithArgsAndReturnValueStringReturnValue = nil
                }

                func clearVariableProperties() {
                    underlyingWorker = nil
                }

                deinit {
                    clearFunctionProperties()
                    clearVariableProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork() {
                    lock.performLockedAction {
                        doWorkCallsCount += 1
                    }
                    doWorkClosure?()
                }
                var doWorkCallsCount = 0
                var doWorkClosure: (() -> Void)?
            
                // MARK: - doWorkWithArgs
            
                func doWorkWithArgs(string: String, arg2: Bool) {
                    lock.performLockedAction {
                        doWorkWithArgsStringArg2CallsCount += 1
                        doWorkWithArgsStringArg2ReceivedArguments.append((string, arg2))
                    }
                    doWorkWithArgsStringArg2Closure?(string, arg2)
                }
                var doWorkWithArgsStringArg2CallsCount = 0
                var doWorkWithArgsStringArg2ReceivedArguments: [(String, Bool)] = []
                var doWorkWithArgsStringArg2Closure: ((String, Bool) -> Void)?
            
                // MARK: - doWorkWithReturnValue
            
                func doWorkWithReturnValue() -> String {
                    lock.performLockedAction {
                        doWorkWithReturnValueCallsCount += 1
                    }
                    if let doWorkWithReturnValueClosure {
                        return doWorkWithReturnValueClosure()
                    } else {
                        return doWorkWithReturnValueReturnValue
                    }
                }
                var doWorkWithReturnValueCallsCount = 0
                var doWorkWithReturnValueClosure: (() -> String)?
                var doWorkWithReturnValueReturnValue: String!
            
                // MARK: - doWorkWithArgsAndReturnValue
            
                func doWorkWithArgsAndReturnValue(string: String) -> [String: String] {
                    lock.performLockedAction {
                        doWorkWithArgsAndReturnValueStringCallsCount += 1
                        doWorkWithArgsAndReturnValueStringReceivedArguments.append(string)
                    }
                    if let doWorkWithArgsAndReturnValueStringClosure {
                        return doWorkWithArgsAndReturnValueStringClosure(string)
                    } else {
                        return doWorkWithArgsAndReturnValueStringReturnValue
                    }
                }
                var doWorkWithArgsAndReturnValueStringCallsCount = 0
                var doWorkWithArgsAndReturnValueStringReceivedArguments: [String] = []
                var doWorkWithArgsAndReturnValueStringClosure: ((String) -> [String: String])?
                var doWorkWithArgsAndReturnValueStringReturnValue: [String: String]!
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_property() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                var worker: String { get set }
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                var worker: String { get set }
            }
            
            final class IServiceMock: IService {
            
                // MARK: - worker
            
                var worker: String {
                    get {
                        return underlyingWorker
                    }
                    set(value) {
                        underlyingWorker = value
                    }
                }
                var underlyingWorker: String! = String.arbitrary()
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearVariableProperties() {
                    underlyingWorker = nil
                }

                deinit {
                    clearVariableProperties()
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_optionalProperty() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                var worker: String? { get set }
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                var worker: String? { get set }
            }
            
            final class IServiceMock: IService {
            
                // MARK: - worker
            
                var worker: String?
            
                // MARK: - Default Empty Init
            
                init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_implicitlyUnwrappedOptionalProperty() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                var worker: String! { get set }
            }
            """,
            expandedSource:
            """
            protocol IService: AnyObject {
                var worker: String! { get set }
            }
            
            final class IServiceMock: IService {
            
                // MARK: - worker
            
                var worker: String!
            
                // MARK: - Default Empty Init
            
                init() {
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_function() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWork()
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWork()
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkClosure = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWork
            
                func doWork() {
                    lock.performLockedAction {
                        doWorkCallsCount += 1
                    }
                    doWorkClosure?()
                }
                var doWorkCallsCount = 0
                var doWorkClosure: (() -> Void)?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_functionWithArgs() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWorkWithArgs(string: String, arg2: Bool)
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWorkWithArgs(string: String, arg2: Bool)
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkWithArgsStringArg2ReceivedArguments = []
                    doWorkWithArgsStringArg2Closure = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWorkWithArgs
            
                func doWorkWithArgs(string: String, arg2: Bool) {
                    lock.performLockedAction {
                        doWorkWithArgsStringArg2CallsCount += 1
                        doWorkWithArgsStringArg2ReceivedArguments.append((string, arg2))
                    }
                    doWorkWithArgsStringArg2Closure?(string, arg2)
                }
                var doWorkWithArgsStringArg2CallsCount = 0
                var doWorkWithArgsStringArg2ReceivedArguments: [(String, Bool)] = []
                var doWorkWithArgsStringArg2Closure: ((String, Bool) -> Void)?
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_functionWithReturnValue() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWorkWithReturnValue() -> String
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWorkWithReturnValue() -> String
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    doWorkWithReturnValueClosure = nil
                    doWorkWithReturnValueReturnValue = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWorkWithReturnValue
            
                func doWorkWithReturnValue() -> String {
                    lock.performLockedAction {
                        doWorkWithReturnValueCallsCount += 1
                    }
                    if let doWorkWithReturnValueClosure {
                        return doWorkWithReturnValueClosure()
                    } else {
                        return doWorkWithReturnValueReturnValue
                    }
                }
                var doWorkWithReturnValueCallsCount = 0
                var doWorkWithReturnValueClosure: (() -> String)?
                var doWorkWithReturnValueReturnValue: String!
            }
            """,
            macros: testMacros
        )
    }
    
    func testMockMacro_functionWithArgsAndReturnValue() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: AnyObject {
                func doWorkWithArgsAndReturnValue(string: String) -> String
            }
            """,
            expandedSource: """
            protocol IService: AnyObject {
                func doWorkWithArgsAndReturnValue(string: String) -> String
            }
            
            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init
            
                init() {
                }
            
                // MARK: - Deinit
            
                func clearFunctionProperties() {
                    doWorkWithArgsAndReturnValueStringReceivedArguments = []
                    doWorkWithArgsAndReturnValueStringClosure = nil
                    doWorkWithArgsAndReturnValueStringReturnValue = nil
                }

                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - doWorkWithArgsAndReturnValue
            
                func doWorkWithArgsAndReturnValue(string: String) -> String {
                    lock.performLockedAction {
                        doWorkWithArgsAndReturnValueStringCallsCount += 1
                        doWorkWithArgsAndReturnValueStringReceivedArguments.append(string)
                    }
                    if let doWorkWithArgsAndReturnValueStringClosure {
                        return doWorkWithArgsAndReturnValueStringClosure(string)
                    } else {
                        return doWorkWithArgsAndReturnValueStringReturnValue
                    }
                }
                var doWorkWithArgsAndReturnValueStringCallsCount = 0
                var doWorkWithArgsAndReturnValueStringReceivedArguments: [String] = []
                var doWorkWithArgsAndReturnValueStringClosure: ((String) -> String)?
                var doWorkWithArgsAndReturnValueStringReturnValue: String!
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_whenAppliedNotToProtocol() {
        assertMacroExpansion(
            """
            @Mock
            class Service: IService {
                func doWork() {}
            }
            """,
            expandedSource: """
            class Service: IService {
                func doWork() {}
            }
            """,
            diagnostics: [.init(message: "@Mock should only be used with protocols", line: 1, column: 1)],
            macros: testMacros
        )
    }

    func testMockMacro_whenProtocolInheritesSendable() {
        assertMacroExpansion(
            """
            @Mock
            protocol IService: Sendable {
                func makeWork()
            }
            """,
            expandedSource: """
            protocol IService: Sendable {
                func makeWork()
            }

            final class IServiceMock: IService, @unchecked Sendable {
            
                // MARK: - Default Empty Init

                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    makeWorkClosure = nil
                }
            
                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - makeWork
            
                func makeWork() {
                    lock.performLockedAction {
                        makeWorkCallsCount += 1
                    }
                    makeWorkClosure?()
                }
                var makeWorkCallsCount = 0
                var makeWorkClosure: (() -> Void)?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_whenMockShouldBeImplicitSendable() {
        assertMacroExpansion(
            """
            @Mock(sendableMode: .enabled)
            protocol IService {
                func makeWork()
            }
            """,
            expandedSource: """
            protocol IService {
                func makeWork()
            }

            final class IServiceMock: IService, @unchecked Sendable {
            
                // MARK: - Default Empty Init

                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    makeWorkClosure = nil
                }
            
                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - makeWork
            
                func makeWork() {
                    lock.performLockedAction {
                        makeWorkCallsCount += 1
                    }
                    makeWorkClosure?()
                }
                var makeWorkCallsCount = 0
                var makeWorkClosure: (() -> Void)?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_whenMockShouldNotBeSendable() {
        assertMacroExpansion(
            """
            @Mock(sendableMode: .disabled)
            protocol IService: Sendable {
                func makeWork()
            }
            """,
            expandedSource: """
            protocol IService: Sendable {
                func makeWork()
            }

            final class IServiceMock: IService {
            
                // MARK: - Default Empty Init

                init() {
                }
            
                // MARK: - Deinit

                func clearFunctionProperties() {
                    makeWorkClosure = nil
                }
            
                deinit {
                    clearFunctionProperties()
                }
            
                private let lock = AtomicLock()
            
                // MARK: - makeWork
            
                func makeWork() {
                    lock.performLockedAction {
                        makeWorkCallsCount += 1
                    }
                    makeWorkClosure?()
                }
                var makeWorkCallsCount = 0
                var makeWorkClosure: (() -> Void)?
            }
            """,
            macros: testMacros
        )
    }

    func testMockMacro_whenMockIsActor_thenMacroDoesntGenerateSendable() {
        assertMacroExpansion(
            """
            @Mock(sendableMode: .auto)
            protocol IService: Actor, Sendable {
                func makeWork() async
            }
            """,
            expandedSource: """
            protocol IService: Actor, Sendable {
                func makeWork() async
            }

            actor IServiceMock: IService {

                // MARK: - Default Empty Init

                init() {
                }

                // MARK: - Deinit

                func clearFunctionProperties() async {
                    makeWorkClosure = nil
                }

                deinit {
                    Task { [weak self] in
                        await self?.clearFunctionProperties()
                    }
                }

                // MARK: - makeWork

                func makeWork() async {
                    makeWorkCallsCount += 1
                    await makeWorkClosure?()
                }
                var makeWorkCallsCount = 0
                private var makeWorkClosure: (() async -> Void)?

                func setMakeWorkClosure(_ closure: @escaping (@Sendable () async -> Void)) {
                    makeWorkClosure = closure
                }
            }
            """,
            macros: testMacros
        )
    }
}
