/// Macro to generate mocks for protocols.
/// Generates a class or actor with a mock implementation of a protocol.
/// It can generate methods with call count tracking, adding fake method implementation, mock `returnValue`, mock error.
///
/// You can add the `associatedType` macro using the macro initializer.
/// The `typealias` functions for these types will be generated.
/// You can specify the `accessModifier` of a mock via the `.public` or `.open` `accessModifier` parameter.
/// `.internal` is set by default.
/// To create a non-final mock class, specify the `heritability: .inheritable` parameter.
/// `.final` is set by default.
///
/// The macro also generates static default values for properties via `defaultValue`.
///
///     @Mock(associatedType: ["Input": "String"], .open, heritability: .inheritable)
///     protocol IService: AnyObject {
///         associatedType Input
///         associatedType Output
///
///         var name: String { get set }
///
///         func makeWork(input: Input)
///         func download() async throws -> Output
///     }
///
/// The macro supports the `async` and `throws` methods.
///
/// - Parameters:
///    - associatedTypes: mock's associated types.
///    - accessModifier: access modifier for the mock entity and its methods or properties.
///    - heritability: mock's heritability. Can be inherited or `final'.
///    - sendableMode: sendable mock generation mode.
///    - defaultValue: default value generation for non-optional properties. Default: `.static`.
/// - buildType: build type where the mock is needed. For `.debug` builds, the mock is wrapped in `#if debug`.
/// Defaults to `debug`.
///
@attached(peer, names: suffixed(Mock))
public macro Mock(
    associatedTypes: [String: String] = [:],
    _ accessModifier: AccessModifier = .internal,
    heritability: Heritability = .final,
    sendableMode: SendableMode = .auto,
    defaultValue: DefaultValue = .static,
    buildType: BuildType = .debug
) = #externalMacro(
    module: "OzonTestingMacros",
    type: "MockMacro"
)

/// Macro to generate mocks for any protocols.
/// Applies in case of multiple protocol inheritance, protocol inheritance for `AnyActor`, or protocol storage in an inaccessible
/// location.
/// The macro automatically adds an auxiliary `@MockAccessor` macro to non-optional properties to proxy the `underlying`
/// properties of the `Mock` inner class, а также макрос `@FunctionBodyMock`для генерации проксирования методов мокового класса.
///
///  - Parameter defaultValue: default value generation for non-optional properties. Default: `.static`.
///
///     @AnyMockable(defaultValue: .static)
///     final class ServiceMock: IService {
///
///         var path: String
///
///         func makeWork() { // Generated code }
///
///         // Generated code
///
///         let mock = Mock()
///
///         final class Mock {
///             // MARK: - path
///
///             var underlyingPath: String!
///
///             private let lock = AtomicLock()
///
///             // MARK: - makeWork
///
///             fileprivate func makeWork() {
///                 lock.performLockedAction {
///                     makeWorkCallsCount += 1
///                 }
///                 makeWorkClosure?()
///             }
///             var makeWorkCallsCount = 0
///             var makeWorkClosure: (() -> Void)?
///         }
///     }
///
@attached(member, names: arbitrary)
@attached(memberAttribute)
@attached(extension, conformances: ProxyableMock)
public macro AnyMockable(defaultValue: DefaultValue = .static) = #externalMacro(
    module: "OzonTestingMacros",
    type: "AnyMockableMacro"
)

/// An auxiliary macro for the `AnyMockable` macro.
/// Generates a getter and setter for the property, proxying the generated `Mock` class instance.
///
///     @MockAccessor
///     var path: String {
///        get {                        // Generated code
///            mock.path                // Generated code
///        }                            // Generated code
///        set(newValue) {              // Generated code
///            mock.path = newValue     // Generated code
///        }                            // Generated code
///     }
///
@attached(accessor)
public macro MockAccessor() = #externalMacro(
    module: "OzonTestingMacros",
    type: "MockAccessorMacro"
)

/// An auxiliary macro for the `AnyMockable` macro.
/// Proxies method calls from the inner `Mock` class.
///
///     @FunctionBodyMock
///     func testFuction(arg1: String, some arg2: String, _ arg3: String) async throws -> [String] {
///         try await mock.testFunctino(arg1: arg1, some: arg2, arg3) // Generated code
///     }
///
@attached(body)
public macro FunctionBodyMock() = #externalMacro(
    module: "OzonTestingMacros",
    type: "FunctionBodyMockMacro"
)

/// A macro for measuring the block execution time in milliseconds.
///
///     let time = #performanceMeasure {
///         doWork()
///     }
///     print("Execution time: \(time) ms.")
///
/// - Parameter closure: a block of code for measuring the execution speed.
/// - Returns: the execution time of a block of code in milliseconds.
///
@freestanding(expression)
public macro performanceMeasure(_ closure: () throws -> Void) -> Double = #externalMacro(
    module: "OzonTestingMacros",
    type: "PerformanceMeasureMacro"
)

