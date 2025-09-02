// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "TestingMacroCollection",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "TestingMacroCollection",
            targets: ["TestingMacroCollection"]
        ),
        .executable(
            name: "TestingMacroCollectionSandbox",
            targets: ["TestingMacroCollectionSandbox"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0" ..< "601.0.1"),
    ],
    targets: [
        .macro(
            name: "TestingMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(name: "TestingMacroCollection", dependencies: ["TestingMacros"]),
        .executableTarget(name: "TestingMacroCollectionSandbox", dependencies: ["TestingMacroCollection"]),
        .testTarget(
            name: "TestingMacroCollectionTests",
            dependencies: [
                "TestingMacroCollection",
                "TestingMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
