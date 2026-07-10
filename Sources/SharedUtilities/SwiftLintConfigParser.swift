import Foundation

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
