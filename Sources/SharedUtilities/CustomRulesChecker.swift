import Foundation

/// Utility for running custom rules checks on files
public enum CustomRulesChecker {
    /// Check a single file for violations
    /// - Parameters:
    ///   - fileURL: URL of file to check
    ///   - ruleEngine: URL of rule engine executable
    ///   - xcodeFormat: Whether to output in Xcode-compatible format
    ///   - onlyRules: Optional list of rule IDs to run (nil = all rules)
    ///   - thresholds: Configurable rule thresholds (empty = engine defaults)
    /// - Returns: CheckResult with violation status and relative path
    public static func checkFile(
        _ fileURL: URL,
        ruleEngine: URL,
        xcodeFormat: Bool = false,
        onlyRules: [String]? = nil,
        thresholds: RuleThresholds = RuleThresholds(),
    ) throws -> CheckResult {
        let process = Process()
        process.executableURL = ruleEngine
        var arguments = [fileURL.path]
        if let onlyRules, !onlyRules.isEmpty {
            arguments.append("--only-rules")
            arguments.append(onlyRules.joined(separator: ","))
        }
        arguments.append(contentsOf: thresholds.engineArguments)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        let relativePath = fileURL.path.replacingOccurrences(of: FileManager.default.currentDirectoryPath + "/", with: "")
        let absolutePath = fileURL.path

        // Parse violations from output
        let violations = parseViolations(from: output)

        // Print violations in appropriate format
        if !violations.isEmpty {
            if xcodeFormat {
                printXcodeViolations(violations: violations, absolutePath: absolutePath)
            } else {
                printTerminalViolations(violations: violations, relativePath: relativePath)
            }
        }

        return CheckResult(hasViolations: !violations.isEmpty, relativePath: relativePath, violations: violations)
    }

    /// Parse violations from rule engine output
    /// Expects formats:
    /// - "⚠️  [rule_id] Line X has message"
    /// - "⚠️  [rule_id] message" (for file-level violations)
    private static func parseViolations(from output: String) -> [Violation] {
        output.components(separatedBy: .newlines)
            .filter { $0.contains("⚠️") }
            .compactMap { line in
                parseViolation(from: line)
            }
    }

    /// Parse a single violation line
    private static func parseViolation(from line: String) -> Violation? {
        guard let ruleIDRange = line.range(of: #"\[([^\]]+)\]"#, options: .regularExpression) else {
            return nil
        }

        let ruleID = String(line[ruleIDRange].dropFirst().dropLast())

        // Try to extract line number and message
        if let (lineNumber, message) = extractLineAndMessage(from: line) {
            return Violation(line: lineNumber, ruleID: ruleID, message: message)
        }

        // File-level violation (no line number)
        if let messageStart = ruleIDRange.upperBound.samePosition(in: line) {
            let message = String(line[messageStart...]).trimmingCharacters(in: .whitespaces)
            return Violation(line: 0, ruleID: ruleID, message: message)
        }

        return nil
    }

    /// Extract line number and message from violation text
    private static func extractLineAndMessage(from line: String) -> (Int, String)? {
        // Match two formats:
        // 1. "Line N: message" (new format from view_structure_order)
        // 2. "Line N message" (existing format from other rules)
        guard let lineNumberRange = line.range(of: #"Line (\d+):?"#, options: .regularExpression) else {
            return nil
        }

        let lineNumberMatch = line[lineNumberRange]
        guard let lineNumberStr = lineNumberMatch.split(separator: " ").last,
              let lineNumber = Int(lineNumberStr.replacingOccurrences(of: ":", with: ""))
        else {
            return nil
        }

        // Find where the message starts (after "Line N:" or "Line N ")
        guard let messageStart = line.range(of: #"Line \d+:? "#, options: .regularExpression)?.upperBound else {
            return nil
        }

        let message = String(line[messageStart...])
        return (lineNumber, message)
    }

    /// Print violations in Xcode-compatible format
    /// Format: /absolute/path/file.swift:42: warning: [rule_id] message
    /// File-level violations use line 1 for Xcode clickability
    private static func printXcodeViolations(violations: [Violation], absolutePath: String) {
        for violation in violations {
            let line = violation.line == 0 ? 1 : violation.line
            print("\(absolutePath):\(line): warning: [\(violation.ruleID)] \(violation.message)")
        }
    }

    /// Print violations in terminal format with colors
    private static func printTerminalViolations(violations: [Violation], relativePath: String) {
        print("\(ANSIColor.red.rawValue)\(relativePath):\(ANSIColor.reset.rawValue)")

        for violation in violations {
            if violation.line == 0 {
                // File-level violation
                print("    • [\(violation.ruleID)] \(violation.message)")
            } else {
                print("    • [\(violation.ruleID)] Line \(violation.line): \(violation.message)")
            }
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
