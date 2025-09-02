#  Arbitrary

The `Arbitrary` macro generates an enum with the `Arbitrary` method inside, which returns the object of the declaration it's attached to. The macro can be attached to structures, classes, actors, and protocols. The macro inside recursively calls the `.arbitrary()` method. You can call the macro with the `.dynamic` and `.static` arguments. When using: - the `.static` argument, some `Foundation` types remain the same; - the `.dynamic` argument, the types generate different values. The `.static` argument is used by default.

The macro also additionally generates a separated initializer if necessary.

```
@Arbitrary(.dynamic)
public struct Model {
    let int: Int
    let string: String
    let otherModel: OtherModel

    /// Generated initializer
    public init(int: Int, string: String, otherModel: OtherModel) {
        self.int = int
        self.string = string
        self.otherModel = otherModel
    }
}

/// Generated enum
public enum ModelArbitrary {
    public static func arbitrary(
        int: Int = .arbitrary(.dynamic), 
        string: String = .arbitrary(.dynamic), 
        otherModel: OtherModel = OtherModelArbitrary.arbitrary()
    ) -> Model {
        Model(int: int, string: string, otherModel: otherModel)
    }
}

```

### `Arbitrary` for protocols
The `Arbitrary` macro should be attached to the protocol together with the `@Mock` macro, since Mock is used to create the declaration object.
Example with the protocol:

```
@Mock
@Arbitrary
protocol Service {
    var otherService: OtherService { get set }
}

/// Generated enum
enum ServiceArbitrary {
    static func arbitrary(otherService: OtherService = OtherServiceArbitrary.arbitrary()) -> Service {
        let mock = ServiceMock()
        mock.otherService = otherService
        return mock
    }
}

```

### `@Ignored` macro
The `Ignored` auxiliary macro is used to indicate properties for which you don't need to generate a value.

Example with `@Ignored`:

```
class Object {}

enum Enumeration { }

class Wrapper<T: AnyObject> {
    weak var wrapped: T?
}

@Arbitrary
class Model {
    let id: UUID
    @Ignored let enumeration: Enumeration
    @Ignored let wrappedObject: Wrapper<Object>
    
    /// Generated initializer
    init(id: UUID, enumeration: Enumeration, wrappedObject: Wrapper<Object>) {
        self.id = id
        self.enumeration = enumeration
        self.wrappedObject = wrappedObject
    }
} 

/// Generated enum
enum ModelArbitrary {
    static func arbitrary(id: UUID = .arbitrary(), enumeration: Enumeration, wrappedObject: Wrapper<Object>) -> Model {
        Model(id: id, enumeration: enumeration, wrappedObject: wrappedObject)
    }
}

```

The `Arbitrary` macro doesn't support enum. For enum properties, use the `@Ignored` macro.
