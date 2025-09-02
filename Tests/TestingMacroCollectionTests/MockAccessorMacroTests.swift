//
//  MockAccessorMacroTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class MockAccessorMacroTests: XCTestCase {
    func testMockAccessor_createsGetterAndSetter() {
        assertMacroExpansion(
        """
        @MockAccessor var property: String
        """,
        expandedSource: 
        """
        var property: String {
            get {
                mock.underlyingProperty
            }
            set(newValue) {
                mock.underlyingProperty = newValue
            }
        }
        """,
        macros: testMacros
        )
    }
}
