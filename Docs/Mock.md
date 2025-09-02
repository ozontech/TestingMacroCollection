#  Mock

Mock can generate a mocked class or an actor for the specified protocol. The macro supports actors, `async/await`, `throws` functions, different types, generics, protocol inheritance, initializers, delegates, and `associatedTypes` for protocols.

Example:

```
@Mock(associatedTypes: ["Path": "String"], .public, heritability: .inheritable)
protocol IService: AnyObject {
    associatedtype Path
    
    var path: Path { get set }
    var networkLayer: INetworkLayer? { get set }
    
    func fetchItems(_ page: Int, completion: @escaping (Result<[String], Error>) -> Void)
    func fetchItems(_ page: Int) async throws -> [String]
}
```

As a result, the mock class is generated:

```
public class IServiceMock: IService {
    // MARK: - Typealiases

    typealias Path = String

    // MARK: - path

    public var path: Path {
        get {
            return underlyingPath
        }
        set(value) {
            underlyingPath = value
        }
    }
    public var underlyingPath: Path!

    // MARK: - networkLayer

    public var networkLayer: INetworkLayer?

    // MARK: - Default Empty Init

    public init() {
    }

    // MARK: - Deinit

    public func clearFunctionProperties() {
        fetchItemsPageCompletionReceivedArguments = []
        fetchItemsPageCompletionClosure = nil
        fetchItemsPageReceivedArguments = []
        fetchItemsPageError = nil
        fetchItemsPageClosure = nil
        fetchItemsPageReturnValue = nil
    }

    public func clearVariableProperties() {
        underlyingPath = nil
    }

    deinit {
        clearFunctionProperties()
        clearVariableProperties()
    }

    private let lock = AtomicLock()

    // MARK: - fetchItems

    public func fetchItems(_ page: Int, completion: @escaping (Result<[String], Error>) -> Void) {
        lock.performLockedAction {
            fetchItemsPageCompletionCallsCount += 1
            fetchItemsPageCompletionReceivedArguments.append((page, completion))
        }
        fetchItemsPageCompletionClosure?(page, completion)
    }
    public var fetchItemsPageCompletionCallsCount = 0
    public var fetchItemsPageCompletionReceivedArguments: [(Int, (Result<[String], Error>) -> Void)] = []
    public var fetchItemsPageCompletionClosure: ((Int, @escaping (Result<[String], Error>) -> Void) -> Void)?

    // MARK: - fetchItems

    public func fetchItems(_ page: Int) async throws -> [String] {
        fetchItemsPageCallsCount += 1
        fetchItemsPageReceivedArguments.append(page)
        if let fetchItemsPageError {
            throw fetchItemsPageError
        }
        if let fetchItemsPageClosure {
            return try await fetchItemsPageClosure(page)
        } else {
            return fetchItemsPageReturnValue
        }
    }
    public var fetchItemsPageCallsCount = 0
    public var fetchItemsPageReceivedArguments: [Int] = []
    public var fetchItemsPageError: Error?
    public var fetchItemsPageClosure: ((Int) async throws -> [String])?
    public var fetchItemsPageReturnValue: [String]!
}

```

To operate the generated mock, you can apply input parameters of the macro:

- `associatedTypes` is used if there are associative types in the protocol. To generate `typealias`, specify them in this parameter.

- `accessModifier` is the access modifier for the generated mock. It can be public, open, or internal.

- `heritability` is the status of the mock's heritability. Use `.final` to generate the final class or `.inheritable` to generate a non-final class. It's used only for classes and ignored when generating an actor.


### Restrictions

- It inherits no more than one protocol.
- It doesn't inherit `AnyActor` and other protocols at the same time.
- It's available and isn't stored in closed-source libraries.

If the protocol has at least one restriction, use the `AnyMockable` macro instead.

### Auxiliary macro `@Ignored`

A weak modifier is added to the mock implementation if: 
- the protocol contains a delegate property: `delegate` is mentioned in the property name; 
- the property is optional. 

To ignore the weak modifier generation, add the `@Ignored` macro before this property in the protocol.

Example:

```
@Mock
protocol IService {
    var delegate: Delegate? { get set }
    @Ignored var serviceDelegate: Delegate? { get set }
    var itemDelegate: Delegate { get set }
}
```
In this case, the macro opens as follows:

```
final class IServiceMock: IService {

    // MARK: - delegate

    weak var delegate: Delegate?

    // MARK: - serviceDelegate

    var serviceDelegate: Delegate?

    // MARK: - itemDelegate

    var itemDelegate: Delegate {
        get {
            return underlyingItemDelegate
        }
        set(value) {
            underlyingItemDelegate = value
        }
    }
    var underlyingItemDelegate: Delegate!

    // MARK: - Default Empty Init

    init() {
    }

    // MARK: - Deinit

    func clearVariableProperties() {
        underlyingItemDelegate = nil
    }

    deinit {
        clearVariableProperties()
    }
}

```

### Protocol heritability

If the protocol inherits one other protocol, add the `@Mock` macro to both protocols.

Example:

```
// In module A:

@Mock(.open, heritability: .inheritable)
protocol Parent {
func doWork()
}

// In module B:

@Mock
protocol Child: Parent {
func doAnotherChildWork()
}
```

For the module A, the following mock class will be generated:

```
open class ParentMock: Parent {

    // MARK: - Default Empty Init

    public init() {
    }

    // MARK: - Deinit

    open func clearFunctionProperties() {
        doWorkClosure = nil
    }

    open func clearVariableProperties() {
    }

    deinit {
        clearFunctionProperties()
        clearVariableProperties()
    }

    private let lock = AtomicLock()

    // MARK: - doWork

    open func doWork() {
        lock.performLockedAction {
            doWorkCallsCount += 1
        }
        doWorkClosure?()
    }
    open var doWorkCallsCount = 0
    open var doWorkClosure: (() -> Void)?
}

```

For the module B, a class will be generated that inherits the parent mock class from module A:

```
final class ChildMock: ParentMock, Child {

    // MARK: - Default Empty Init

    override init() {
    }

    // MARK: - Deinit

    override func clearFunctionProperties() {
        super.clearFunctionProperties()
        doAnotherChildWorkClosure = nil
    }

    deinit {
        clearFunctionProperties()
    }

    private let lock = AtomicLock()

    // MARK: - doAnotherChildWork

    func doAnotherChildWork() {
        lock.performLockedAction {
            doAnotherChildWorkCallsCount += 1
        }
        doAnotherChildWorkClosure?()
    }
    var doAnotherChildWorkCallsCount = 0
    var doAnotherChildWorkClosure: (() -> Void)?
}

```

If the parent protocol was stored in another module, specify the `accessModifier- .open` parameter, and the `- .inheritable` heritability. This generates a non-final open class.
