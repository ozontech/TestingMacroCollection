#  AutoEquatable

The `AutoEquatable` macro allows you to automatically subscribe to the `Equatable` protocol and add it to the extension.
Class example:

```
@AutoEquatable
class Model {
    let name: String
    let id: UUID
    let base: String
}
```

You can expand the macro as:

```
extension Model: Equatable {
    static func == (lhs: Model, rhs: Model) -> Bool {
        lhs.name == rhs.name && lhs.id == rhs.id && lhs.base && rhs.base
    }
}

```

Enum example:

```
@AutoEquatable
enum Enumeration {
    case first
    case second(String, Int)
    case third(arg: String)
    
    var property: Bool {
        .random()
    }
}
```

### `@Ignored` macro

The `@Ignored` auxiliary macro allows you to mark a property as ignored so that it isn't taken into account when checking equivalence.

```
@AutoEquatable
class ViewModel {
    let id: UUID
    let service: ViewModelService
    @Ignored
    weak var delegate: IViewModelDelegate?
}

// Generated code
extension ViewModel: Equatable {
    static func == (lhs: Model, rhs: Model) -> Bool {
        lhs.id == rhs.id && lhs.service == rhs.service
    }
}

```
