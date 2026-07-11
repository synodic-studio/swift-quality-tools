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
    private static func searchDirectoryTreeForSwiftLintConfig() -> URL? {
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
                return parseExclusions(from: foundConfig)
            }

            // No config found, return default exclusions
            return [
                ".build",
                "build",
                "Frameworks",
                "DerivedData",
            ]
        }

        return parseExclusions(from: config)
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

    /// Parse exclusion patterns from SwiftLint config file
    private static func parseExclusions(from config: URL) -> [String] {
        // Read and parse the YAML file
        guard let contents = try? String(contentsOf: config, encoding: .utf8) else {
            return []
        }

        var exclusions: [String] = []
        var inExcludedSection = false

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Check if we're entering the excluded section
            if trimmed.hasPrefix("excluded:") {
                inExcludedSection = true
                continue
            }

            // If we're in the excluded section
            guard inExcludedSection else { continue }
            inExcludedSection = handleExcludedSection(line: line, trimmed: trimmed, exclusions: &exclusions)
        }

        return exclusions
    }

    /// Handle a line in the excluded section of SwiftLint config
    /// - Parameters:
    ///   - line: The full line from the config file
    ///   - trimmed: The trimmed version of the line
    ///   - exclusions: Array to append exclusion patterns to
    /// - Returns: True if still in excluded section, false if exited
    private static func handleExcludedSection(
        line: String,
        trimmed: String,
        exclusions: inout [String],
    ) -> Bool {
        // Check if this line starts a new top-level section
        if !line.isEmpty, !line.first!.isWhitespace, trimmed.contains(":") {
            return false // Exited excluded section
        }

        // Extract exclusion pattern (lines starting with - in the excluded section)
        if trimmed.hasPrefix("- ") {
            let pattern = trimmed
                .dropFirst(2) // Remove "- "
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) // Remove quotes
            if !pattern.isEmpty {
                exclusions.append(pattern)
            }
        }

        return true // Still in excluded section
    }
}
