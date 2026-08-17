import Foundation

/// Configurable custom-rule thresholds, read from a `swiftskim:` block in
/// `.swiftlint.yml`. A `nil` field means "use the engine default".
public struct RuleThresholds: Sendable, Equatable {
    public var skimmableBodyMaxLines: Int?
    public var excessiveNestingMaxDepth: Int?

    public init(skimmableBodyMaxLines: Int? = nil, excessiveNestingMaxDepth: Int? = nil) {
        self.skimmableBodyMaxLines = skimmableBodyMaxLines
        self.excessiveNestingMaxDepth = excessiveNestingMaxDepth
    }

    /// Flags to pass to the rule engine; empty when nothing is overridden.
    public var engineArguments: [String] {
        var args: [String] = []
        if let skimmableBodyMaxLines {
            args += ["--skimmable-body-max", String(skimmableBodyMaxLines)]
        }
        if let excessiveNestingMaxDepth {
            args += ["--nesting-max-depth", String(excessiveNestingMaxDepth)]
        }
        return args
    }
}

/// Parser for SwiftLint configuration files
public enum SwiftLintConfigParser {
    /// Find SwiftLint config file in a directory
    private static func findSwiftLintConfig(in directory: URL, fileManager: FileManager) -> URL? {
        for configName in [".swiftlint.yml", ".swiftlint.yaml"] {
            let configURL = directory.appendingPathComponent(configName)
            if fileManager.fileExists(atPath: configURL.path) {
                return configURL
            }
        }
        return nil
    }

    /// Search directory tree for SwiftLint config file
    public static func searchDirectoryTreeForSwiftLintConfig() -> URL? {
        let fileManager = FileManager.default
        var currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        for _ in 0 ..< 10 {
            if let foundConfig = findSwiftLintConfig(in: currentDir, fileManager: fileManager) {
                return foundConfig
            }

            let parent = currentDir.deletingLastPathComponent()
            guard parent.path != currentDir.path else {
                break // Reached root
            }
            currentDir = parent
        }

        return nil
    }

    /// Exclusions applied when no config file can be found.
    public static let defaultExclusions = [
        ".build",
        "build",
        "Frameworks",
        "DerivedData",
    ]

    /// Read exclusion patterns from SwiftLint configuration file
    /// - Parameter configPath: Path to SwiftLint config file (optional)
    /// - Returns: Array of exclusion patterns found in the config
    public static func readExclusions(configPath: URL? = nil) -> [String] {
        // Try to find SwiftLint config
        let config: URL
        if let configPath {
            config = configPath
        } else {
            // Try to find SwiftLint config in current directory or parent directories
            if let foundConfig = searchDirectoryTreeForSwiftLintConfig() {
                return YAMLPathList.parse(section: "excluded:", from: foundConfig)
            }

            return defaultExclusions
        }

        return YAMLPathList.parse(section: "excluded:", from: config)
    }

    /// Read `included:` patterns from a SwiftLint configuration file.
    ///
    /// An empty result means the config places no inclusion filter on linting.
    /// - Parameter configPath: Path to SwiftLint config file (optional)
    public static func readInclusions(configPath: URL? = nil) -> [String] {
        guard let config = configPath ?? searchDirectoryTreeForSwiftLintConfig() else {
            return []
        }
        return YAMLPathList.parse(section: "included:", from: config)
    }

    /// Read custom-rule thresholds from a `swiftskim:` block in the config.
    /// - Parameter configPath: Explicit config path, or nil to discover one.
    /// - Returns: Thresholds with only the overridden fields set.
    public static func readThresholds(configPath: URL? = nil) -> RuleThresholds {
        let config: URL
        if let configPath {
            config = configPath
        } else if let found = searchDirectoryTreeForSwiftLintConfig() {
            config = found
        } else {
            return RuleThresholds()
        }
        return parseThresholds(from: config)
    }

    /// Parse the `swiftskim:` threshold block from a config file.
    private static func parseThresholds(from config: URL) -> RuleThresholds {
        guard let contents = try? String(contentsOf: config, encoding: .utf8) else {
            return RuleThresholds()
        }

        var thresholds = RuleThresholds()
        var inSection = false

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("swiftskim:") {
                inSection = true
                continue
            }
            guard inSection else { continue }

            // A new non-indented key ends the block.
            if !line.isEmpty, !line.first!.isWhitespace, trimmed.contains(":") {
                break
            }
            applyThresholdLine(trimmed, to: &thresholds)
        }

        return thresholds
    }

    /// Apply one `key: value` line from the `swiftskim:` block.
    private static func applyThresholdLine(_ trimmed: String, to thresholds: inout RuleThresholds) {
        let parts = trimmed.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2, let value = Int(parts[1]) else { return }

        switch parts[0] {
        case "skimmable_body_max_lines": thresholds.skimmableBodyMaxLines = value
        case "excessive_nesting_max_depth": thresholds.excessiveNestingMaxDepth = value
        default: break
        }
    }
}
