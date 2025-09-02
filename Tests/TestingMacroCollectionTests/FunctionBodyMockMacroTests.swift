//
//  FunctionBodyMockMacroTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class FunctionBodyMockMacroTests: XCTestCase {
    func testFunctionBodyMock_callingMockMethod() {
        assertMacroExpansion(
        """
        final class Mock {
            @FunctionBodyMock
            func callMock() {}
        }
        """,
        expandedSource:
        """
        final class Mock {
            func callMock() {
                mock.callMock()
            }
        }
        """,
        macros: testMacros
        )
    }

    func testFunctionBodyMock_callingMockMethodWithParameters() {
        assertMacroExpansion(
        """
        final class Mock {
            @FunctionBodyMock
            func callMock(first: String, _ second: Int, third parameter: Bool) {}
        }
        """,
        expandedSource:
        """
        final class Mock {
            func callMock(first: String, _ second: Int, third parameter: Bool) {
                mock.callMock(first: first, second, third: parameter)
            }
        }
        """,
        macros: testMacros
        )
    }

    func testFunctionBodyMock_callingMockMethodWithAsyncThrows() {
        assertMacroExpansion(
        """
        final class Mock {
            @FunctionBodyMock
            func callAsyncMock() async {}
        
            @FunctionBodyMock
            func callThrowsMock() throws {}
        
            @FunctionBodyMock
            func callAsyncThrowsMock() async throws {}
        }
        """,
        expandedSource:
        """
        final class Mock {
            func callAsyncMock() async {
                await mock.callAsyncMock()
            }
            func callThrowsMock() throws {
                try mock.callThrowsMock()
            }
            func callAsyncThrowsMock() async throws {
                try await mock.callAsyncThrowsMock()
            }
        }
        """,
        macros: testMacros
        )
    }
}
