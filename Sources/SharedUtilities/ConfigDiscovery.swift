import Foundation

/// Configuration discovery for Swift quality tools
public enum ConfigDiscovery {
    /// Filename of the rule-engine executable.
    static let engineBinaryName = "swiftskim-engine"

    /// Directory containing the currently running executable (symlinks resolved).
    private static var executableDirectory: URL {
        let path = Bundle.main.executablePath ?? CommandLine.arguments.first ?? ""
        return URL(fileURLWithPath: path).resolvingSymlinksInPath().deletingLastPathComponent()
    }

    /// Root directory holding bundled resources (`Configs/`, the rule engine).
    ///
    /// Resolved without hardcoding any machine path, so the tool stands on its own
    /// wherever it is installed:
    /// 1. `SWIFTSKIM_HOME` if set (explicit override).
    /// 2. Walk up from the executable to the nearest ancestor containing
    ///    `Configs/shared-swiftlint.yml` (covers dev `.build/release` and installs
    ///    that place `Configs/` relative to the binary).
    /// 3. Legacy fallback to the historical dev checkout.
    static var resourcesRoot: URL {
        let fileManager = FileManager.default

        if let override = ProcessInfo.processInfo.environment["SWIFTSKIM_HOME"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        var directory = executableDirectory
        for _ in 0 ..< 8 {
            let marker = directory.appendingPathComponent("Configs/shared-swiftlint.yml")
            if fileManager.fileExists(atPath: marker.path) {
                return directory
            }
            let parent = directory.deletingLastPathComponent()
            guard parent.path != directory.path else { break }
            directory = parent
        }

        return fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Developer")
            .appendingPathComponent("swift-quality-tools")
    }

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
        explicitConfig: URL? = nil,
    ) throws -> URL {
        // If explicit config provided, validate and return it
        if let explicitConfig {
            guard FileManager.default.fileExists(atPath: explicitConfig.path) else {
                throw ConfigDiscoveryError.noConfigFound
            }
            Console.info("Using explicit config: \(explicitConfig.path)")
            return explicitConfig
        }

        // Search for config files in current directory and walk up tree
        if let foundConfig = try searchDirectoryTree(for: configNames) {
            Console.info("Found config: \(foundConfig.path)")
            return foundConfig
        }

        // Fall back to shared config
        let sharedConfig = resourcesRoot
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

    /// Get path to custom rule engine executable.
    ///
    /// 1. `SWIFTSKIM_ENGINE` if set (explicit override).
    /// 2. Beside the running executable (installed layout).
    /// 3. The engine's own build dir under the resources root (dev layout).
    public static var customRuleEnginePath: URL {
        if let override = ProcessInfo.processInfo.environment["SWIFTSKIM_ENGINE"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let sibling = executableDirectory.appendingPathComponent(engineBinaryName)
        if FileManager.default.isExecutableFile(atPath: sibling.path) {
            return sibling
        }

        return resourcesRoot
            .appendingPathComponent("CustomRules")
            .appendingPathComponent("swiftlint-swiftsyntax-integration")
            .appendingPathComponent("rule-engine")
            .appendingPathComponent(".build")
            .appendingPathComponent("release")
            .appendingPathComponent(engineBinaryName)
    }

    /// Read exclusion patterns from SwiftLint configuration file
    /// - Parameter configPath: Path to SwiftLint config file (optional)
    /// - Returns: Array of exclusion patterns found in the config
    public static func readSwiftLintExclusions(configPath: URL? = nil) -> [String] {
        SwiftLintConfigParser.readExclusions(configPath: configPath)
    }

    /// Read custom-rule thresholds (`swiftskim:` block) from the SwiftLint config.
    public static func readRuleThresholds(configPath: URL? = nil) -> RuleThresholds {
        SwiftLintConfigParser.readThresholds(configPath: configPath)
    }
}
