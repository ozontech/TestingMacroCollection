# TestingMacroCollection

<img src="/Assets/TestingMacroCollection-logo.png" width="256" height="256">

  
A tool for native generation of template code for testing in Swift.

##  Overview

Learn more about the tool in Wiki.

## Performance

Starting with Xcode 16.4 (16F6) and Swift 6.1.1, you can use the prebuilt version of swift-syntax.
To enable it, use the
`defaults write com.apple.dt.Xcode IDEPackageEnablePrebuilts YES` command or the `--enable-experimental-prebuilts` parameter for CI builds.  

The build time without cache for `TestingMacroCollection` is reduced by approximately 4x. 

## Requirements

TestingMacroCollection supports SPM, which is the recommended option. Xcode 15.0 and higher is required.

## Languages and Versions

<p align="left">
<img src="https://img.shields.io/badge/iOS-13.0-lightgrey.svg">
<img src="https://img.shields.io/badge/Swift-6.0-orange.svg">
</p>

## Version changes

Learn more in [Changelog](CHANGELOG.md).

## Documentation

[Mock](Docs/Mock.md)  
[AnyMockable](Docs/AnyMockable.md)  
[Arbitrary](Docs/Arbitrary.md)  
[AutoEquatable](Docs/AutoEquatable.md)  
[PerformanceMeasure](Docs/PerformanceMeasure.md)  

# Installation and build

TestingMacroCollection supports SPM, which is the recommended option. Xcode 15.0 and higher is required.
