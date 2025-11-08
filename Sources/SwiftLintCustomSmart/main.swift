import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintCustomSmart: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run custom SwiftSyntax-based linting rules",
        discussion: """
            This tool runs custom SwiftSyntax-based rules including:
            • SwiftUI View body properties limited to 10 lines maximum
            • SwiftUI View body properties must have exactly one top-level view (never Group)
            """
    )

    @Argument(help: "File or directory to check (default: current directory)")
    var target: String = "."

    mutating func run() throws {
        let targetURL = URL(fileURLWithPath: target)

        // Validate target exists
        do {
            try ConfigDiscovery.validateTarget(targetURL)
        } catch {
            Console.error(error.localizedDescription)
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
                Console.error("Rule engine directory not found: \(ruleEngineDir.path)")
                throw ExitCode.failure
            }

            // Build the rule engine
            do {
                let exitCode = try ProcessRunner.run(
                    "swift",
                    arguments: ["build"],
                    workingDirectory: ruleEngineDir
                )

                if exitCode != 0 {
                    Console.error("Failed to build rule engine")
                    throw ExitCode.failure
                }

                // Verify it was built
                guard FileManager.default.fileExists(atPath: ruleEnginePath.path) else {
                    Console.error("Rule engine build succeeded but executable not found")
                    throw ExitCode.failure
                }

                Console.success("Rule engine built successfully")
            } catch let error as ProcessError {
                Console.error(error.localizedDescription)
                throw ExitCode.failure
            }
        }

        // Run custom rules
        Console.section("🔍 Running Custom SwiftSyntax Rules on: \(target)")
        print("")

        var violationCount = 0
        var totalFiles = 0

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
            if try checkFile(fileURL, ruleEngine: ruleEnginePath) {
                violationCount += 1
            }
        }

        // Summary
        print("")
        Console.section("==================== SUMMARY ====================")
        print("📊 Files checked: \(totalFiles)")

        if violationCount == 0 {
            Console.success("No violations found! All code follows the custom rules.")
        } else {
            print("\(ANSIColor.red.rawValue)❌ Found \(violationCount) file(s) with violations.\(ANSIColor.reset.rawValue)")
            print("")
            Console.section("Custom rules being checked:")
            print("  • SwiftUI View body properties limited to 10 lines maximum")
            print("  • SwiftUI View body properties must have exactly one top-level view (never Group)")
        }
        Console.section("=================================================")

        if violationCount > 0 {
            throw ExitCode.failure
        }
    }

    /// Check a single file for violations
    /// - Parameters:
    ///   - fileURL: URL of file to check
    ///   - ruleEngine: URL of rule engine executable
    /// - Returns: true if violations found, false otherwise
    private func checkFile(_ fileURL: URL, ruleEngine: URL) throws -> Bool {
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

        // Check if there are violations
        if output.contains("⚠️") {
            let relativePath = fileURL.path.replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")
            print("\(ANSIColor.red.rawValue)\(relativePath):\(ANSIColor.reset.rawValue)")

            // Print violations
            output.components(separatedBy: .newlines).forEach { line in
                if line.contains("⚠️") {
                    let cleaned = line.replacingOccurrences(of: "⚠️", with: "  •")
                    print("    \(cleaned)")
                }
            }
            print("")
            return true
        }

        return false
    }
}
