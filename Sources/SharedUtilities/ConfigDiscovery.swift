import Foundation

/// Errors that can occur during config discovery
public enum ConfigDiscoveryError: LocalizedError {
    case multipleConfigsFound([URL])
    case noConfigFound
    case sharedConfigMissing(URL)
    case targetNotFound(URL)

    public var errorDescription: String? {
        switch self {
        case let .multipleConfigsFound(urls):
            "Multiple config files found: \(urls.map(\.lastPathComponent).joined(separator: ", "))"
        case .noConfigFound:
            "No config file found"
        case let .sharedConfigMissing(url):
            "Shared config file missing: \(url.path)"
        case let .targetNotFound(url):
            "Target not found: \(url.path)"
        }
    }
}

/// Configuration discovery for Swift quality tools
public enum ConfigDiscovery {
    /// Path to swift-quality-tools directory
    private static let toolsPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Developer")
        .appendingPathComponent("swift-quality-tools")

    /// Find config file with smart discovery
    ///
    /// Discovery order:
    /// 1. Check current directory for config files (error if multiple found)
    /// 2. Walk up directory tree until config found
    /// 3. Fall back to shared config in swift-quality-tools
    ///
    /// - Parameters:
    ///   - configNames: List of config file names to search for (e.g., [".swiftformat.yml", ".swiftformat"])
    ///   - sharedConfigName: Name of shared config file in swift-quality-tools/Configs/
    ///   - explicitConfig: Explicitly provided config path (overrides discovery)
    /// - Returns: URL of config file to use
    /// - Throws: ConfigDiscoveryError if no valid config found
    public static func findConfig(
        configNames: [String],
        sharedConfigName: String,
        explicitConfig: URL? = nil
    ) throws -> URL {
        // If explicit config provided, validate and return it
        if let explicit = explicitConfig {
            guard FileManager.default.fileExists(atPath: explicit.path) else {
                throw ConfigDiscoveryError.noConfigFound
            }
            Console.info("Using explicit config: \(explicit.path)")
            return explicit
        }

        // Search for config files in current directory and walk up tree
        if let foundConfig = try searchDirectoryTree(for: configNames) {
            Console.info("Found config: \(foundConfig.path)")
            return foundConfig
        }

        // Fall back to shared config
        let sharedConfig = toolsPath
            .appendingPathComponent("Configs")
            .appendingPathComponent(sharedConfigName)

        guard FileManager.default.fileExists(atPath: sharedConfig.path) else {
            throw ConfigDiscoveryError.sharedConfigMissing(sharedConfig)
        }

        Console.info("Using shared config: \(sharedConfig.path)")
        return sharedConfig
    }

    /// Search directory tree for config files
    ///
    /// Walks up from current directory to root, looking for config files.
    /// Throws error if multiple configs found in same directory.
    ///
    /// - Parameter configNames: List of config file names to search for
    /// - Returns: URL of config file if found, nil otherwise
    /// - Throws: ConfigDiscoveryError.multipleConfigsFound if multiple configs in same directory
    private static func searchDirectoryTree(for configNames: [String]) throws -> URL? {
        let fileManager = FileManager.default
        var currentDir = fileManager.currentDirectoryPath

        while currentDir != "/" {
            let currentURL = URL(fileURLWithPath: currentDir)

            // Check for all config names in current directory
            let foundConfigs = configNames
                .map { currentURL.appendingPathComponent($0) }
                .filter { fileManager.fileExists(atPath: $0.path) }

            // If multiple configs found, error
            if foundConfigs.count > 1 {
                throw ConfigDiscoveryError.multipleConfigsFound(foundConfigs)
            }

            // If single config found, return it
            if let foundConfig = foundConfigs.first {
                return foundConfig
            }

            // Move up one directory
            currentDir = (currentURL.deletingLastPathComponent().path)
        }

        return nil
    }

    /// Validate that a target path exists
    ///
    /// - Parameter target: URL of target file or directory
    /// - Throws: ConfigDiscoveryError.targetNotFound if target doesn't exist
    public static func validateTarget(_ target: URL) throws {
        guard FileManager.default.fileExists(atPath: target.path) else {
            throw ConfigDiscoveryError.targetNotFound(target)
        }
    }

    /// Get path to custom rule engine executable
    public static var customRuleEnginePath: URL {
        toolsPath
            .appendingPathComponent("CustomRules")
            .appendingPathComponent("swiftlint-swiftsyntax-integration")
            .appendingPathComponent("rule-engine")
            .appendingPathComponent(".build")
            .appendingPathComponent("debug")
            .appendingPathComponent("test-custom-rule")
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
    public static func readSwiftLintExclusions(configPath: URL? = nil) -> [String] {
        // Try to find SwiftLint config
        let config: URL
        if let explicitConfig = configPath {
            config = explicitConfig
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
        exclusions: inout [String]
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
