//
//  BuildType.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

/// The build type in which the mock is needed.
/// For a debug build, the mock will be wrapped in `#if debug`.
public enum BuildType {
    case debug
    case prod
}
