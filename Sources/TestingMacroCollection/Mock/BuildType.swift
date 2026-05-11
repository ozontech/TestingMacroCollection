//
//  BuildType.swift
//  TestingMacroCollection
//
//  Copyright © 2026 Ozon. All rights reserved.
//

/// The build type where the mock is needed.
/// For debug builds, the mock is wrapped in `#if debug`.
public enum BuildType {
    case debug
    case prod
}
