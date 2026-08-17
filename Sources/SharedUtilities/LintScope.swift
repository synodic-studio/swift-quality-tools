import Foundation

/// The set of files a lint configuration actually covers.
///
/// SwiftLint applies `included:` / `excluded:` only to files it discovers itself; a path
/// named on the command line is linted with default scope. That makes a file's verdict
/// depend on how it was reached — the same file passes a repo-wide run and blocks a
/// single-file run, which is exactly what a post-edit hook does. `LintScope` closes the
/// gap: the CLI wrappers ask it whether an explicitly named file is in scope and skip it
/// when it is not, so one file always gets one verdict.
public struct LintScope: Sendable, Equatable {
    /// Directory the config's relative `included:` patterns resolve against.
    public let root: URL
    /// `included:` patterns. Empty means "no inclusion filter".
    public let included: [String]
    /// `excluded:` patterns.
    public let excluded: [String]

    public init(root: URL, included: [String] = [], excluded: [String] = []) {
        self.root = root
        self.included = included
        self.excluded = excluded
    }

    /// Read scope from a config file; relative patterns resolve against its directory.
    public static func read(configPath: URL) -> LintScope {
        LintScope(
            root: configPath.deletingLastPathComponent(),
            included: SwiftLintConfigParser.readInclusions(configPath: configPath),
            excluded: SwiftLintConfigParser.readExclusions(configPath: configPath),
        )
    }

    /// Discover the scope from the nearest `.swiftlint.yml`, walking up from the cwd.
    public static func discover() -> LintScope {
        guard let config = SwiftLintConfigParser.searchDirectoryTreeForSwiftLintConfig() else {
            return LintScope(
                root: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                excluded: SwiftLintConfigParser.defaultExclusions,
            )
        }
        return read(configPath: config)
    }

    /// The same scope with the inclusion filter dropped, keeping exclusions.
    public var withoutInclusions: LintScope {
        LintScope(root: root, included: [], excluded: excluded)
    }

    /// Whether `fileURL` falls inside this scope.
    public func covers(_ fileURL: URL) -> Bool {
        let path = Self.normalize(fileURL)
        if excluded.contains(where: { Self.matches(pattern: $0, path: path) }) {
            return false
        }
        guard !included.isEmpty else { return true }
        // A file outside the config's own directory is not something `included:` has an
        // opinion about (a hook may be handed a scratch file while cwd is a project), so
        // cover it rather than silently skipping a lint nobody asked to suppress.
        guard let relative = Self.relativePath(of: path, under: root) else { return true }
        return included.contains { Self.includes(pattern: $0, relativePath: relative) }
    }

    /// Absolute, symlink-resolved path for stable comparison (`/var` vs `/private/var`).
    private static func normalize(_ url: URL) -> String {
        url.resolvingSymlinksInPath().standardizedFileURL.path
    }

    /// `path` relative to `root`, or nil when it is not underneath it.
    private static func relativePath(of path: String, under root: URL) -> String? {
        var rootPath = normalize(root)
        while rootPath.count > 1, rootPath.hasSuffix("/") {
            rootPath.removeLast()
        }
        let prefix = rootPath == "/" ? "/" : rootPath + "/"
        guard path.hasPrefix(prefix) else { return nil }
        return String(path.dropFirst(prefix.count))
    }

    /// Whether an `included:` pattern covers a config-relative path.
    private static func includes(pattern: String, relativePath: String) -> Bool {
        var cleaned = pattern
        while cleaned.hasPrefix("./") {
            cleaned.removeFirst(2)
        }
        while cleaned.count > 1, cleaned.hasSuffix("/") {
            cleaned.removeLast()
        }
        guard !cleaned.isEmpty else { return false }
        if cleaned.contains("*") {
            return matches(pattern: cleaned, path: "/" + relativePath)
        }
        return relativePath == cleaned || relativePath.hasPrefix(cleaned + "/")
    }

    /// Whether an `excluded:`-style pattern matches an absolute path.
    static func matches(pattern: String, path: String) -> Bool {
        if pattern.hasPrefix("**/") {
            let suffix = String(pattern.dropFirst(3))
            return path.contains("/\(suffix)")
        }

        if pattern.hasSuffix("/**") {
            let prefix = String(pattern.dropLast(3))
            return path.contains("/\(prefix)/")
        }

        if pattern.contains("*") {
            let nonWildcard = pattern.replacingOccurrences(of: "*", with: "")
            return path.contains(nonWildcard)
        }

        return path.contains("/\(pattern)/") || path.hasSuffix("/\(pattern)")
    }
}
