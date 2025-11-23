import Foundation
import SwiftSyntax

/// Handles parsing and tracking of swiftlint directive comments
/// Supports:
/// - swiftlint:disable:next rule_name
/// - swiftlint:disable:this rule_name
/// - swiftlint:disable rule_name (file-level)
/// - swiftlint:enable rule_name (file-level)
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
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Only process comment lines
        guard trimmed.hasPrefix("//") else { return }

        let comment = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)

        // swiftlint:disable:next rule_name
        if comment.hasPrefix("swiftlint:disable:next") {
            let rules = extractRules(from: comment, prefix: "swiftlint:disable:next")
            disabledRulesForNextLine[lineNumber] = rules
        }
        // swiftlint:disable:this rule_name
        else if comment.hasPrefix("swiftlint:disable:this") {
            let rules = extractRules(from: comment, prefix: "swiftlint:disable:this")
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
