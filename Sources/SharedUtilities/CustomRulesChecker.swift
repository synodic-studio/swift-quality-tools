import Foundation

/// Utility for running custom rules checks on files
public enum CustomRulesChecker {
    /// Check a single file for violations
    /// - Parameters:
    ///   - fileURL: URL of file to check
    ///   - ruleEngine: URL of rule engine executable
    /// - Returns: CheckResult with violation status and relative path
    public static func checkFile(_ fileURL: URL, ruleEngine: URL) throws -> CheckResult {
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
    private static func printViolations(output: String, relativePath: String) {
        print("\(ANSIColor.red.rawValue)\(relativePath):\(ANSIColor.reset.rawValue)")

        let violationLines = output.components(separatedBy: .newlines).filter { $0.contains("⚠️") }
        for line in violationLines {
            let cleaned = line.replacingOccurrences(of: "⚠️", with: "  •")
            print("    \(cleaned)")
        }
        print("")
    }

    /// Print summary of linting results
    public static func printSummary(totalFiles: Int, violations: Int) {
        print("")
        if violations == 0 {
            Console.success("✓ \(totalFiles) files checked, no violations")
        } else {
            Console.warning("\(violations)/\(totalFiles) files with violations")
        }
    }
}
