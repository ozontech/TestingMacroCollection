//
//  main.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import TestingMacroCollection
import Foundation

// MARK: - Playground

// You can test macro here.

// MARK: - Mock

public enum BadError: Error {}

@Mock(.open, heritability: .inheritable, sendableMode: .enabled, defaultValue: .static)
protocol Generic {
    @available(iOS 14.0, macOS 11.0, *)
    func test_simple<T>(value: T) async throws(BadError) -> T
    func test_complex<T, E>(value: [T], argument: (T, E)) -> [String: E]
    func test_closure<T, E>(closure: @escaping (T, E) -> E)
    func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T]
}

@Mock
protocol GenericActor: Actor {
    func test_simple<T>(value: T) async -> T
    func test_complex<T, E>(value: [T], argument: (T, E)) async throws(BadError) -> [String: E]
    func test_closure<T, E>(closure: @escaping (@Sendable (T, E) -> E)) async
    func test_closure_with_return_value<T, E>(closure: @escaping (@Sendable (T, E) -> E)) async -> [T]
}

@Mock(heritability: .inheritable, sendableMode: .enabled, defaultValue: .static)
protocol IParentService: Sendable {
    @available(swift 5.0)
    var session: URLSession { get set }

    func download(path: String) async throws -> Data
}

@Mock
protocol MethodOverloading {
    func job<T>(arg: T)
    func job<T>(arg: T?)
    
    func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate)
    func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService)
    func jobOne(_ arg1: [String: Int], _ arg2: (Bool, Int), _ arg3: @Sendable @escaping () -> Void)
}

struct Outer {
    struct Inner { }
}

@Mock(sendableMode: .enabled)
protocol IService: IParentService {
    var path: String { get set }
    var dictionary: [String: Any] { get set }
    var nested: Outer.Inner { get set }

    func upload(data: String) async throws(BadError) -> Bool
}

@Mock(.public)
protocol ActorService: Actor {
    var property: String { get async }

    func brilliantMethod() async throws -> String
}

// MARK: - AnyMockable & MockAccessor

protocol ISuperDuperFastService: Actor {
    var veryVeryVeryLittleData: (String, Data) { get async }

    func superFastDownload(target: String) async
    func superDuperMethod(argument: String, another _argument: Int) async throws
}

protocol ISuperDuperSlowService: ISuperDuperFastService {
    var veryVeryVeryBigData: Data { get async }
    var nested: Outer.Inner { get async }

    func superSlowMethod(bigFile: Data) async throws(BadError) -> [Data]
}

@AnyMockable
actor MediumService: ISuperDuperSlowService {
    var veryVeryVeryBigData: Data
    var nested: Outer.Inner
    var veryVeryVeryLittleData: (String, Data)

    func superSlowMethod(bigFile: Data) async throws(BadError) -> [Data] {}

    func superFastDownload(target: String) async {}

    func superDuperMethod(argument: String, another _argument: Int) async throws {}
}

@AnyMockable
class MethodOverloadingAnyMockable: MethodOverloading {
    func job<T>(arg: T) {}
    func job<T>(arg: T?) {}
    
    func jobOne(_ arg1: Character, _ arg2: SecTrust, _ arg3: SecCertificate) {}
    func jobOne(_ arg1: Int?, _ arg2: [Bool], _ arg3: some IParentService) {}
    func jobOne(_ arg1: [String : Int], _ arg2: (Bool, Int), _ arg3: @escaping () -> Void) {}
}

@AnyMockable
class AnyMockableWithGeneric: Generic {
    func test_closure<T, E>(closure: @escaping (T, E) -> E) {}
    
    func test_closure_with_return_value<T, E>(closure: @escaping (T, E) -> E) -> [T] {}
    
    func test_simple<T>(value: T) async throws(BadError) -> T {}
    
    func test_complex<T, E>(value: [T], argument: (T, E)) -> [String : E] {}
}

// MARK: - PerformanceMeasure

let closure = { }

let executionTime = #performanceMeasure {
    closure()
}

// MARK: - AutoEquatable

@AutoEquatable
class SomeClass {
    let id: UUID
    @Ignored
    let name: String
    let filter: () -> Bool

    init(id: UUID, name: String, filter: @escaping () -> Bool) {
        self.id = id
        self.name = name
        self.filter = filter
    }
}

@AutoEquatable
public struct Structure {
    let id: UUID
    @Ignored
    let name: String
    let filter: () -> Bool
}

@AutoEquatable
enum Enumeration {
    case first
    case second(path: String)
    case third(one: Int, two: Double, three: Decimal)
    case fourth
    case fifth(arg: Int, _ arg2: Double)

    @Ignored
    var property: Bool { false }
    var isHype: Bool { true }
}

@AutoEquatable
enum Route {
    case main
    case profile
    case editProfile

    var property: Bool { true }
    var name: String { "name" }
}

// MARK: - Arbitrary

@Mock
@Arbitrary
protocol CustomType {}

@Mock
@Arbitrary
protocol ForArbitrary {
    var foundationType: String { get set }
    var optionalType: Int? { get set }
    var array: [String] { get set }
    var forceUnwrapped: UUID! { get set }
    var tuple: (String, Int) { get set }
    var customType: CustomType { get set }
    var optionalClosure: (() -> String)? { get set }
}

@Arbitrary(.static)
class ClassModel {
    @Nilable let optionalType: CustomType?
    @Nilable var forceUnwrappedType: CustomType!
}

@Arbitrary
class One {
    @Arbitrary
    class Two {}
}

@Arbitrary(.dynamic)
class Parent {
    @Arbitrary
    class Nested {}

    let nestedObject: Nested
    let nestedObjectOptional: Nested?
    let nestedObjectUnwraped: Nested!
    let onetwo: One.Two
    let onetwoOptional: One.Two?
    let onetwoUnwraped: One.Two!
}

@Arbitrary
struct OneOne {
    let two: [OneOne.TwoTwo]
    let three: OneOne.Three

    @Arbitrary
    struct Three {
        let three: [Four]
    }
}

extension OneOne {
    @Arbitrary
    struct TwoTwo {
        let two: String
    }
}

extension OneOne.TwoTwo {
    @Arbitrary
    struct FourFour {
        let four: String
    }
}

@Arbitrary
struct Four {
    let four: String
}

@Arbitrary
struct ServiceModel {}

@Mock
@Arbitrary
protocol AnotherServiceProtocol {}

@Arbitrary()
class Service {
    let name: String
    let model: ServiceModel
    let anotherProtocol: AnotherServiceProtocol

    init(
        name: String,
        model: ServiceModel,
        anotherProtocol: AnotherServiceProtocol
    ) {
        self.name = name
        self.model = model
        self.anotherProtocol = anotherProtocol
    }
}

@Arbitrary(.dynamic)
enum MyEnum {
    case a(name1: StructInEnum, name2: String)
    case b
}

@Arbitrary
struct StructInEnum {
    let string: String
}

@Arbitrary
class ClassWithEnum {
    let int: Int
    let enumVar: MyEnum
    let nestedEnum: ClassWithEnum.NestedEnum
}

extension ClassWithEnum {
    @Arbitrary()
    enum NestedEnum {
        @ArbitraryDefaultCase case a
        case b
    }
}

public struct PublicStruct {}

public extension PublicStruct {
    @Arbitrary(accessModifier: .internal)
    struct InnerPublicStruct {
        public let string: String
    }
}
