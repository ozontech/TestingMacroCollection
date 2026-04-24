//
//  AutoEquatableMacroTests.swift
//  TestingMacroCollection
//
//  Copyright © 2025 Ozon. All rights reserved.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacrosTestSupport
import XCTest

final class AutoEquatableMacroTests: XCTestCase {
    func testAutoEquatableMacro_propertyWithIgnoredMacro() {
        assertMacroExpansion(
        """
        @AutoEquatable
        struct Model {
            @Ignored
            let id: UUID
            let number: Int
            let name: String
        }
        """,
        expandedSource:
        """
        struct Model {
            @Ignored
            let id: UUID
            let number: Int
            let name: String
        }
        
        extension Model: Equatable {
            static func == (lhs: Model, rhs: Model) -> Bool {
                lhs.number == rhs.number && lhs.name == rhs.name
            }
        }
        """,
        macros: testMacros
        )
    }

    func testAutoEquatableMacro_enumWithoutParametersAndOtherVariables() {
        assertMacroExpansion(
        """
        @AutoEquatable
        enum Route {
            case main
            case profile
            case settings
        
            var currentRoute: Route { .main }
            var previousRoute: Route { .profile }
        }
        """,
        expandedSource:
        """
        enum Route {
            case main
            case profile
            case settings
        
            var currentRoute: Route { .main }
            var previousRoute: Route { .profile }
        }
        
        extension Route: Equatable {
            static func == (lhs: Route, rhs: Route) -> Bool {
                let otherVariablesCheck = lhs.currentRoute == rhs.currentRoute && lhs.previousRoute == rhs.previousRoute
                switch (lhs, rhs) {
                case (.main, .main):
                    return otherVariablesCheck
                case (.profile, .profile):
                    return otherVariablesCheck
                case (.settings, .settings):
                    return otherVariablesCheck
                default:
                    return false
                }
            }
        }
        """,
        macros: testMacros
        )
    }

    func testAutoEquatableMacro_enumWithParametersAndOtherVariables() {
        assertMacroExpansion(
        """
        @AutoEquatable
        enum Route {
            case main(viewModel: ViewModel)
            case profile
            case settings
        
            var currentRoute: Route { .main }
            var previousRoute: Route { .profile }
        }
        """,
        expandedSource:
        """
        enum Route {
            case main(viewModel: ViewModel)
            case profile
            case settings
        
            var currentRoute: Route { .main }
            var previousRoute: Route { .profile }
        }
        
        extension Route: Equatable {
            static func == (lhs: Route, rhs: Route) -> Bool {
                let otherVariablesCheck = lhs.currentRoute == rhs.currentRoute && lhs.previousRoute == rhs.previousRoute
                switch (lhs, rhs) {
                case (let .main(lhsViewModel), let .main(rhsViewModel)):
                    return lhsViewModel == rhsViewModel && otherVariablesCheck
                case (.profile, .profile):
                    return otherVariablesCheck
                case (.settings, .settings):
                    return otherVariablesCheck
                default:
                    return false
                }
            }
        }
        """,
        macros: testMacros
        )
    }

    func testAutoEquatableMacro_createExtensionForClass() {
        assertMacroExpansion(
        """
        @AutoEquatable
        class SomeModel {
            let id: String
            let name: String
        
            init(id: String, name: String) {
                self.id = id
                self.name = name
            }
        }
        """,
        expandedSource:
        """
        class SomeModel {
            let id: String
            let name: String
        
            init(id: String, name: String) {
                self.id = id
                self.name = name
            }
        }

        extension SomeModel: Equatable {
            static func == (lhs: SomeModel, rhs: SomeModel) -> Bool {
                lhs.id == rhs.id && lhs.name == rhs.name
            }
        }
        """,
        macros: testMacros
        )
    }

    func testAutoEquatableMacro_createExtensionForStruct() {
        assertMacroExpansion(
        """
        @AutoEquatable
        struct Structure {
            let childModel: Model
            let id: UUID
            let path: String
        }
        """,
        expandedSource:
        """
        struct Structure {
            let childModel: Model
            let id: UUID
            let path: String
        }
        
        extension Structure: Equatable {
            static func == (lhs: Structure, rhs: Structure) -> Bool {
                lhs.childModel == rhs.childModel && lhs.id == rhs.id && lhs.path == rhs.path
            }
        }
        """,
        macros: testMacros
        )
    }

    func testAutoEquatableMacro_createExtensionForEnum() {
        assertMacroExpansion(
        """
        @AutoEquatable
        enum Enumeration {
            case first
            case second(arg: String, arg2: Int)
            case third(path: Array<String>)
            case fourth(_ argument: String, arg: Char)
        }
        """,
        expandedSource:
        """
        enum Enumeration {
            case first
            case second(arg: String, arg2: Int)
            case third(path: Array<String>)
            case fourth(_ argument: String, arg: Char)
        }
        
        extension Enumeration: Equatable {
            static func == (lhs: Enumeration, rhs: Enumeration) -> Bool {
                switch (lhs, rhs) {
                case (.first, .first):
                    return true
                case (let .second(lhsArg, lhsArg2), let .second(rhsArg, rhsArg2)):
                    return lhsArg == rhsArg && lhsArg2 == rhsArg2
                case (let .third(lhsPath), let .third(rhsPath)):
                    return lhsPath == rhsPath
                case (let .fourth(lhsArgument, lhsArg), let .fourth(rhsArgument, rhsArg)):
                    return lhsArgument == rhsArgument && lhsArg == rhsArg
                default:
                    return false
                }
            }
        }
        """,
        macros: testMacros
        )
    }
    
    func testAutoEquatableMacro_enumWithOneCase() {
        assertMacroExpansion(
        """
        @AutoEquatable
        enum Route {
            case main
        }
        """,
        expandedSource:
        """
        enum Route {
            case main
        }
        
        extension Route: Equatable {
            static func == (lhs: Route, rhs: Route) -> Bool {
                switch (lhs, rhs) {
                case (.main, .main):
                    return true
                }
            }
        }
        """,
        macros: testMacros
        )
    }
}
