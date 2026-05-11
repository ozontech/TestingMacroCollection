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
    func testArbitraryMacro_withBuildType() {
        assertMacroExpansion(
        """
        @Arbitrary(buildType: .prod)
        struct ProdModel {}
        
        @Arbitrary
        struct DebugModel {}
        
        @Arbitrary(buildType: .debug)
        struct AlsoDebugModel {}
        """,
        expandedSource:
        """
        struct ProdModel {}

        enum ProdModelArbitrary {
            static func arbitrary() -> ProdModel {
                ProdModel ()
            }
        }
        struct DebugModel {}

        #if DEBUG
        enum DebugModelArbitrary {
            static func arbitrary() -> DebugModel {
                DebugModel ()
            }
        }
        #endif
        struct AlsoDebugModel {}

        #if DEBUG
        enum AlsoDebugModelArbitrary {
            static func arbitrary() -> AlsoDebugModel {
                AlsoDebugModel ()
            }
        }
        #endif

        extension ProdModel {
            static func arbitrary() -> ProdModel {
                ProdModel()
            }
        }

        #if DEBUG
        extension DebugModel {
            static func arbitrary() -> DebugModel {
                DebugModel()
            }
        }
        #endif

        #if DEBUG
        extension AlsoDebugModel {
            static func arbitrary() -> AlsoDebugModel {
                AlsoDebugModel()
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenAccessModifierIsDefined_Auto() {
        assertMacroExpansion(
        """
        @Arbitrary(accessModifier: .auto)
        public struct PublicStruct {
            public let id: String
        }
        
        @Arbitrary(accessModifier: .auto)
        struct InternalStruct {
            let id: String
        }
        """,
        expandedSource:
        """
        public struct PublicStruct {
            public let id: String

            public init(id: String) {
                self.id = id
            }
        }
        
        #if DEBUG
        
        public enum PublicStructArbitrary {
            public static func arbitrary(id: String = .arbitrary(.static)) -> PublicStruct {
                PublicStruct (id: id)
            }
        }
        #endif
        struct InternalStruct {
            let id: String
        }

        #if DEBUG
        enum InternalStructArbitrary {
            static func arbitrary(id: String = .arbitrary(.static)) -> InternalStruct {
                InternalStruct (id: id)
            }
        }
        #endif
        
        #if DEBUG
        extension PublicStruct {
            public static func arbitrary(id: String = .arbitrary(.static)) -> PublicStruct {
                PublicStruct(id: id)
            }
        }
        #endif
        
        #if DEBUG
        extension InternalStruct {
            static func arbitrary(id: String = .arbitrary(.static)) -> InternalStruct {
                InternalStruct(id: id)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }
    
    func testArbitrary_whenAccessModifierIsDefined_Public() {
        assertMacroExpansion(
        """
        @Arbitrary(accessModifier: .public)
        struct PublicStruct {
            let id: String
        }
        
        @Arbitrary
        public struct AutoNotDefinedStruct {
            public let id: String
        }
        """,
        expandedSource:
        """
        struct PublicStruct {
            let id: String

            public init(id: String) {
                self.id = id
            }
        }

        #if DEBUG
        public enum PublicStructArbitrary {
            public static func arbitrary(id: String = .arbitrary(.static)) -> PublicStruct {
                PublicStruct (id: id)
            }
        }
        #endif
        public struct AutoNotDefinedStruct {
            public let id: String

            public init(id: String) {
                self.id = id
            }
        }

        #if DEBUG
        
        public enum AutoNotDefinedStructArbitrary {
            public static func arbitrary(id: String = .arbitrary(.static)) -> AutoNotDefinedStruct {
                AutoNotDefinedStruct (id: id)
            }
        }
        #endif
        
        #if DEBUG
        extension PublicStruct {
            public static func arbitrary(id: String = .arbitrary(.static)) -> PublicStruct {
                PublicStruct(id: id)
            }
        }
        #endif

        #if DEBUG
        extension AutoNotDefinedStruct {
            public static func arbitrary(id: String = .arbitrary(.static)) -> AutoNotDefinedStruct {
                AutoNotDefinedStruct(id: id)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }
    
    func testArbitrary_whenAccessModifierIsDefined_Internal() {
        assertMacroExpansion(
        """
        @Arbitrary(accessModifier: .internal)
        public struct InternalStruct {
            public let id: String
        }
        
        @Arbitrary
        struct AutoNotDefinedStruct {
            let id: String
        }
        """,
        expandedSource:
        """
        public struct InternalStruct {
            public let id: String
        }

        #if DEBUG
        enum InternalStructArbitrary {
            static func arbitrary(id: String = .arbitrary(.static)) -> InternalStruct {
                InternalStruct (id: id)
            }
        }
        #endif
        struct AutoNotDefinedStruct {
            let id: String
        }

        #if DEBUG
        enum AutoNotDefinedStructArbitrary {
            static func arbitrary(id: String = .arbitrary(.static)) -> AutoNotDefinedStruct {
                AutoNotDefinedStruct (id: id)
            }
        }
        #endif
        
        #if DEBUG
        extension InternalStruct {
            static func arbitrary(id: String = .arbitrary(.static)) -> InternalStruct {
                InternalStruct(id: id)
            }
        }
        #endif

        #if DEBUG
        extension AutoNotDefinedStruct {
            static func arbitrary(id: String = .arbitrary(.static)) -> AutoNotDefinedStruct {
                AutoNotDefinedStruct(id: id)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenPropertyIsNilable() {
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
        
        #if DEBUG
        enum ClassModelArbitrary {
            static func arbitrary(optionalType: CustomType? = nil, forceUnwrappedType: CustomType! = nil) -> ClassModel {
                ClassModel (optionalType: optionalType, forceUnwrappedType: forceUnwrappedType)
            }
        }
        #endif
        
        #if DEBUG
        extension ClassModel {
            static func arbitrary(optionalType: CustomType? = nil, forceUnwrappedType: CustomType! = nil) -> ClassModel {
                ClassModel(optionalType: optionalType, forceUnwrappedType: forceUnwrappedType)
            }
        }
        #endif
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
        
            #if DEBUG
            enum TwoArbitrary {
                static func arbitrary() -> Two {
                    Two ()
                }
            }
            #endif
        }
        class Outer {
            actor InnerActor { }

            #if DEBUG
            enum InnerActorArbitrary {
                static func arbitrary() -> InnerActor {
                    InnerActor ()
                }
            }
            #endif
            
            let innerActor: InnerActor
            class InnerClass { }

            #if DEBUG
            enum InnerClassArbitrary {
                static func arbitrary() -> InnerClass {
                    InnerClass ()
                }
            }
            #endif
        
            let innerClass: InnerClass
            struct InnerStruct { }

            #if DEBUG
            enum InnerStructArbitrary {
                static func arbitrary() -> InnerStruct {
                    InnerStruct ()
                }
            }
            #endif
        
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

        #if DEBUG
        enum OuterArbitrary {
            static func arbitrary(innerActor: Outer.InnerActor = Outer.InnerActorArbitrary.arbitrary(), innerClass: Outer.InnerClass = Outer.InnerClassArbitrary.arbitrary(), innerStruct: Outer.InnerStruct = Outer.InnerStructArbitrary.arbitrary(), onetwo: One.Two = One.TwoArbitrary.arbitrary(), onetwoOptional: One.Two? = One.TwoArbitrary.arbitrary(), onetwoUnwrapped: One.Two! = One.TwoArbitrary.arbitrary(), innerClassOptional: Outer.InnerClass? = Outer.InnerClassArbitrary.arbitrary(), innerClassUnwrapped: Outer.InnerClass! = Outer.InnerClassArbitrary.arbitrary()) -> Outer {
                Outer (innerActor: innerActor, innerClass: innerClass, innerStruct: innerStruct, onetwo: onetwo, onetwoOptional: onetwoOptional, onetwoUnwrapped: onetwoUnwrapped, innerClassOptional: innerClassOptional, innerClassUnwrapped: innerClassUnwrapped)
            }
        }
        #endif
        
        #if DEBUG
        extension One.Two {
            static func arbitrary() -> One.Two {
                One.Two()
            }
        }
        #endif
        
        #if DEBUG
        extension Outer.InnerActor {
            static func arbitrary() -> Outer.InnerActor {
                Outer.InnerActor()
            }
        }
        #endif
        
        #if DEBUG
        extension Outer.InnerClass {
            static func arbitrary() -> Outer.InnerClass {
                Outer.InnerClass()
            }
        }
        #endif
        
        #if DEBUG
        extension Outer.InnerStruct {
            static func arbitrary() -> Outer.InnerStruct {
                Outer.InnerStruct()
            }
        }
        #endif
        
        #if DEBUG
        extension Outer {
            static func arbitrary(innerActor: Outer.InnerActor = Outer.InnerActorArbitrary.arbitrary(), innerClass: Outer.InnerClass = Outer.InnerClassArbitrary.arbitrary(), innerStruct: Outer.InnerStruct = Outer.InnerStructArbitrary.arbitrary(), onetwo: One.Two = One.TwoArbitrary.arbitrary(), onetwoOptional: One.Two? = One.TwoArbitrary.arbitrary(), onetwoUnwrapped: One.Two! = One.TwoArbitrary.arbitrary(), innerClassOptional: Outer.InnerClass? = Outer.InnerClassArbitrary.arbitrary(), innerClassUnwrapped: Outer.InnerClass! = Outer.InnerClassArbitrary.arbitrary()) -> Outer {
                Outer(innerActor: innerActor, innerClass: innerClass, innerStruct: innerStruct, onetwo: onetwo, onetwoOptional: onetwoOptional, onetwoUnwrapped: onetwoUnwrapped, innerClassOptional: innerClassOptional, innerClassUnwrapped: innerClassUnwrapped)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_deepNestedTypes() {
        assertMacroExpansion(
        """
        struct One {
            struct Two {
                struct Three {
                    let three: String
                }
            }
        }

        @Arbitrary
        struct DeepNestedModel {
            let oneTwoThree: One.Two.Three
        }
        """,
        expandedSource:
        """
        struct One {
            struct Two {
                struct Three {
                    let three: String
                }
            }
        }
        struct DeepNestedModel {
            let oneTwoThree: One.Two.Three
        }

        #if DEBUG
        enum DeepNestedModelArbitrary {
            static func arbitrary(oneTwoThree: One.Two.Three = One.Two.ThreeArbitrary.arbitrary()) -> DeepNestedModel {
                DeepNestedModel (oneTwoThree: oneTwoThree)
            }
        }
        #endif

        #if DEBUG
        extension DeepNestedModel {
            static func arbitrary(oneTwoThree: One.Two.Three = One.Two.ThreeArbitrary.arbitrary()) -> DeepNestedModel {
                DeepNestedModel(oneTwoThree: oneTwoThree)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(string: String = .arbitrary(.static), int: Int = .arbitrary(.static), decimal: Decimal = .arbitrary(.static), timeInterval: TimeInterval = .arbitrary(.static), date: Date = .arbitrary(.static), float: Float = .arbitrary(.static), url: URL = .arbitrary(), data: Data = .arbitrary(), error: NSError = .arbitrary(), uuid: UUID = .arbitrary(), bool: Bool = .arbitrary(.static)) -> SimpleModel {
                SimpleModel (string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid, bool: bool)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(string: String = .arbitrary(.static), int: Int = .arbitrary(.static), decimal: Decimal = .arbitrary(.static), timeInterval: TimeInterval = .arbitrary(.static), date: Date = .arbitrary(.static), float: Float = .arbitrary(.static), url: URL = .arbitrary(), data: Data = .arbitrary(), error: NSError = .arbitrary(), uuid: UUID = .arbitrary(), bool: Bool = .arbitrary(.static)) -> SimpleModel {
                SimpleModel(string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid, bool: bool)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(string: String? = .arbitrary(.static), int: Int? = .arbitrary(.static), decimal: Decimal? = .arbitrary(.static), timeInterval: TimeInterval? = .arbitrary(.static), date: Date? = .arbitrary(.static), float: Float? = .arbitrary(.static), url: URL? = .arbitrary(), data: Data? = .arbitrary(), error: NSError? = .arbitrary(), uuid: UUID? = .arbitrary()) -> SimpleModel {
                SimpleModel (string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(string: String? = .arbitrary(.static), int: Int? = .arbitrary(.static), decimal: Decimal? = .arbitrary(.static), timeInterval: TimeInterval? = .arbitrary(.static), date: Date? = .arbitrary(.static), float: Float? = .arbitrary(.static), url: URL? = .arbitrary(), data: Data? = .arbitrary(), error: NSError? = .arbitrary(), uuid: UUID? = .arbitrary()) -> SimpleModel {
                SimpleModel(string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(string: String! = .arbitrary(), int: Int! = .arbitrary(), decimal: Decimal! = .arbitrary(), timeInterval: TimeInterval! = .arbitrary(), date: Date! = .arbitrary(), float: Float! = .arbitrary(), url: URL! = .arbitrary(), data: Data! = .arbitrary(), error: NSError! = .arbitrary(), uuid: UUID! = .arbitrary()) -> SimpleModel {
                SimpleModel (string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(string: String! = .arbitrary(), int: Int! = .arbitrary(), decimal: Decimal! = .arbitrary(), timeInterval: TimeInterval! = .arbitrary(), date: Date! = .arbitrary(), float: Float! = .arbitrary(), url: URL! = .arbitrary(), data: Data! = .arbitrary(), error: NSError! = .arbitrary(), uuid: UUID! = .arbitrary()) -> SimpleModel {
                SimpleModel(string: string, int: int, decimal: decimal, timeInterval: timeInterval, date: date, float: float, url: url, data: data, error: error, uuid: uuid)
            }
        }
        #endif
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
        
        #if DEBUG
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
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(simpleClosure: @escaping () -> Void = { 
                }, optionalClosure: ((String, Int) -> CustomType)? = { _, _ in
                    CustomTypeArbitrary.arbitrary()
                }, forceUnwrappedClosure: ((String, Int) -> Bool)! = { _, _ in
                    Bool.arbitrary(.static)
                }) -> SimpleModel {
                SimpleModel(simpleClosure: simpleClosure, optionalClosure: optionalClosure, forceUnwrappedClosure: forceUnwrappedClosure)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(array: [String] = [.arbitrary()], _array: Array<String> = [.arbitrary()], set: Set<String> = [.arbitrary()], dictionary: [String: String] = [:], _dictionary: Dictionary<String, String> = [:]) -> SimpleModel {
                SimpleModel (array: array, _array: _array, set: set, dictionary: dictionary, _dictionary: _dictionary)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(array: [String] = [.arbitrary()], _array: Array<String> = [.arbitrary()], set: Set<String> = [.arbitrary()], dictionary: [String: String] = [:], _dictionary: Dictionary<String, String> = [:]) -> SimpleModel {
                SimpleModel(array: array, _array: _array, set: set, dictionary: dictionary, _dictionary: _dictionary)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_simpleModel_withEmptedCollections() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct SimpleModel {
            @Empted let array: [String]
            let _array: Array<String>
            @Empted let set: Set<String>
            let dictionary: [String: String]
            let _dictionary: Dictionary<String, String>
        }
        """,
        expandedSource:
        """
        struct SimpleModel {
            @Empted let array: [String]
            let _array: Array<String>
            @Empted let set: Set<String>
            let dictionary: [String: String]
            let _dictionary: Dictionary<String, String>
        }
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(array: [String] = [], _array: Array<String> = [.arbitrary()], set: Set<String> = [], dictionary: [String: String] = [:], _dictionary: Dictionary<String, String> = [:]) -> SimpleModel {
                SimpleModel (array: array, _array: _array, set: set, dictionary: dictionary, _dictionary: _dictionary)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(array: [String] = [], _array: Array<String> = [.arbitrary()], set: Set<String> = [], dictionary: [String: String] = [:], _dictionary: Dictionary<String, String> = [:]) -> SimpleModel {
                SimpleModel(array: array, _array: _array, set: set, dictionary: dictionary, _dictionary: _dictionary)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(tuple: (String, Model) = (.arbitrary(.static), ModelArbitrary.arbitrary())) -> SimpleModel {
                SimpleModel (tuple: tuple)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(tuple: (String, Model) = (.arbitrary(.static), ModelArbitrary.arbitrary())) -> SimpleModel {
                SimpleModel(tuple: tuple)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(model: Model = ModelArbitrary.arbitrary(), customType: CustomType = CustomTypeArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel (model: model, customType: customType)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(model: Model = ModelArbitrary.arbitrary(), customType: CustomType = CustomTypeArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel(model: model, customType: customType)
            }
        }
        #endif
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
        
        #if DEBUG
        enum ProtocolModelArbitrary {
            static func arbitrary(array: [String] = [.arbitrary()], model: Model = ModelArbitrary.arbitrary(), tuple: (String, [String]) = (.arbitrary(.static), [.arbitrary()]), int: Int = .arbitrary(.static), url: URL = .arbitrary()) -> ProtocolModel {
                let mock = ProtocolModelMock()
                mock.array = array
                mock.model = model
                mock.tuple = tuple
                mock.int = int
                mock.url = url
                return mock
            }
        }
        #endif
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
        
        #if DEBUG
        
        public enum SimpleModelArbitrary {
            public static func arbitrary(model: Model = ModelArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel (model: model)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            public static func arbitrary(model: Model = ModelArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel(model: model)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(model: Model = ModelArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel (model: model)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(model: Model = ModelArbitrary.arbitrary()) -> SimpleModel {
                SimpleModel(model: model)
            }
        }
        #endif
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
        
        #if DEBUG
        
        public enum SimpleModelArbitrary {
            public static func arbitrary(model: Model = ModelArbitrary.arbitrary(), wrappedObject: Wrapper<Object>) -> SimpleModel {
                SimpleModel (model: model, wrappedObject: wrappedObject)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            public static func arbitrary(model: Model = ModelArbitrary.arbitrary(), wrappedObject: Wrapper<Object>) -> SimpleModel {
                SimpleModel(model: model, wrappedObject: wrappedObject)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(string: String = .arbitrary(.dynamic), uuid: UUID = .arbitrary(), bool: Bool = .arbitrary(.dynamic)) -> SimpleModel {
                SimpleModel (string: string, uuid: uuid, bool: bool)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(string: String = .arbitrary(.dynamic), uuid: UUID = .arbitrary(), bool: Bool = .arbitrary(.dynamic)) -> SimpleModel {
                SimpleModel(string: string, uuid: uuid, bool: bool)
            }
        }
        #endif
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
        
        #if DEBUG
        enum SimpleModelArbitrary {
            static func arbitrary(string: String = .arbitrary(.static), uuid: UUID = .arbitrary()) -> SimpleModel {
                SimpleModel (string: string, uuid: uuid)
            }
        }
        #endif
        
        #if DEBUG
        extension SimpleModel {
            static func arbitrary(string: String = .arbitrary(.static), uuid: UUID = .arbitrary()) -> SimpleModel {
                SimpleModel(string: string, uuid: uuid)
            }
        }
        #endif
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

    func testArbitrary_whenAppliedToEnumWithoutCases() {
        assertMacroExpansion(
        """
        @Arbitrary
        enum MyEnum {}
        """,
        expandedSource:
        """
        enum MyEnum {}
        """,
        diagnostics: [
            .init(message: "@Arbitrary macro attached to an empty enum", line: 1, column: 1)
        ],
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToEnumForDynamic() {
        assertMacroExpansion(
        """
        @Arbitrary(.dynamic)
        enum MyEnum {
            case a(name1: StructInEnum, name2: String)
            case b
        }

        @Arbitrary
        struct StructInEnum {
            let string: String
        }
        """,
        expandedSource:
        """
        enum MyEnum {
            case a(name1: StructInEnum, name2: String)
            case b
        }

        #if DEBUG
        enum MyEnumArbitrary {
            static func arbitrary() -> MyEnum {
                let allCases: [MyEnum ] = [.a(name1: StructInEnumArbitrary.arbitrary(), name2: .arbitrary(.dynamic)), .b]
                return allCases.randomElement()!
            }
        }
        #endif
        struct StructInEnum {
            let string: String
        }

        #if DEBUG
        enum StructInEnumArbitrary {
            static func arbitrary(string: String = .arbitrary(.static)) -> StructInEnum {
                StructInEnum (string: string)
            }
        }
        #endif
        
        #if DEBUG
        extension MyEnum {
            static func arbitrary() -> MyEnum {
                let allCases: [MyEnum ] = [.a(name1: StructInEnumArbitrary.arbitrary(), name2: .arbitrary(.dynamic)), .b]
                return allCases.randomElement()!
            }
        }
        #endif
        
        #if DEBUG
        extension StructInEnum {
            static func arbitrary(string: String = .arbitrary(.static)) -> StructInEnum {
                StructInEnum(string: string)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToEnumWithoutDefaultCaseForStatic() {
        assertMacroExpansion(
        """
        @Arbitrary
        enum MyEnum {
        case a
        case b
        }
        """,
        expandedSource:
        """
        enum MyEnum {
        case a
        case b
        }
        """,
        diagnostics: [
            .init(
                message: "@Arbitrary(.static) macro attached to an enum without a case marked with @ArbitraryDefaultCase",
                line: 1,
                column: 1
            )
        ],
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToEnumWithCasesWithoutAssociatedValues() {
        assertMacroExpansion(
        """
        @Arbitrary
        enum MyEnum {
            case a
            @ArbitraryDefaultCase
            case b
        }
        """,
        expandedSource:
        """
        enum MyEnum {
            case a
            @ArbitraryDefaultCase
            case b
        }

        #if DEBUG
        enum MyEnumArbitrary {
            static func arbitrary() -> MyEnum {
                return .b
            }
        }
        #endif
        
        #if DEBUG
        extension MyEnum {
            static func arbitrary() -> MyEnum {
                return .b
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToEnumWithCasesWithAssociatedValuesWithoutNames() {
        assertMacroExpansion(
        """
        @Arbitrary()
        enum MyEnum {
            @ArbitraryDefaultCase
            case a(MyStruct, String)
            case b
        }
        
        @Arbitrary()
        struct MyStruct {
            let string: String
        }
        """,
        expandedSource:
        """
        enum MyEnum {
            @ArbitraryDefaultCase
            case a(MyStruct, String)
            case b
        }

        #if DEBUG
        enum MyEnumArbitrary {
            static func arbitrary() -> MyEnum {
                return .a(MyStructArbitrary.arbitrary(), .arbitrary(.static))
            }
        }
        #endif
        struct MyStruct {
            let string: String
        }

        #if DEBUG
        enum MyStructArbitrary {
            static func arbitrary(string: String = .arbitrary(.static)) -> MyStruct {
                MyStruct (string: string)
            }
        }
        #endif
        
        #if DEBUG
        extension MyEnum {
            static func arbitrary() -> MyEnum {
                return .a(MyStructArbitrary.arbitrary(), .arbitrary(.static))
            }
        }
        #endif
        
        #if DEBUG
        extension MyStruct {
            static func arbitrary(string: String = .arbitrary(.static)) -> MyStruct {
                MyStruct(string: string)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToEnumWithCasesWithAssociatedValuesWithNames() {
        assertMacroExpansion(
        """
        @Arbitrary()
        enum MyEnum {
            @ArbitraryDefaultCase
            case a(name1: MyStruct, name2: String)
            case b
        }
        
        @Arbitrary()
        struct MyStruct {
            let string: String
        }
        """,
        expandedSource:
        """
        enum MyEnum {
            @ArbitraryDefaultCase
            case a(name1: MyStruct, name2: String)
            case b
        }

        #if DEBUG
        enum MyEnumArbitrary {
            static func arbitrary() -> MyEnum {
                return .a(name1: MyStructArbitrary.arbitrary(), name2: .arbitrary(.static))
            }
        }
        #endif
        struct MyStruct {
            let string: String
        }

        #if DEBUG
        enum MyStructArbitrary {
            static func arbitrary(string: String = .arbitrary(.static)) -> MyStruct {
                MyStruct (string: string)
            }
        }
        #endif
        
        #if DEBUG
        extension MyEnum {
            static func arbitrary() -> MyEnum {
                return .a(name1: MyStructArbitrary.arbitrary(), name2: .arbitrary(.static))
            }
        }
        #endif
        
        #if DEBUG
        extension MyStruct {
            static func arbitrary(string: String = .arbitrary(.static)) -> MyStruct {
                MyStruct(string: string)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToTypeWithEnumInProperties() {
        assertMacroExpansion(
        """
        @Arbitrary()
        enum MyEnum {
            @ArbitraryDefaultCase
            case a
            case b
        }
        
        @Arbitrary()
        struct MyStruct {
            let myEnum: MyEnum
        }
        """,
        expandedSource:
        """
        enum MyEnum {
            @ArbitraryDefaultCase
            case a
            case b
        }

        #if DEBUG
        enum MyEnumArbitrary {
            static func arbitrary() -> MyEnum {
                return .a
            }
        }
        #endif
        struct MyStruct {
            let myEnum: MyEnum
        }

        #if DEBUG
        enum MyStructArbitrary {
            static func arbitrary(myEnum: MyEnum = MyEnumArbitrary.arbitrary()) -> MyStruct {
                MyStruct (myEnum: myEnum)
            }
        }
        #endif
        
        #if DEBUG
        extension MyEnum {
            static func arbitrary() -> MyEnum {
                return .a
            }
        }
        #endif
        
        #if DEBUG
        extension MyStruct {
            static func arbitrary(myEnum: MyEnum = MyEnumArbitrary.arbitrary()) -> MyStruct {
                MyStruct(myEnum: myEnum)
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }
    
    func testArbitrary_whenAppliedToTypeWithComputedProperties() {
        assertMacroExpansion(
        """
        @Arbitrary
        struct StructWithComputedProperty {
            var computedProperty: Bool { true }
        }
        """,
        expandedSource:
        """
        struct StructWithComputedProperty {
            var computedProperty: Bool { true }
        }

        #if DEBUG
        enum StructWithComputedPropertyArbitrary {
            static func arbitrary() -> StructWithComputedProperty {
                StructWithComputedProperty ()
            }
        }
        #endif

        #if DEBUG
        extension StructWithComputedProperty {
            static func arbitrary() -> StructWithComputedProperty {
                StructWithComputedProperty()
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }

    func testArbitrary_whenAppliedToNestedEnum() {
        assertMacroExpansion(
        """
        struct MyStruct {
            let myEnum: MyEnum
        }
        
        extension MyStruct {
            @Arbitrary()
            enum MyEnum {
                @ArbitraryDefaultCase
                case a
                case b
            }
        }
        """,
        expandedSource:
        """
        struct MyStruct {
            let myEnum: MyEnum
        }
        
        extension MyStruct {
            enum MyEnum {
                @ArbitraryDefaultCase
                case a
                case b
            }
        
            #if DEBUG
            enum MyEnumArbitrary {
                static func arbitrary() -> MyEnum {
                    return .a
                }
            }
            #endif
        }
        
        #if DEBUG
        extension MyStruct.MyEnum {
            static func arbitrary() -> MyStruct.MyEnum {
                return .a
            }
        }
        #endif
        """,
        macros: testMacros
        )
    }
}
