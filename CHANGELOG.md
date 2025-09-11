# Version History

# 3.0.1

## Technical changes

- Renamed the Macro target TestingMacros to OzonTestingMacros.
- Ran swiftformat.

# 3.0.0

## Added

- `@FunctionBodyMock` macro for automatic method call proxying to the internal `Mock()` class in `@AnyMockable`. 
This is a helper macro and shouldn't be called manually.

- `@Nilable` macro for generating nil default values in @Arbitrary macro. 
Can only be applied to optional and force-unwrapped properties.

- `.Arbitrary()` method implementation for `Int64`.

## Technical changes

- Bumped Swift version requirement to 6.0.
- Minimum swift-syntax version increased to 600.0.0.
- Added strict-concurrency support for `@Mock` and `@AnyMockable`.

# 2.1.0

## Added

- Ability to add `@Arbitrary(.dynamic)` to the exceptions.
- Default value generation for properties in `@Mock` and `@AnyMockable`: standard types, collections, and tuples.
- Generic type support in `@Mock` and `@AnyMockable`.

# 2.0.3

## Fixed

- `Sendable` protocol support in `MockMacro`.

# 2.0.2

## Added

- Default value generation for Swift or Foundation types and closures in the `Arbitrary` macro.

# 2.0.1

## Added

- Full nested type path generation for properties in the `Arbitrary` macro. For example, `One.Two.Three`.

# 2.0.0

## Added

- `Mock` now generates initializers if defined in the protocol.
- Actor support in `Mock`. Property setters are now generated for mutable properties.
- API Mock change: replaced `shouldBeInherited` parameter with `inheritability`.
- Removed `Foundation` import requirement for `Mock` or `AnyMockable` macros.
- `Mock` automatically applies weak modifier to delegate properties. Use `@Ignored` macro to override.
- Added new README and GitLab wiki.

## Fixed

- `Arbitrary` now correctly generates default values for `Bool`.
- Fixed return value type generation of `some` or `any` in `Mock` and `AnyMockable`.
