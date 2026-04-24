# Version History

# 3.1.0

## Added

- Added support for enumerations by the `@Arbitrary` macro. For the .static generation type, the case marked with `@ArbitraryEnumStaticCase` is used. For .dynamic — a random one.

- Implemented the auxiliary `@ArbitraryEnumStaticCase` macro, which helps the @Arbitrary macro choose an enumeration case for the static generation type.

- Added generation of an extension with the static .arbitrary() function by the Arbitrary macro.

- Added the auxiliary `@Empted` macro for generating an empty collection by default in the `@Arbitrary` macro.

- The `@Empted` macro can only be attached to `Array` and `Set`.

- Removed redundant generation of default in switch for an enum with a single case in the `@AutoEquatable` macro.

- The `accessModifier` parameter for the `@Arbitrary` macro.

- Support for typed errors in methods with throws for mocks.

- Support for the `@available` attribute for `@Mock` properties and methods.

## Technical changes

- Added support for method overloading for `@Mock` and `@AnyMockable`.

- Raised the lower bound of `swift-syntax` to 601.0.0.

- `@Mock` and `@Arbitrary` macros are wrapped in `#if DEBUG ... #endif`.

## Fixed

- Implemented ignoring of computed properties of models in the `@Arbitrary` macro.

- The return value of a nested Enum inside an extension of the `@Arbitrary` macro.

- Fixed generation of arbitrary for deeply nested types (e.g., One.Two.Three) in the `@Arbitrary` macro.

- Support for a generic type inside a generic clause `Result<T, Error>`.

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
