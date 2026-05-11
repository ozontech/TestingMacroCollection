//
//  TestingMacroCollectionTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(TestingMacroCollection)
    import OzonTestingMacros

    nonisolated(unsafe)
    let testMacros: [String: Macro.Type] = [
        "Mock": MockMacro.self,
        "performanceMeasure": PerformanceMeasureMacro.self,
        "AutoEquatable": AutoEquatableMacro.self,
        "MockAccessor": MockAccessorMacro.self,
        "AnyMockable": AnyMockableMacro.self,
        "Arbitrary": ArbitraryMacro.self,
        "FunctionBodyMock": FunctionBodyMockMacro.self,
    ]
#endif
