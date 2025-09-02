//
//  Foundation+Arbitrary.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftUI

// MARK: - String

public extension String {
    static func arbitrary(_ arbitraryType: ArbitraryType = .static, length: Int = 10) -> String {
        arbitraryType == .static ? "string" : dynamicArbitrary(length: length)
    }

    private static func dynamicArbitrary(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0 ..< length).compactMap { _ in letters.randomElement() })
    }
}

// MARK: - Bool

public extension Bool {
    static func arbitrary(_ arbitraryType: ArbitraryType = .static) -> Bool {
        arbitraryType == .static ? true : .random()
    }
}

// MARK: - Int

public extension Int {
    static func arbitrary(_ arbitraryType: ArbitraryType = .static, min: Int = 0, max: Int = 100, exclusions: [Int] = []) -> Int {
        switch arbitraryType {
        case .static:
            return 123
        case .dynamic:
            guard !exclusions.isEmpty else { return Int.random(in: min ... max) }

            let allowedRange = ClosedRange(uncheckedBounds: (min, max)).filter { !exclusions.contains($0) }
            return allowedRange.randomElement() ?? min
        }
    }
}

public extension Int64 {
    static func arbitrary(
        _ arbitraryType: ArbitraryType = .static,
        min: Int64 = 0,
        max: Int64 = 100,
        exclusions: [Int64] = []
    ) -> Int64 {
        switch arbitraryType {
        case .static:
            return 123
        case .dynamic:
            guard !exclusions.isEmpty else { return Int64.random(in: min ... max) }

            let allowedRange = ClosedRange(uncheckedBounds: (min, max)).filter { !exclusions.contains($0) }
            return allowedRange.randomElement() ?? min
        }
    }
}

// MARK: - Decimal

public extension Decimal {
    static func arbitrary(
        _ arbitraryType: ArbitraryType = .static,
        min: Int = 0,
        max: Int = 100,
        exclusions: [Int] = []
    ) -> Decimal {
        switch arbitraryType {
        case .static:
            return Decimal(123_123)
        case .dynamic:
            guard !exclusions.isEmpty else { return Decimal(Int.random(in: min ... max)) }

            let allowedRange = ClosedRange(uncheckedBounds: (min, max)).filter { !exclusions.contains($0) }
            return Decimal(allowedRange.randomElement() ?? min)
        }
    }
}

// MARK: - TimeInterval

public extension TimeInterval {
    static func arbitrary(
        _ arbitraryType: ArbitraryType = .static,
        min: TimeInterval = 0,
        max: TimeInterval = 100,
        exclusions: [TimeInterval] = []
    ) -> TimeInterval {
        switch arbitraryType {
        case .dynamic:
            guard !exclusions.isEmpty else { return TimeInterval.random(in: min ... max) }

            var randomElement: TimeInterval = min

            repeat {
                randomElement = TimeInterval.random(in: min ... max)
            } while exclusions.contains(randomElement)

            return randomElement
        case .static:
            return TimeInterval(123_123)
        }
    }
}

// MARK: - Date

public extension Date {
    static func arbitrary(_ arbitraryType: ArbitraryType = .static, max: Int = 1000) -> Date {
        arbitraryType == .static ? Date(timeIntervalSince1970: 10000) : Date()
            .addingTimeInterval(TimeInterval(Int.arbitrary(max: max)))
    }
}

// MARK: - Float

public extension Float {
    static func arbitrary(
        _ arbitraryType: ArbitraryType = .static,
        min: Float = 0,
        max: Float = 10,
        exclusions: [Float] = []
    ) -> Float {
        switch arbitraryType {
        case .dynamic:
            guard !exclusions.isEmpty else { return Float.random(in: min ... max) }
            var randomElement: Float = min

            repeat {
                randomElement = Float.random(in: min ... max)
            } while exclusions.contains(randomElement)

            return randomElement
        case .static:
            return 123.2
        }
    }
}

// MARK: - URL

public extension URL {
    static func arbitrary(urlString: String = "/device") -> URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: urlString)!
    }
}

// MARK: - Data

public extension Data {
    static func arbitrary() -> Data {
        Data(count: 10)
    }
}

// MARK: - NSError

public extension NSError {
    static func arbitrary() -> NSError {
        NSError(domain: "", code: -8, userInfo: nil)
    }
}

// MARK: - UUID

public extension UUID {
    static func arbitrary() -> UUID {
        .init()
    }
}
