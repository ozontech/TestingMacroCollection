//
//  AnyMockableMacroTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class AnyMockableMacroTests: XCTestCase {
    func testAnyMockable_withGenericInGenericClause() {
        assertMacroExpansion(
        """
        @AnyMockable
        class Service: IService {
            func download<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {}
        }
        """,
        expandedSource:
        """
        class Service: IService {
            func download<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {
                mock.download(completion: completion)
            }

            internal let mock = Mock()

            internal final class Mock: @unchecked Sendable {

                private let lock = AtomicLock()

                // MARK: - download

                fileprivate func download<T: Decodable>(completion: @escaping (Result<T, Error>) -> Void) {
                    lock.performLockedAction {
                        downloadCompletionCallsCount += 1
                        downloadCompletionReceivedArguments.append(completion as! (Result<Any, Error>) -> Void)
                    }
                    downloadCompletionClosure?(completion as! (Result<Any, Error>) -> Void)
                }
                var downloadCompletionCallsCount = 0
                var downloadCompletionReceivedArguments: [(Result<Any, Error>) -> Void] = []
                var downloadCompletionClosure: ((@escaping (Result<Any, Error>) -> Void) -> Void)?
            }
        }

        extension Service: ProxyableMock {
        }
        """,
        macros: testMacros
        )
    }

    func testAnyMockable_withTypedErrorActor() {
        assertMacroExpansion(
        """
        @AnyMockable
        actor ActorWithMethodThatThrowsBadError: ProtocolWithMethodThatThrowsBadError {
            func throwBadError() async throws(BadError)
        } 
        """,
        expandedSource:
        """
        actor ActorWithMethodThatThrowsBadError: ProtocolWithMethodThatThrowsBadError {
            func throwBadError() async throws(BadError) {
                try await mock.throwBadError()
            }

            internal let mock = Mock()

            internal final class Mock: @unchecked Sendable {

                private let lock = AtomicLock()

                // MARK: - throwBadError

                fileprivate func throwBadError() async throws(BadError) {
                    throwBadErrorCallsCount += 1
                    if let throwBadErrorError {
                        throw throwBadErrorError
                    }
                    try await throwBadErrorClosure?()
                }
                var throwBadErrorCallsCount = 0
                var throwBadErrorError: BadError?
                var throwBadErrorClosure: (() async throws(BadError) -> Void)?
            }
        } 

        extension ActorWithMethodThatThrowsBadError: ProxyableMock {
        }
        """,
        macros: testMacros
        )
    }

    func testAnyMockable_withTypedError() {
        assertMacroExpansion(
        """
        @AnyMockable
        class ClassWithMethodThatThrowsBadError: ProtocolWithMethodThatThrowsBadError {
            func throwBadError() throws(BadError)
        }
        """,
        expandedSource:
        """
        class ClassWithMethodThatThrowsBadError: ProtocolWithMethodThatThrowsBadError {
            func throwBadError() throws(BadError) {
                try mock.throwBadError()
            }

            internal let mock = Mock()

            internal final class Mock: @unchecked Sendable {

                private let lock = AtomicLock()

                // MARK: - throwBadError

                fileprivate func throwBadError() throws(BadError) {
                    lock.performLockedAction {
                        throwBadErrorCallsCount += 1
                    }
                    if let throwBadErrorError {
                        throw throwBadErrorError
                    }
                    try throwBadErrorClosure?()
                }
                var throwBadErrorCallsCount = 0
                var throwBadErrorError: BadError?
                var throwBadErrorClosure: (() throws(BadError) -> Void)?
            }
        }

        extension ClassWithMethodThatThrowsBadError: ProxyableMock {
        }
        """,
        macros: testMacros
        )
    }

    func testAnyMockable_withEqualSignatures() {
        assertMacroExpansion(
        """
        @AnyMockable
        class MethodOverloadingAnyMockable: MethodOverloading {
            func job<T>(arg: T) {}
            func job<T>(arg: T?) {}
            
            func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate) {}
            func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService) {}
            func jobOne(_ arg1: [String : Int], _ arg2: (Bool, Int), _ arg3: @escaping () -> Void) {}
        }
        """,
        expandedSource:
        """
        class MethodOverloadingAnyMockable: MethodOverloading {
            func job<T>(arg: T) {
                mock.job(arg: arg)
            }
            func job<T>(arg: T?) {
                mock.job(arg: arg)
            }
            
            func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate) {
                mock.jobOne(arg1, arg2, arg3)
            }
            func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService) {
                mock.jobOne(arg1, arg2, arg3)
            }
            func jobOne(_ arg1: [String : Int], _ arg2: (Bool, Int), _ arg3: @escaping () -> Void) {
                mock.jobOne(arg1, arg2, arg3)
            }
        
            internal let mock = Mock()
        
            internal final class Mock: @unchecked Sendable {

                private let lock = AtomicLock()

                // MARK: - job

                fileprivate func job<T>(arg: T) {
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

                fileprivate func job<T>(arg: T?) {
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

                fileprivate func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate) {
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

                fileprivate func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService) {
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

                fileprivate func jobOne(_ arg1: [String : Int], _ arg2: (Bool, Int), _ arg3: @escaping () -> Void) {
                    lock.performLockedAction {
                        jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionCallsCount += 1
                        jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionReceivedArguments.append((arg1, arg2, arg3))
                    }
                    jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionClosure?(arg1, arg2, arg3)
                }
                var jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionCallsCount = 0
                var jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionReceivedArguments: [([String : Int], (Bool, Int), () -> Void)] = []
                var jobOneArg1DictStringIntArg2TupleArg3AttributedFunctionClosure: (([String : Int], (Bool, Int), @escaping () -> Void) -> Void)?
            }
        }
        
        extension MethodOverloadingAnyMockable: ProxyableMock {
        }
        """,
        macros: testMacros
        )
    }

    func testAnyMockable_withGenerics() {
        assertMacroExpansion(
        """
        @AnyMockable
        class AnyMockableWithGeneric: Generic {
            func test_closure<T, E>(closure: @escaping (T, E) -> E) {
                mock.test_closure(closure: closure)
            }
            
            func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T] {
                mock.test_closure_with_return_value(closure: closure)
            }
            
            func test_simple<T>(value: T) -> T {
                mock.test_simple(value: value)
            }
            
            func test_complex<T, E>(value: [T], argument: (T, E)) -> [String : E] {
                mock.test_complex(value: value, argument: argument)
            }
        }
        """,
        expandedSource:
        """
        class AnyMockableWithGeneric: Generic {
            func test_closure<T, E>(closure: @escaping (T, E) -> E) {
                mock.test_closure(closure: closure)
            }
            
            func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T] {
                mock.test_closure_with_return_value(closure: closure)
            }
            
            func test_simple<T>(value: T) -> T {
                mock.test_simple(value: value)
            }
            
            func test_complex<T, E>(value: [T], argument: (T, E)) -> [String : E] {
                mock.test_complex(value: value, argument: argument)
            }
        
            internal let mock = Mock()

            internal final class Mock: @unchecked Sendable {

                private let lock = AtomicLock()

                // MARK: - test_closure

                fileprivate func test_closure<T, E>(closure: @escaping (T, E) -> E) {
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

                fileprivate func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T] {
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
                var test_closure_with_return_valueClosureClosure: ((@escaping (Any, Any) -> Any) -> [Any] )?
                var test_closure_with_return_valueClosureReturnValue: [Any]!

                // MARK: - test_simple

                fileprivate func test_simple<T>(value: T) -> T {
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

                fileprivate func test_complex<T, E>(value: [T], argument: (T, E)) -> [String : E] {
                    lock.performLockedAction {
                        test_complexValueArgumentCallsCount += 1
                        test_complexValueArgumentReceivedArguments.append((value, argument))
                    }
                    if let test_complexValueArgumentClosure {
                        return test_complexValueArgumentClosure(value, argument) as! [String : E]
                    } else {
                        return test_complexValueArgumentReturnValue as! [String : E]
                    }
                }
                var test_complexValueArgumentCallsCount = 0
                var test_complexValueArgumentReceivedArguments: [([Any], (Any, Any))] = []
                var test_complexValueArgumentClosure: (([Any], (Any, Any)) -> [String : Any] )?
                var test_complexValueArgumentReturnValue: [String : Any]!
            }
        }
        
        extension AnyMockableWithGeneric: ProxyableMock {
        }
        """,
        macros: testMacros
        )
    }

    func testAnyMockable_createMock() {
        assertMacroExpansion(
        """
        @AnyMockable
        final class ServiceMock: IService {
            var path: String
        
            var optionalProperty: String?
        
            func makeWork(arg1: String) -> String {
                mock.makeWork(arg1: arg1)
            }
        }
        """,
        expandedSource:
        """
        final class ServiceMock: IService {
            var path: String {
                get {
                    mock.underlyingPath
                }
                set(newValue) {
                    mock.underlyingPath = newValue
                }
            }
        
            var optionalProperty: String?
        
            func makeWork(arg1: String) -> String {
                mock.makeWork(arg1: arg1)
            }
        
            internal let mock = Mock()
        
            internal final class Mock: @unchecked Sendable {
                var underlyingPath: String! = String.arbitrary()
        
                private let lock = AtomicLock()
        
                // MARK: - makeWork
        
                fileprivate func makeWork(arg1: String) -> String {
                    lock.performLockedAction {
                        makeWorkArg1CallsCount += 1
                        makeWorkArg1ReceivedArguments.append(arg1)
                    }
                    if let makeWorkArg1Closure {
                        return makeWorkArg1Closure(arg1)
                    } else {
                        return makeWorkArg1ReturnValue
                    }
                }
                var makeWorkArg1CallsCount = 0
                var makeWorkArg1ReceivedArguments: [String] = []
                var makeWorkArg1Closure: ((String) -> String )?
                var makeWorkArg1ReturnValue: String!
            }
        }
        
        extension ServiceMock: ProxyableMock {
        }
        """,
        macros: testMacros
        )
    }
}
