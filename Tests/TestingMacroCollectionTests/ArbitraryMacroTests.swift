//
//  ArbitraryMacroTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class ArbitraryMacroTests: XCTestCase {
    func testArbotraru_whenPropertyIsNilable() {
        assertMacroExpansion(
        """
        @Arbitrary(.dynamic)
        class ClassModel {
            @Nilable let optionalType: CustomType?
            @Nilable var forceUnwrappedType: CustomType!
        }
        """,
        expandedSource:
        """
        class ClassModel {
            @Nilable let optionalType: CustomType?
            @Nilable var forceUnwrappedType: CustomType!
        
            init(optionalType: CustomType?, forceUnwrappedType: CustomType!) {
                self.optionalType = optionalType
                self.forceUnwrappedType = forceUnwrappedType
            }
        }
        
        enum ClassModelArbitrary {
            static func arbitrary(optionalType: CustomType? = nil, forceUnwrappedType: CustomType! = nil) -> ClassModel {
                ClassModel (optionalType: optionalType, forceUnwrappedType: forceUnwrappedType)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenDeclHasNestedDecls() {
        assertMacroExpansion(
        """
        class One {
            @Arbitrary
            class Two {}
        }
        
        @Arbitrary
        class Outer {
            @Arbitrary
            actor InnerActor { }
            
            let innerActor: InnerActor
        
            @Arbitrary
            class InnerClass { }
        
            let innerClass: InnerClass
        
            @Arbitrary
            struct InnerStruct { }
        
            let innerStruct: InnerStruct
        
            let onetwo: One.Two
            let onetwoOptional: One.Two?
            let onetwoUnwrapped: One.Two!
        
            let innerClassOptional: InnerClass?
            let innerClassUnwrapped: InnerClass!
        }
        """,
        expandedSource:
        """
        class One {
            class Two {}
        
            enum TwoArbitrary {
                static func arbitrary() -> Two {
                    Two ()
                }
            }
        }
        class Outer {
            actor InnerActor { }

            enum InnerActorArbitrary {
                static func arbitrary() -> InnerActor {
                    InnerActor ()
                }
            }
            
            let innerActor: InnerActor
            class InnerClass { }

            enum InnerClassArbitrary {
                static func arbitrary() -> InnerClass {
                    InnerClass ()
                }
            }
        
            let innerClass: InnerClass
            struct InnerStruct { }

            enum InnerStructArbitrary {
                static func arbitrary() -> InnerStruct {
                    InnerStruct ()
                }
            }
        
            let innerStruct: InnerStruct
        
            let onetwo: One.Two
            let onetwoOptional: One.Two?
            let onetwoUnwrapped: One.Two!
        
            let innerClassOptional: InnerClass?
            let innerClassUnwrapped: InnerClass!
        
            init(innerActor: InnerActor, innerClass: InnerClass, innerStruct: InnerStruct, onetwo: One.Two, onetwoOptional: One.Two?, onetwoUnwrapped: One.Two!, innerClassOptional: InnerClass?, innerClassUnwrapped: InnerClass!) {
                self.innerActor = innerActor
                self.innerClass = innerClass
                self.innerStruct = innerStruct
                self.onetwo = onetwo
                self.onetwoOptional = onetwoOptional
                self.onetwoUnwrapped = onetwoUnwrapped
                self.innerClassOptional = innerClassOptional
                self.innerClassUnwrapped = innerClassUnwrapped
            }
        }

        enum OuterArbitrary {
            static func arbitrary(innerActor: Outer.InnerActor = Outer.InnerActorArbitrary.arbitrary(), innerClass: Outer.InnerClass = Outer.InnerClassArbitrary.arbitrary(), innerStruct: Outer.InnerStruct = Outer.InnerStructArbitrary.arbitrary(), onetwo: One.Two = One.TwoArbitrary.arbitrary(), onetwoOptional: One.Two? = One.TwoArbitrary.arbitrary(), onetwoUnwrapped: One.Two! = One.TwoArbitrary.arbitrary(), innerClassOptional: Outer.InnerClass? = Outer.InnerClassArbitrary.arbitrary(), innerClassUnwrapped: Outer.InnerClass! = Outer.InnerClassArbitrary.arbitrary()) -> Outer {
                Outer (innerActor: innerActor, innerClass: innerClass, innerStruct: innerStruct, onetwo: onetwo, onetwoOptional: onetwoOptional, onetwoUnwrapped: onetwoUnwrapped, innerClassOptional: innerClassOptional, innerClassUnwrapped: innerClassUnwrapped)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withFoundationTypes() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            let string: String
            let int: Int
            let decimal: Decimal
            let timeInterval: TimeInterval
            let date: Date
            let float: Float
            let url: URL
            let data: Data
            let error: NSError
            let uuid: UUID
            let bool: Bool
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let string: String
            let int: Int
            let decimal: Decimal
            let timeInterval: TimeInterval
            let date: Date
            let float: Float
            let url: URL
            let data: Data
            let error: NSError
            let uuid: UUID
            let bool: Bool
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(string: String = .arbitrary(.static), int: Int = .arbitrary(.static), decimal: Decimal = .arbitrary(.static), timeInterval: TimeInterval = .arbitrary(.static), date: Date = .arbitrary(.static), float: Float = .arbitrary(.static), url: URL = .arbitrary(), data: Data = .arbitrary(), error: NSError = .arbitrary(), uuid: UUID = .arbitrary(), bool: Bool = .arbitrary(.static)) -> SimpleModel {
                SimpleModel (string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid, bool: bool)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withOptionalFoundationTypes() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            let string: String?
            let int: Int?
            let decimal: Decimal?
            let timeInterval: TimeInterval?
            let date: Date?
            let float: Float?
            let url: URL?
            let data: Data?
            let error: NSError?
            let uuid: UUID?
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let string: String?
            let int: Int?
            let decimal: Decimal?
            let timeInterval: TimeInterval?
            let date: Date?
            let float: Float?
            let url: URL?
            let data: Data?
            let error: NSError?
            let uuid: UUID?
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(string: String? = .arbitrary(.static), int: Int? = .arbitrary(.static), decimal: Decimal? = .arbitrary(.static), timeInterval: TimeInterval? = .arbitrary(.static), date: Date? = .arbitrary(.static), float: Float? = .arbitrary(.static), url: URL? = .arbitrary(), data: Data? = .arbitrary(), error: NSError? = .arbitrary(), uuid: UUID? = .arbitrary()) -> SimpleModel {
                SimpleModel (string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withForceUnwrappedFoundationTypes() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            let string: String!
            let int: Int!
            let decimal: Decimal!
            let timeInterval: TimeInterval!
            let date: Date!
            let float: Float!
            let url: URL!
            let data: Data!
            let error: NSError!
            let uuid: UUID!
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let string: String!
            let int: Int!
            let decimal: Decimal!
            let timeInterval: TimeInterval!
            let date: Date!
            let float: Float!
            let url: URL!
            let data: Data!
            let error: NSError!
            let uuid: UUID!
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(string: String! = .arbitrary(), int: Int! = .arbitrary(), decimal: Decimal! = .arbitrary(), timeInterval: TimeInterval! = .arbitrary(), date: Date! = .arbitrary(), float: Float! = .arbitrary(), url: URL! = .arbitrary(), data: Data! = .arbitrary(), error: NSError! = .arbitrary(), uuid: UUID! = .arbitrary()) -> SimpleModel {
                SimpleModel (string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withClosures() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            let simpleClosure: () -> Void
            let optionalClosure: ((String, Int) -> CustomType)?
            let forceUnwrappedClosure: ((String, Int) -> Bool)!
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let simpleClosure: () -> Void
            let optionalClosure: ((String, Int) -> CustomType)?
            let forceUnwrappedClosure: ((String, Int) -> Bool)!
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(simpleClosure: @escaping () -> Void = { 
                }, optionalClosure: ((String, Int) -> CustomType)? = { _, _ in
                    CustomTypeArbitrary.arbitrary()
                }, forceUnwrappedClosure: ((String, Int) -> Bool)! = { _, _ in
                    Bool.arbitrary(.static)
                }) -> SimpleModel {
                SimpleModel (simpleClosure: simpleClosure, optionalClosure: optionalClosure, forceUnwrappedClosure: forceUnwrappedClosure)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withCollections() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            let array: [String]
            let _array: Array<String>
            let set: Set<String>
            let dictionary: [String: String]
            let _dictionary: Dictionary<String, String>
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let array: [String]
            let _array: Array<String>
            let set: Set<String>
            let dictionary: [String: String]
            let _dictionary: Dictionary<String, String>
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(array: [String] = [], _array: Array<String> = [], set: Set<String> = [], dictionary: [String: String] = [:], _dictionary: Dictionary<String, String> = [:]) -> SimpleModel {
                SimpleModel (array: array, _array: _array, set: set, dictionary: dictionary, _dictionary: _dictionary)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withTuple() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            let tuple: (String, Model)
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let tuple: (String, Model)
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(tuple: (String, Model) = (.arbitrary(.static), ModelArbitrary.arbitrary())) -> SimpleModel {
                SimpleModel (tuple: tuple)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withCustomTypes() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            let model: Model
            let customType: CustomType
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let model: Model
            let customType: CustomType
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(model: Model = ModelArbitrary.arbitrary(), customType: CustomType = CustomTypeArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel (model: model, customType: customType)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_protocolModel() {
        assertMacroExpansion(
        """
        @Arbitrary
        protocol ProtocolModel {
            var array: [String] { get set }
            var model: Model { get set }
            var tuple: (String, [String]) { get set }
            var int: Int { get set }
            var url: URL { get set }
        }
        """,
        expandedSource:
        """
        protocol ProtocolModel {
            var array: [String] { get set }
            var model: Model { get set }
            var tuple: (String, [String]) { get set }
            var int: Int { get set }
            var url: URL { get set }
        }
        
        enum ProtocolModelArbitrary {
            static func arbitrary(array: [String] = [], model: Model = ModelArbitrary.arbitrary(), tuple: (String, [String]) = (.arbitrary(.static), []), int: Int = .arbitrary(.static), url: URL = .arbitrary()) -> ProtocolModel {
                let mock = ProtocolModelMock()
                mock.array = array
                mock.model = model
                mock.tuple = tuple
                mock.int = int
                mock.url = url
                return mock
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withPublicAccessModifier() {
        assertMacroExpansion(
        """
        @Arbitrary
        public struct SimpleModel {
            let model: Model
        }
        """,
        expandedSource:
        """
        public struct SimpleModel {
            let model: Model
        
            public init(model: Model) {
                self.model = model
            }
        }
        
        public enum SimpleModelArbitrary {
            public static func arbitrary(model: Model = ModelArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel (model: model)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_whenModelIsClass() {
        assertMacroExpansion(
        """
        @Arbitrary
        class SimpleModel {
            let model: Model
        }
        """,
        expandedSource:
        """
        class SimpleModel {
            let model: Model
        
            init(model: Model) {
                self.model = model
            }
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(model: Model = ModelArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel (model: model)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withIgnoredMacro() {
        assertMacroExpansion(
        """
        @Arbitrary
        public struct SimpleModel {
            let model: Model
            @Ignored let wrappedObject: Wrapper<Object>
        }
        """,
        expandedSource:
        """
        public struct SimpleModel {
            let model: Model
            @Ignored let wrappedObject: Wrapper<Object>
        
            public init(model: Model, wrappedObject: Wrapper<Object>) {
                self.model = model
                self.wrappedObject = wrappedObject
            }
        }
        
        public enum SimpleModelArbitrary {
            public static func arbitrary(model: Model = ModelArbitrary.arbitrary(), wrappedObject: Wrapper<Object>) -> SimpleModel {
                SimpleModel (model: model, wrappedObject: wrappedObject)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withDynamicArgument() {
        assertMacroExpansion(
        """
        @Arbitrary(.dynamic)
        struct SimpleModel {
            let string: String
            let uuid: UUID
            let bool: Bool
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let string: String
            let uuid: UUID
            let bool: Bool
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(string: String = .arbitrary(.dynamic), uuid: UUID = .arbitrary(), bool: Bool = .arbitrary(.dynamic)) -> SimpleModel {
                SimpleModel (string: string, uuid: uuid, bool: bool)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withStaticArgument() {
        assertMacroExpansion(
        """
        @Arbitrary(.static)
        struct SimpleModel {
            let string: String
            let uuid: UUID
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            let string: String
            let uuid: UUID
        }
        
        enum SimpleModelArbitrary {
            static func arbitrary(string: String = .arbitrary(.static), uuid: UUID = .arbitrary()) -> SimpleModel {
                SimpleModel (string: string, uuid: uuid)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToExtension() {
        assertMacroExpansion(
        """
        @Arbitrary
        extension Model {}
        """,
        expandedSource:
        """
        extension Model {}
        """,
        diagnostics: [
            .init(message: "@Arbitrary macro is attached to an unsupported declaration", line: 1, column: 1)
        ],
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToEnum() {
        assertMacroExpansion(
        """
        @Arbitrary
        enum Model {}
        """,
        expandedSource:
        """
        enum Model {}
        """,
        diagnostics: [
            .init(message: "@Arbitrary macro is attached to an unsupported declaration", line: 1, column: 1)
        ],
        macros: testMacros
        )
    }
}
