import Foundation

/// Errors that can occur during config discovery
public enum ConfigDiscoveryError: LocalizedError {
    case multipleConfigsFound([URL])
    case noConfigFound
    case sharedConfigMissing(URL)
    case targetNotFound(URL)

    public var errorDescription: String? {
        switch self {
        case .multipleConfigsFound(let urls):
            return "Multiple config files found: \(urls.map { $0.lastPathComponent }.joined(separator: ", "))"
        case .noConfigFound:
            return "No config file found"
        case .sharedConfigMissing(let url):
            return "Shared config file missing: \(url.path)"
        case .targetNotFound(let url):
            return "Target not found: \(url.path)"
        }
    }
}

/// Configuration discovery for Swift quality tools
public struct ConfigDiscovery {
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
            var foundConfigs: [URL] = []
            for configName in configNames {
                let configURL = currentURL.appendingPathComponent(configName)
                if fileManager.fileExists(atPath: configURL.path) {
                    foundConfigs.append(configURL)
                }
            }

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
}
