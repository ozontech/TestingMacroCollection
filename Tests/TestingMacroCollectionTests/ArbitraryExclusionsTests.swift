//
//  ArbitraryExclusionsTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
@testable import TestingMacroCollection
import XCTest

final class ArbitraryExclusionsTests: XCTestCase {
    func test_int() {
        // Given
        let min = 1
        let max = 2
        let exclusion = max

        // When
        let result = Int.arbitrary(.dynamic, min: min, max: max, exclusions: [exclusion])

        // Then
        XCTAssertEqual(result, min)
    }

    func test_decimal() {
        // Given
        let min = 1
        let max = 2
        let exclusion = max

        // When
        let result = Decimal.arbitrary(.dynamic, min: min, max: max, exclusions: [exclusion])

        // Then
        XCTAssertEqual(result, Decimal(min))
    }
}
