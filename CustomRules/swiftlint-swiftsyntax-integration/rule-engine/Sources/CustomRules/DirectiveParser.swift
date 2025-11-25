import Foundation
import SwiftSyntax

/// Handles parsing and tracking of swiftlintcustom directive comments
/// Supports:
/// - swiftlintcustom:disable:next rule_name
/// - swiftlintcustom:disable:this rule_name
/// - swiftlintcustom:disable rule_name (file-level - TODO)
/// - swiftlintcustom:enable rule_name (file-level - TODO)
public final class DirectiveParser {
    private var disabledRulesForNextLine: [Int: Set<String>] = [:]
    private var disabledRulesForLine: [Int: Set<String>] = [:]
    /// Parse all directives from source file
    public func parseDirectives(from source: String) {
        let lines = source.components(separatedBy: .newlines)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            parseLine(line, lineNumber: lineNumber)
        }
    }

    /// Check if a rule is suppressed for a given line
    public func isSuppressed(rule: String, line: Int) -> Bool {
        // Line-specific disable:this
        if let disabledForLine = disabledRulesForLine[line],
           disabledForLine.contains(rule)
        {
            return true
        }

        // Line-specific disable:next (check previous line)
        if let disabledForNextLine = disabledRulesForNextLine[line - 1],
           disabledForNextLine.contains(rule)
        {
            return true
        }

        // File-level disable not yet implemented
        return false
    }

    /// Parse a single line for directives
    private func parseLine(_ line: String, lineNumber: Int) {
        // Check for inline comments (after code on same line)
        // Example: Task { ... } // swiftlintcustom:disable:this rule_name
        if let commentStart = line.range(of: "//") {
            let comment = String(line[commentStart.upperBound...])
                .trimmingCharacters(in: .whitespaces)

            // swiftlintcustom:disable:this for inline comments
            if comment.hasPrefix("swiftlintcustom:disable:this") {
                let rules = extractRules(from: comment, prefix: "swiftlintcustom:disable:this")
                disabledRulesForLine[lineNumber] = rules
                return
            }
        }

        // Check for comment-only lines (for :next directives)
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("//") else { return }

        let comment = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)

        // swiftlintcustom:disable:next rule_name
        if comment.hasPrefix("swiftlintcustom:disable:next") {
            let rules = extractRules(from: comment, prefix: "swiftlintcustom:disable:next")
            disabledRulesForNextLine[lineNumber] = rules
        }
        // swiftlintcustom:disable:this for comment-only lines
        else if comment.hasPrefix("swiftlintcustom:disable:this") {
            let rules = extractRules(from: comment, prefix: "swiftlintcustom:disable:this")
            disabledRulesForLine[lineNumber] = rules
        }
        // Note: File-level disable/enable not yet implemented
        // TODO: Implement file-level directive support with proper range tracking
    }

    /// Extract rule names from directive comment
    private func extractRules(from comment: String, prefix: String) -> Set<String> {
        guard let prefixRange = comment.range(of: prefix) else {
            return []
        }

        let rulesText = String(comment[prefixRange.upperBound...])
            .trimmingCharacters(in: .whitespaces)

        // Split by whitespace to get individual rule names
        let ruleNames = rulesText.components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return Set(ruleNames)
    }
}
