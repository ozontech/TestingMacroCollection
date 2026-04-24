//
//  ProxyableMock.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

// MARK: - ProxyableMock

/// A protocol that eliminates the use of `mock.mock` to access the generated properties of `@AnyMockable` mocks.
///
///     extension IMock: ProxyableMock {}
///
/// Client response:
///
///     let mock = IMock()
///     mock.updateClosure = { _ in }
///     print(mock.updateCallsCount)
///
@dynamicMemberLookup
public protocol ProxyableMock: AnyObject {
    associatedtype Mock
    var mock: Mock { get }
}

public extension ProxyableMock {
    subscript<T>(dynamicMember keyPath: ReferenceWritableKeyPath<Mock, T>) -> T {
        get { mock[keyPath: keyPath] }
        set { mock[keyPath: keyPath] = newValue }
    }
}
