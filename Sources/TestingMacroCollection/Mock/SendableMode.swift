/// Mode for generating `@unchecked Sendable` mocks.
public enum SendableMode {
    /// Auto-detects if generation is needed.
    case auto
    /// Enables generation by default.
    case enabled
    /// Disables generation.
    case disabled
}