/// Macro for the automatic conformation of the `Equatable` protocol.
/// Automatically makes an `extension` to the attached declaration and
/// implements the `== (lhs:_, rhs:_)` method.
///
/// Works with classes, actors, structures, and enumerations.
///
/// ```
/// @AutoEquatable
/// struct Model {
///  let name: String
///  let id: UUID
///  let age: Int
///  let value: Bool
///
///  static func == (lhs: Model, rhs: Model) -> Bool {      // Generated code
///     ...                                                 // Generated code
///  }                                                      // Generated code
/// }
/// ```
///
@attached(extension, conformances: Equatable, names: named(==))
public macro AutoEquatable() = #externalMacro(module: "OzonTestingMacros", type: "AutoEquatableMacro")

/// Helper macro.
/// When attached to a declaration, signals other macros to ignore this declaration.
///
/// ```
/// @AutoEquatable
/// class ViewModel {
///   let id: String
///   @Ignored
///   weak var delegate: IViewModelDelegate?
/// ```
///
/// In this example, the `AutoEquatable` macro ignores the `delegate`
/// property when implementing the `==` method.
///
@attached(peer)
public macro Ignored() = #externalMacro(module: "OzonTestingMacros", type: "IgnoredMacro")

/// Helper macro.
/// When attached to a declaration, signals other macros to use `nil` as property default.
///
/// ```
/// @Arbitrary
/// class ViewModel {
///   let id: String
///   @Nilable var tapHandler: TapHandler?
/// }
/// ```
///
/// `Arbitrary` generates default `tapHandler: TapHandler? = nil`.
///
@attached(peer)
public macro Nilable() = #externalMacro(module: "OzonTestingMacros", type: "NilableMacro")

/// A macro for generating a stub for the model. Generates an `enum` with an `arbitrary` method inside.
/// A macro can be attached to structures, classes, actors, and protocols. It also generates a default initializer if necessary.
///
///  - Important: to use the `Arbitrary` macro with protocols, add `Mock` to the protocol.
///
/// ```
/// @Arbitrary
/// public struct Model {
///    let id: UUID
///    let name: String
///    let count: Int
///
///    // Generated init.
///    public init(id: UUID, name: String, count: Int) {
///       self.id = id
///       self.name = name
///       self.count = count
///    }
/// }
///
///  // Generated `enum`.
///  public enum ModelArbitrary {
///     public static func arbitrary(id: UUID = .arbitrary(), name: String = .arbitrary(.static), count: Int =
/// .arbitrary(.static)) -> Model {
///         Model(id: id, name: name, count: count)
///     }
///  }
///
///  /// Generated `extension`:
///  extension Model {
///     public static func arbitrary(id: UUID = .arbitrary(), name: String = .arbitrary(.static), count: Int =
///  .arbitrary(.static) -> Model {
///         Model(id: id, name: name, count: count)
///     }
///  }
/// ```
///
/// -  Parameters:
///   - arbitraryType: the `Arbitrary` type. With `.dynamic` generation, it creates random values for `Foundation` types.
///   - accessModifier: access modifier for the generated enum. Defaults to `auto`, inherits it from the attached type.
///   - buildType: build type. When set to `debug`, the generated `enum` and `extension` are wrapped in `#if DEBUG`.
///     Defaults to `debug`.
///
@attached(peer, names: suffixed(Arbitrary))
@attached(member, names: arbitrary)
@attached(extension, names: named(arbitrary))
public macro Arbitrary(
    _ arbitraryType: ArbitraryType = .static,
    accessModifier: ArbitraryAccessModifier = .auto,
    buildType: BuildType = .debug
) = #externalMacro(
    module: "OzonTestingMacros",
    type: "ArbitraryMacro"
)

/// Auxiliary macro.
/// Specifies the enumeration case `enum` for default value generation with `.static` generation type.
/// Example:
/// ```
/// @Arbitrary
/// enum MyEnum {
///     case a
///     @ArbitraryDefaultCase
///     case b
/// }
/// ```
///
/// Generates:
/// ```
/// enum MyEnumArbitrary {
///     static func arbitrary() -> MyEnum {
///         return .b
///     }
/// }
/// ```
@attached(peer)
public macro ArbitraryDefaultCase() = #externalMacro(
    module: "OzonTestingMacros",
    type: "ArbitraryDefaultCaseMacro"
)

/// The macro does nothing by itself. It is an auxiliary macro that,
/// when attached to a declaration, tells the `Arbitrary` macro to use `[]` for collection property default values.
/// use `[]` — Empty, for the default value of collection properties.
///
/// ```
/// @Arbitrary
/// class ViewModel {
///   let id: String
///   @Empted var array: [String]
/// }
/// ```
///
/// In this example, the `Arbitrary` macro generates a default value for `array: [String] = []`.
/// `array: [String] = []`
@attached(peer)
public macro Empted() = #externalMacro(module: "OzonTestingMacros", type: "EmptedMacro")
