/// Runtime-configurable rule thresholds.
///
/// Set once per engine process from CLI flags, which the `swift-skim`
/// wrapper populates from the project's `.swiftlint.yml` (a `swift_skim:` block).
/// Defaults match the long-standing built-in values, so a project with no config
/// behaves exactly as before.
///
/// Safe as process-global mutable state: the wrapper spawns one engine process
/// per file, so there is no concurrent writer.
public enum RuleConfig {
    /// `skimmable_body`: maximum lines in a View/ViewModifier body (default 15).
    public static var skimmableBodyMaxLines = 15

    /// `excessive_nesting`: maximum nesting depth before a violation (default 3).
    public static var excessiveNestingMaxDepth = 3
}
