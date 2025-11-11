import Foundation
import Testing
@testable import SharedUtilities

@Suite("ErrorFormatter Tests")
struct ErrorFormatterTests {
    @Test("Basic error formatting includes all components")
    func basicErrorFormatting() {
        let result = ErrorFormatter.format(
            tool: "TestTool",
            errorType: "TestError",
            problem: "Something went wrong",
            context: "During test execution",
            file: "/path/to/file.swift:42",
            fix: "Try fixing this thing",
        )

        #expect(result.contains("🚨 TestTool Error: TestError"))
        #expect(result.contains("Problem: Something went wrong"))
        #expect(result.contains("Context: During test execution"))
        #expect(result.contains("File: /path/to/file.swift:42"))
        #expect(result.contains("Fix: Try fixing this thing"))
    }

    @Test("Error formatting works without optional parameters")
    func minimalErrorFormatting() {
        let result = ErrorFormatter.format(
            tool: "TestTool",
            errorType: "TestError",
            problem: "Something went wrong",
            fix: "Try fixing this thing",
        )

        #expect(result.contains("🚨 TestTool Error: TestError"))
        #expect(result.contains("Problem: Something went wrong"))
        #expect(result.contains("Fix: Try fixing this thing"))
        #expect(!result.contains("Context:"))
        #expect(!result.contains("File:"))
    }

    @Test("Config error formatting generates proper message")
    func configErrorFormatting() {
        let result = ErrorFormatter.formatConfigError(
            tool: "SwiftFormatSmart",
            searchPath: "/Users/test/project",
            configName: ".swiftformat.yml",
        )

        #expect(result.contains("🚨 SwiftFormatSmart Error: ConfigNotFound"))
        #expect(result.contains("Problem: No .swiftformat.yml found"))
        #expect(result.contains("Context: Searching from /Users/test/project"))
        #expect(result.contains("Fix: Create .swiftformat.yml"))
        #expect(result.contains("--config flag"))
    }

    @Test("Config error formatting accepts custom fix message")
    func configErrorCustomFix() {
        let customFix = "Install the config from template"
        let result = ErrorFormatter.formatConfigError(
            tool: "SwiftLintSmart",
            searchPath: "/path",
            configName: ".swiftlint.yml",
            fix: customFix,
        )

        #expect(result.contains("Fix: \(customFix)"))
    }

    @Test("Command error formatting includes install instructions")
    func commandErrorFormatting() {
        let result = ErrorFormatter.formatCommandError(
            tool: "SwiftFormatSmart",
            command: "swiftformat",
        )

        #expect(result.contains("🚨 SwiftFormatSmart Error: CommandNotFound"))
        #expect(result.contains("Problem: Required command 'swiftformat' not found"))
        #expect(result.contains("Fix: Install swiftformat using: brew install swiftformat"))
    }

    @Test("Target error formatting shows path")
    func targetErrorFormatting() {
        let result = ErrorFormatter.formatTargetError(
            tool: "SwiftLintCustomSmart",
            target: "/path/to/missing/file.swift",
        )

        #expect(result.contains("🚨 SwiftLintCustomSmart Error: TargetNotFound"))
        #expect(result.contains("Problem: Target path does not exist: /path/to/missing/file.swift"))
        #expect(result.contains("Fix: Verify the path exists"))
    }

    @Test("Build error formatting includes exit code")
    func buildErrorFormatting() {
        let result = ErrorFormatter.formatBuildError(
            tool: "SwiftLintCustomSmart",
            project: "rule-engine",
            exitCode: 1,
        )

        #expect(result.contains("🚨 SwiftLintCustomSmart Error: BuildFailed"))
        #expect(result.contains("Problem: Build failed for rule-engine with exit code 1"))
        #expect(result.contains("Fix: Review build errors"))
    }

    @Test("Build error formatting includes output when provided")
    func buildErrorWithOutput() {
        let buildOutput = "error: cannot find 'foo' in scope"
        let result = ErrorFormatter.formatBuildError(
            tool: "SwiftLintCustomSmart",
            project: "rule-engine",
            exitCode: 1,
            output: buildOutput,
        )

        #expect(result.contains(buildOutput))
        #expect(result.contains("Build output:"))
    }

    @Test("Multiple configs error formatting lists all configs")
    func multipleConfigsErrorFormatting() {
        let configs = [
            "/path/to/.swiftformat.yml",
            "/path/to/.swiftformat",
        ]

        let result = ErrorFormatter.formatMultipleConfigsError(
            tool: "SwiftFormatSmart",
            configs: configs,
            directory: "/path/to",
        )

        #expect(result.contains("🚨 SwiftFormatSmart Error: MultipleConfigsFound"))
        #expect(result.contains("Found multiple config files in /path/to"))
        #expect(result.contains(".swiftformat.yml"))
        #expect(result.contains(".swiftformat"))
        #expect(result.contains("Fix: Keep only one config file"))
    }

    @Test("Error messages follow consistent structure")
    func errorMessageStructure() {
        let result = ErrorFormatter.format(
            tool: "Tool",
            errorType: "Error",
            problem: "Problem",
            context: "Context",
            file: "File",
            fix: "Fix",
        )

        let lines = result.components(separatedBy: "\n")
        #expect(lines.count == 5)
        #expect(lines[0].starts(with: "🚨"))
        #expect(lines[1].starts(with: "Problem:"))
        #expect(lines[2].starts(with: "Context:"))
        #expect(lines[3].starts(with: "File:"))
        #expect(lines[4].starts(with: "Fix:"))
    }
}
