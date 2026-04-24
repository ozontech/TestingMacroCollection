//
//  TestingMacroCollectionPlugin.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

import Foundation
import SwiftCompilerPlugin
import SwiftSyntaxMacros

@available(macOS 13.0, *)
@main
struct TestingMacroCollectionPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        MockMacro.self,
        PerformanceMeasureMacro.self,
        AutoEquatableMacro.self,
        AnyMockableMacro.self,
        MockAccessorMacro.self,
        FunctionBodyMockMacro.self,
        IgnoredMacro.self,
        NilableMacro.self,
        EmptedMacro.self,
        ArbitraryMacro.self,
        ArbitraryDefaultCaseMacro.self,
    ]
}
