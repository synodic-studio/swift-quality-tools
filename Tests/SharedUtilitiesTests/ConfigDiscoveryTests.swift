// swiftlint:disable file_length type_body_length

import Foundation
import Testing

@testable import SharedUtilities

@Suite("ConfigDiscovery Tests")
struct ConfigDiscoveryTests {
    // MARK: - Test Fixtures

    private func createTempDirectory() throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        // Resolve symlinks to avoid /var vs /private/var mismatch on macOS
        return tempDir.resolvingSymlinksInPath()
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func createFile(at url: URL, contents: String = "") throws {
        try contents.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Target Validation Tests

    @Test("Validate target throws error for non-existent path")
    func validateTargetNonExistent() throws {
        let nonExistentPath = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString)")

        #expect(throws: ConfigDiscoveryError.self) {
            try ConfigDiscovery.validateTarget(nonExistentPath)
        }
    }

    @Test("Validate target succeeds for existing file")
    func validateTargetExistingFile() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let testFile = tempDir.appendingPathComponent("test.swift")
        try createFile(at: testFile, contents: "// test")

        #expect(throws: Never.self) {
            try ConfigDiscovery.validateTarget(testFile)
        }
    }

    @Test("Validate target succeeds for existing directory")
    func validateTargetExistingDirectory() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        #expect(throws: Never.self) {
            try ConfigDiscovery.validateTarget(tempDir)
        }
    }

    // MARK: - Explicit Config Tests

    @Test("Find config returns explicit config when provided and exists")
    func explicitConfigExists() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let explicitConfig = tempDir.appendingPathComponent("custom.yml")
        try createFile(at: explicitConfig)

        // Change to temp directory
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }

        let result = try ConfigDiscovery.findConfig(
            configNames: [".swiftformat.yml"],
            sharedConfigName: "shared-swiftformat.yml",
            explicitConfig: explicitConfig,
        )

        #expect(result.path == explicitConfig.path)
    }

    @Test("Find config throws error when explicit config doesn't exist")
    func explicitConfigNotExists() throws {
        let nonExistentConfig = URL(fileURLWithPath: "/tmp/nonexistent-\(UUID().uuidString).yml")

        #expect(throws: ConfigDiscoveryError.noConfigFound) {
            try ConfigDiscovery.findConfig(
                configNames: [".swiftformat.yml"],
                sharedConfigName: "shared-swiftformat.yml",
                explicitConfig: nonExistentConfig,
            )
        }
    }

    // MARK: - Config Discovery Error Tests

    @Test("ConfigDiscoveryError multipleConfigsFound has correct description")
    func multipleConfigsFoundError() {
        let configs = [
            URL(fileURLWithPath: "/path/.swiftformat.yml"),
            URL(fileURLWithPath: "/path/.swiftformat"),
        ]
        let error = ConfigDiscoveryError.multipleConfigsFound(configs)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description!.contains(".swiftformat.yml"))
        #expect(description!.contains(".swiftformat"))
    }

    @Test("ConfigDiscoveryError noConfigFound has correct description")
    func noConfigFoundError() {
        let error = ConfigDiscoveryError.noConfigFound
        let description = error.errorDescription

        #expect(description != nil)
        #expect(description!.contains("No config file found"))
    }

    @Test("ConfigDiscoveryError sharedConfigMissing includes path")
    func sharedConfigMissingError() {
        let missingPath = URL(fileURLWithPath: "/path/to/shared.yml")
        let error = ConfigDiscoveryError.sharedConfigMissing(missingPath)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description!.contains("/path/to/shared.yml"))
    }

    @Test("ConfigDiscoveryError targetNotFound includes path")
    func targetNotFoundError() {
        let targetPath = URL(fileURLWithPath: "/path/to/target")
        let error = ConfigDiscoveryError.targetNotFound(targetPath)

        let description = error.errorDescription
        #expect(description != nil)
        #expect(description!.contains("/path/to/target"))
    }

    // MARK: - Custom Rule Engine Path Tests

    @Test("Custom rule engine path points to correct location")
    func testCustomRuleEnginePath() {
        TestSupport.ensureSwiftskimHome()
        let path = ConfigDiscovery.customRuleEnginePath

        // Collapsed layout: the engine is built by the root package, so its dev
        // fallback path lives in the root `.build/release/`, not a nested package.
        #expect(path.path.contains("swift-quality-tools"))
        #expect(path.path.contains(".build/release"))
        #expect(path.path.contains("swiftskim-engine"))
    }

    @Test("Custom rule engine path is in home directory")
    func customRuleEnginePathInHome() {
        TestSupport.ensureSwiftskimHome()
        let path = ConfigDiscovery.customRuleEnginePath
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path

        #expect(path.path.starts(with: homeDir))
    }

    // MARK: - Directory Tree Search Tests

    @Test("Find config in current directory")
    func findConfigInCurrentDirectory() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        // Create config in temp directory
        let configFile = tempDir.appendingPathComponent(".swiftformat.yml")
        try createFile(at: configFile, contents: "# test config")

        // Change to temp directory
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }

        let result = try ConfigDiscovery.findConfig(
            configNames: [".swiftformat.yml"],
            sharedConfigName: "shared-swiftformat.yml",
        )

        #expect(result.lastPathComponent == ".swiftformat.yml")
        #expect(result.path.contains(tempDir.lastPathComponent))
    }

    @Test("Find config in parent directory")
    func findConfigInParentDirectory() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        // Create config in temp directory
        let configFile = tempDir.appendingPathComponent(".swiftformat.yml")
        try createFile(at: configFile, contents: "# test config")

        // Create subdirectory
        let subDir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

        // Change to subdirectory
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(subDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }

        let result = try ConfigDiscovery.findConfig(
            configNames: [".swiftformat.yml"],
            sharedConfigName: "shared-swiftformat.yml",
        )

        #expect(result.lastPathComponent == ".swiftformat.yml")
        #expect(result.path.contains(tempDir.lastPathComponent))
    }

    @Test("Find config walking up multiple directories")
    func findConfigWalkingUpMultipleLevels() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        // Create config in temp directory
        let configFile = tempDir.appendingPathComponent(".swiftformat.yml")
        try createFile(at: configFile, contents: "# test config")

        // Create nested subdirectories
        let deepDir = tempDir
            .appendingPathComponent("level1")
            .appendingPathComponent("level2")
            .appendingPathComponent("level3")
        try FileManager.default.createDirectory(at: deepDir, withIntermediateDirectories: true)

        // Change to deep subdirectory
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(deepDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }

        let result = try ConfigDiscovery.findConfig(
            configNames: [".swiftformat.yml"],
            sharedConfigName: "shared-swiftformat.yml",
        )

        // Compare standardized paths to handle symlink differences
        let expectedPath = configFile.standardizedFileURL.path
        let actualPath = result.standardizedFileURL.path
        #expect(actualPath == expectedPath, "Expected config at \(expectedPath) but found \(actualPath)")
    }

    @Test("Multiple configs in same directory throws error")
    func multipleConfigsInSameDirectory() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        // Create multiple config files
        try createFile(at: tempDir.appendingPathComponent(".swiftformat.yml"), contents: "# config 1")
        try createFile(at: tempDir.appendingPathComponent(".swiftformat"), contents: "# config 2")

        // Change to temp directory
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }

        #expect(throws: ConfigDiscoveryError.self) {
            try ConfigDiscovery.findConfig(
                configNames: [".swiftformat.yml", ".swiftformat"],
                sharedConfigName: "shared-swiftformat.yml",
            )
        }
    }

    @Test("Prefers closest config when multiple in tree")
    func prefersClosestConfig() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        // Create config in root
        let rootConfig = tempDir.appendingPathComponent(".swiftformat.yml")
        try createFile(at: rootConfig, contents: "# root config")

        // Create subdirectory with its own config
        let subDir = tempDir.appendingPathComponent("subdir")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        let subConfig = subDir.appendingPathComponent(".swiftformat.yml")
        try createFile(at: subConfig, contents: "# sub config")

        // Change to subdirectory
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(subDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }

        let result = try ConfigDiscovery.findConfig(
            configNames: [".swiftformat.yml"],
            sharedConfigName: "shared-swiftformat.yml",
        )

        // Should find the config in subdir, not the parent
        // Resolve both paths to handle /var vs /private/var symlink on macOS
        #expect(result.path.hasSuffix("subdir/.swiftformat.yml"))
        #expect(!result.path.hasSuffix(tempDir.lastPathComponent + "/.swiftformat.yml"))
    }

    // MARK: - SwiftLint Exclusion Parsing Tests

    @Test("readSwiftLintExclusions parses basic exclusions")
    func readSwiftLintExclusionsBasic() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let configContent = """
        excluded:
          - .build
          - DerivedData
          - Frameworks
        """

        let configFile = tempDir.appendingPathComponent(".swiftlint.yml")
        try createFile(at: configFile, contents: configContent)

        let exclusions = ConfigDiscovery.readSwiftLintExclusions(configPath: configFile)

        #expect(exclusions.contains(".build"))
        #expect(exclusions.contains("DerivedData"))
        #expect(exclusions.contains("Frameworks"))
        #expect(exclusions.count == 3)
    }

    @Test("readSwiftLintExclusions handles quoted patterns")
    func readSwiftLintExclusionsQuoted() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let configContent = """
        excluded:
          - ".build"
          - 'DerivedData'
          - "Frameworks"
        """

        let configFile = tempDir.appendingPathComponent(".swiftlint.yml")
        try createFile(at: configFile, contents: configContent)

        let exclusions = ConfigDiscovery.readSwiftLintExclusions(configPath: configFile)

        #expect(exclusions.contains(".build"))
        #expect(exclusions.contains("DerivedData"))
        #expect(exclusions.contains("Frameworks"))
    }

    @Test("readSwiftLintExclusions handles multiple sections")
    func readSwiftLintExclusionsMultipleSections() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let configContent = """
        disabled_rules:
          - line_length
          - trailing_whitespace

        excluded:
          - .build
          - DerivedData

        opt_in_rules:
          - empty_count
        """

        let configFile = tempDir.appendingPathComponent(".swiftlint.yml")
        try createFile(at: configFile, contents: configContent)

        let exclusions = ConfigDiscovery.readSwiftLintExclusions(configPath: configFile)

        #expect(exclusions.contains(".build"))
        #expect(exclusions.contains("DerivedData"))
        #expect(!exclusions.contains("line_length"))
        #expect(!exclusions.contains("empty_count"))
    }

    @Test("readSwiftLintExclusions returns defaults when no config found")
    func readSwiftLintExclusionsDefaults() throws {
        // Create temp directory with no config file
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        // Change to directory with no config
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
        defer { FileManager.default.changeCurrentDirectoryPath(originalDir) }

        let exclusions = ConfigDiscovery.readSwiftLintExclusions()

        // Should return default exclusions
        #expect(exclusions.contains(".build"))
        #expect(exclusions.contains("build"))
        #expect(exclusions.contains("Frameworks"))
        #expect(exclusions.contains("DerivedData"))
    }

    @Test("readSwiftLintExclusions handles empty excluded section")
    func readSwiftLintExclusionsEmpty() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let configContent = """
        disabled_rules:
          - line_length

        excluded:

        opt_in_rules:
          - empty_count
        """

        let configFile = tempDir.appendingPathComponent(".swiftlint.yml")
        try createFile(at: configFile, contents: configContent)

        let exclusions = ConfigDiscovery.readSwiftLintExclusions(configPath: configFile)

        #expect(exclusions.isEmpty)
    }

    @Test("readSwiftLintExclusions handles indented exclusions")
    func readSwiftLintExclusionsIndented() throws {
        let tempDir = try createTempDirectory()
        defer { cleanup(tempDir) }

        let configContent = """
        excluded:
            - .build
            - DerivedData
            - Frameworks
        """

        let configFile = tempDir.appendingPathComponent(".swiftlint.yml")
        try createFile(at: configFile, contents: configContent)

        let exclusions = ConfigDiscovery.readSwiftLintExclusions(configPath: configFile)

        #expect(exclusions.contains(".build"))
        #expect(exclusions.contains("DerivedData"))
        #expect(exclusions.contains("Frameworks"))
    }
}
