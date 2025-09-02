//
//  PerformanceMeasureMacroTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class PerformanceMeasureMacroTests: XCTestCase {
    func testPerformanceMeasureMacro() {
        assertMacroExpansion(
        """
        let time = #performanceMeasure {
            doWork()
        }
        """,
        expandedSource:
        """
        let time = {
            let startTime = CFAbsoluteTimeGetCurrent()
            doWork()
            return Double(CFAbsoluteTimeGetCurrent() - startTime) * 1000
        }()
        """,
        macros: testMacros
        )
    }

    func testPerformanceMeasureMacro_oneLine() {
        assertMacroExpansion(
        """
        let time = #performanceMeasure { doWork() }
        """,
        expandedSource:
        """
        let time = {
            let startTime = CFAbsoluteTimeGetCurrent()
            doWork()
            return Double(CFAbsoluteTimeGetCurrent() - startTime) * 1000
        }()
        """,
        macros: testMacros
        )
    }

    func testPerformanceMeasureMacro_throwsFunc() {
        assertMacroExpansion(
        """
        let time = #performanceMeasure { 
            do {
                try doWork()
            } catch {
                printError()
            }
        }
        """,
        expandedSource:
        """
        let time = {
            let startTime = CFAbsoluteTimeGetCurrent()
            do {
                try doWork()
            } catch {
                printError()
            }
            return Double(CFAbsoluteTimeGetCurrent() - startTime) * 1000
        }()
        """,
        macros: testMacros
        )
    }

    func testPerformanceMeasureMacro_whenPassedNotClosure() {
        assertMacroExpansion(
        """
        let time = #performanceMeasure("foo")
        """,
        expandedSource:
        """
        let time = #performanceMeasure("foo")
        """,
        diagnostics: [.init(message: "#PerformanceMeasureMacro is waiting for a closure", line: 1, column: 12)],
        macros: testMacros
        )
    }
}
