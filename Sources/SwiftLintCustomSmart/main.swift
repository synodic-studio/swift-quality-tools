import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintCustomSmart: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run custom SwiftSyntax-based linting rules",
        discussion: """
        This tool runs custom SwiftSyntax-based rules including:
        • SwiftUI View body properties limited to 12 lines maximum
        • SwiftUI View body properties must have exactly one top-level view (never Group)
        """,
    )

    @Argument(help: "File or directory to check (default: current directory)")
    var target: String = "."

    mutating func run() throws {
        let targetURL = URL(fileURLWithPath: target)

        // Validate target exists
        do {
            try ConfigDiscovery.validateTarget(targetURL)
        } catch {
            let errorMsg = ErrorFormatter.formatTargetError(
                tool: "SwiftLintCustomSmart",
                target: target,
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }

        // Get rule engine path
        let ruleEnginePath = ConfigDiscovery.customRuleEnginePath

        // Check if rule engine exists, build if needed
        if !FileManager.default.fileExists(atPath: ruleEnginePath.path) {
            Console.warning("Rule engine not found at \(ruleEnginePath.path)")
            print("Building rule engine...")

            let ruleEngineDir = ruleEnginePath.deletingLastPathComponent().deletingLastPathComponent()

            guard FileManager.default.fileExists(atPath: ruleEngineDir.path) else {
                let errorMsg = ErrorFormatter.format(
                    tool: "SwiftLintCustomSmart",
                    errorType: "RuleEngineDirectoryNotFound",
                    problem: "Rule engine directory not found",
                    context: "Expected at: \(ruleEngineDir.path)",
                    fix: "Verify swift-quality-tools CustomRules/swiftlint-swiftsyntax-integration/rule-engine/ directory exists",
                )
                Console.error(errorMsg)
                throw ExitCode.failure
            }

            // Build the rule engine
            do {
                let exitCode = try ProcessRunner.run(
                    "swift",
                    arguments: ["build"],
                    workingDirectory: ruleEngineDir,
                )

                if exitCode != 0 {
                    let errorMsg = ErrorFormatter.formatBuildError(
                        tool: "SwiftLintCustomSmart",
                        project: "rule-engine",
                        exitCode: Int32(exitCode),
                    )
                    Console.error(errorMsg)
                    throw ExitCode.failure
                }

                // Verify it was built
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

                Console.success("Rule engine built successfully")
            } catch let error as ProcessError {
                let errorMsg = ErrorFormatter.format(
                    tool: "SwiftLintCustomSmart",
                    errorType: "ProcessError",
                    problem: error.localizedDescription,
                    context: "Building rule engine with swift build",
                    fix: "Ensure Swift toolchain is installed and rule-engine Package.swift is valid",
                )
                Console.error(errorMsg)
                throw ExitCode.failure
            }
        }

        // Run custom rules
        Console.section("🔍 Running Custom SwiftSyntax Rules on: \(target)")
        print("")

        var violationCount = 0
        var totalFiles = 0
        var filesWithViolations: [String] = []

        // Process target
        let fileManager = FileManager.default
        var filesToCheck: [URL] = []

        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: targetURL.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Directory - find all Swift files
                if let enumerator = fileManager.enumerator(at: targetURL, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        if fileURL.pathExtension == "swift" {
                            filesToCheck.append(fileURL)
                        }
                    }
                }
                filesToCheck.sort { $0.path < $1.path }
            } else {
                // Single file
                if targetURL.pathExtension == "swift" {
                    filesToCheck.append(targetURL)
                } else {
                    Console.warning("File '\(target)' is not a Swift file")
                }
            }
        }

        totalFiles = filesToCheck.count

        // Check each file
        for fileURL in filesToCheck {
            let result = try checkFile(fileURL, ruleEngine: ruleEnginePath)
            if result.hasViolations {
                violationCount += 1
                filesWithViolations.append(result.relativePath)
            }
        }

        // Summary
        print("")
        Console.section("==================== SUMMARY ====================")
        print("📊 Files checked: \(totalFiles)")

        if violationCount == 0 {
            Console.success("No violations found! All code follows the custom rules.")
        } else {
            print("\(ANSIColor.red.rawValue)❌ Found \(violationCount) file(s) with violations:\(ANSIColor.reset.rawValue)")
            for filePath in filesWithViolations {
                print("  • \(filePath)")
            }
            print("")
            Console.section("Custom rules being checked:")
            print("  • SwiftUI View body properties limited to 12 lines maximum")
            print("  • SwiftUI View body properties must have exactly one top-level view (never Group)")
        }
        Console.section("=================================================")

        if violationCount > 0 {
            throw ExitCode.failure
        }
    }

    /// Result of checking a single file
    private struct CheckResult {
        let hasViolations: Bool
        let relativePath: String
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
            print("\(ANSIColor.red.rawValue)\(relativePath):\(ANSIColor.reset.rawValue)")

            // Print violations
            for line in output.components(separatedBy: .newlines) {
                if line.contains("⚠️") {
                    let cleaned = line.replacingOccurrences(of: "⚠️", with: "  •")
                    print("    \(cleaned)")
                }
            }
            print("")
            return CheckResult(hasViolations: true, relativePath: relativePath)
        }

        return CheckResult(hasViolations: false, relativePath: relativePath)
    }
}
