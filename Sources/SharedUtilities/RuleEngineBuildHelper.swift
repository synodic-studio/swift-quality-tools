import ArgumentParser
import Foundation

/// Helper for building and verifying the custom rule engine
public enum RuleEngineBuildHelper {
    /// Ensure the rule engine is built and ready to use
    public static func ensureBuilt(_ ruleEnginePath: URL) throws {
        guard !FileManager.default.fileExists(atPath: ruleEnginePath.path) else {
            return
        }

        Console.warning("Rule engine not found at \(ruleEnginePath.path)")
        print("Building rule engine...")

        let ruleEngineDir = ruleEnginePath.deletingLastPathComponent().deletingLastPathComponent()
        try validateDirectory(ruleEngineDir)
        try build(at: ruleEngineDir)
        try verifyBuild(ruleEnginePath)

        Console.success("Rule engine built successfully")
    }

    /// Validate that the rule engine directory exists
    private static func validateDirectory(_ directory: URL) throws {
        guard FileManager.default.fileExists(atPath: directory.path) else {
            let errorMsg = ErrorFormatter.format(
                tool: "SwiftLintCustomSmart",
                errorType: "RuleEngineDirectoryNotFound",
                problem: "Rule engine directory not found",
                context: "Expected at: \(directory.path)",
                fix: "Verify swift-quality-tools CustomRules/swiftlint-swiftsyntax-integration/rule-engine/ directory exists",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }
    }

    /// Build the rule engine using swift build
    private static func build(at directory: URL) throws {
        do {
            let exitCode = try ProcessRunner.run(
                "swift",
                arguments: ["build"],
                workingDirectory: directory,
            )
            try throwIfBuildFailed(exitCode)
        } catch let error as ProcessError {
            throw buildProcessError(error)
        }
    }

    /// Throw an error if the build failed
    private static func throwIfBuildFailed(_ exitCode: Int32) throws {
        guard exitCode == 0 else {
            let errorMsg = ErrorFormatter.formatBuildError(
                tool: "SwiftLintCustomSmart",
                project: "rule-engine",
                exitCode: exitCode,
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }
    }

    /// Create an error for process failures
    private static func buildProcessError(_ error: ProcessError) -> ExitCode {
        let errorMsg = ErrorFormatter.format(
            tool: "SwiftLintCustomSmart",
            errorType: "ProcessError",
            problem: error.localizedDescription,
            context: "Building rule engine with swift build",
            fix: "Ensure Swift toolchain is installed and rule-engine Package.swift is valid",
        )
        Console.error(errorMsg)
        return ExitCode.failure
    }

    /// Verify that the rule engine was built successfully
    private static func verifyBuild(_ ruleEnginePath: URL) throws {
        guard FileManager.default.fileExists(atPath: ruleEnginePath.path) else {
            let errorMsg = ErrorFormatter.format(
                tool: "SwiftLintCustomSmart",
                errorType: "ExecutableNotFound",
                problem: "Rule engine build succeeded but executable not found",
                context: "Expected at: \(ruleEnginePath.path)",
                fix: "Check if swift build created the executable in .build/debug/",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }
    }
}
