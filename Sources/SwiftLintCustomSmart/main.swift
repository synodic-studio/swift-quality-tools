import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintCustomSmart: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run custom SwiftSyntax-based linting rules",
        discussion: """
        This tool runs custom SwiftSyntax-based rules including:
        • SwiftUI View body properties limited to 15 lines maximum
        • SwiftUI View body properties must have exactly one top-level view (never Group)
        • Indentation depth limited to 4 levels maximum for all functions, closures, and initializers
        """,
    )

    @Argument(help: "File or directory to check (default: current directory)")
    var target: String = "."

    mutating func run() throws {
        let targetURL = URL(fileURLWithPath: target)
        try ConfigDiscovery.validateTarget(targetURL)

        let ruleEnginePath = ConfigDiscovery.customRuleEnginePath
        try ensureRuleEngineBuilt(ruleEnginePath)

        Console.section("🔍 Running Custom SwiftSyntax Rules on: \(target)")

        let exclusionPatterns = ConfigDiscovery.readSwiftLintExclusions()
        let filesToCheck = collectSwiftFiles(from: targetURL, excluding: exclusionPatterns)

        let results = try filesToCheck.map { try checkFile($0, ruleEngine: ruleEnginePath) }
        let violationCount = results.filter(\.hasViolations).count

        printSummary(totalFiles: filesToCheck.count, violations: violationCount)
        if violationCount > 0 {
            throw ExitCode.failure
        }
    }

    /// Ensure the rule engine is built and ready to use
    private func ensureRuleEngineBuilt(_ ruleEnginePath: URL) throws {
        guard !FileManager.default.fileExists(atPath: ruleEnginePath.path) else {
            return
        }

        Console.warning("Rule engine not found at \(ruleEnginePath.path)")
        print("Building rule engine...")

        let ruleEngineDir = ruleEnginePath.deletingLastPathComponent().deletingLastPathComponent()
        try validateRuleEngineDirectory(ruleEngineDir)
        try buildRuleEngine(at: ruleEngineDir)
        try verifyRuleEngineBuild(ruleEnginePath)

        Console.success("Rule engine built successfully")
    }

    /// Validate that the rule engine directory exists
    private func validateRuleEngineDirectory(_ directory: URL) throws {
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
    private func buildRuleEngine(at directory: URL) throws {
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
    private func throwIfBuildFailed(_ exitCode: Int32) throws {
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
    private func buildProcessError(_ error: ProcessError) -> ExitCode {
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
    private func verifyRuleEngineBuild(_ ruleEnginePath: URL) throws {
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

    /// Collect Swift files from the target URL, excluding specified patterns
    private func collectSwiftFiles(from targetURL: URL, excluding patterns: [String]) -> [URL] {
        var filesToCheck: [URL] = []
        let fileManager = FileManager.default

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: targetURL.path, isDirectory: &isDirectory) else {
            return []
        }

        if isDirectory.boolValue {
            filesToCheck = collectSwiftFilesFromDirectory(targetURL, excluding: patterns)
        } else if targetURL.pathExtension == "swift" {
            filesToCheck.append(targetURL)
        } else {
            Console.warning("File '\(target)' is not a Swift file")
        }

        return filesToCheck
    }

    /// Collect Swift files from a directory recursively
    private func collectSwiftFilesFromDirectory(_ directoryURL: URL, excluding patterns: [String]) -> [URL] {
        var files: [URL] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift", !shouldExclude(fileURL, patterns: patterns) {
                files.append(fileURL)
            }
        }

        return files.sorted { $0.path < $1.path }
    }

    /// Print summary of linting results
    private func printSummary(totalFiles: Int, violations: Int) {
        print("")
        if violations == 0 {
            Console.success("✓ \(totalFiles) files checked, no violations")
        } else {
            Console.warning("\(violations)/\(totalFiles) files with violations")
        }
    }

    /// Result of checking a single file
    private struct CheckResult {
        let hasViolations: Bool
        let relativePath: String
    }

    /// Check if a file should be excluded from linting based on SwiftLint exclusion patterns
    /// - Parameters:
    ///   - fileURL: The file URL to check
    ///   - patterns: Exclusion patterns from SwiftLint config
    /// - Returns: True if the file should be excluded
    private func shouldExclude(_ fileURL: URL, patterns: [String]) -> Bool {
        let path = fileURL.path
        return patterns.contains { matchesPattern($0, in: path) }
    }

    /// Check if a path matches an exclusion pattern
    private func matchesPattern(_ pattern: String, in path: String) -> Bool {
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

    /// Check a single file for violations
    /// - Parameters:
    ///   - fileURL: URL of file to check
    ///   - ruleEngine: URL of rule engine executable
    /// - Returns: CheckResult with violation status and relative path
    private func checkFile(_ fileURL: URL, ruleEngine: URL) throws -> CheckResult {
        let process = Process()
        process.executableURL = ruleEngine
        process.arguments = [fileURL.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        let relativePath = fileURL.path.replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")

        // Check if there are violations
        if output.contains("⚠️") {
            printViolations(output: output, relativePath: relativePath)
            return CheckResult(hasViolations: true, relativePath: relativePath)
        }

        return CheckResult(hasViolations: false, relativePath: relativePath)
    }

    /// Print violations from linting output
    private func printViolations(output: String, relativePath: String) {
        print("\(ANSIColor.red.rawValue)\(relativePath):\(ANSIColor.reset.rawValue)")

        let violationLines = output.components(separatedBy: .newlines).filter { $0.contains("⚠️") }
        for line in violationLines {
            let cleaned = line.replacingOccurrences(of: "⚠️", with: "  •")
            print("    \(cleaned)")
        }
        print("")
    }
}
