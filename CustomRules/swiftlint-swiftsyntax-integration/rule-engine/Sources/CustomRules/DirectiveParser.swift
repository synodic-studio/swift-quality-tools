import Foundation
import SwiftSyntax

/// Handles parsing and tracking of swiftlintcustom directive comments
/// Supports:
/// - swiftlintcustom:disable:next rule_name - suppress next line
/// - swiftlintcustom:disable:this rule_name - suppress current line
/// - swiftlintcustom:disable:previous rule_name - suppress previous line
/// - swiftlintcustom:disable rule_name - start disabled region (until enable or EOF)
/// - swiftlintcustom:enable rule_name - end disabled region
public final class DirectiveParser {
    private var disabledRulesForNextLine: [Int: Set<String>] = [:]
    private var disabledRulesForLine: [Int: Set<String>] = [:]
    private var disabledRulesForPreviousLine: [Int: Set<String>] = [:]

    /// Tracks block-level disable regions: rule -> [(startLine, endLine)]
    /// endLine is Int.max if the region extends to end of file
    private var disabledRegions: [String: [(start: Int, end: Int)]] = [:]

    /// Tracks currently open disable regions during parsing: rule -> startLine
    private var openDisableRegions: [String: Int] = [:]

    /// Total number of lines in the file (for closing open regions)
    private var totalLines = 0

    /// Parse all directives from source file
    public func parseDirectives(from source: String) {
        let lines = source.components(separatedBy: .newlines)
        totalLines = lines.count

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            parseLine(line, lineNumber: lineNumber)
        }

        // Close any open regions at end of file
        finalizeOpenRegions()
    }

    /// Check if a rule is suppressed for a given line
    /// For line 0 (file-level violations), any disable region anywhere suppresses it
    public func isSuppressed(rule: String, line: Int) -> Bool {
        // Line-specific disable:this
        if let disabledForLine = disabledRulesForLine[line],
           disabledForLine.contains(rule)
        {
            return true
        }

        // Line-specific disable:next (check previous line)
        if line > 1,
           let disabledForNextLine = disabledRulesForNextLine[line - 1],
           disabledForNextLine.contains(rule)
        {
            return true
        }

        // Line-specific disable:previous (check next line)
        if let disabledForPrevLine = disabledRulesForPreviousLine[line + 1],
           disabledForPrevLine.contains(rule)
        {
            return true
        }

        // Block-level disable regions
        if let regions = disabledRegions[rule] {
            // For file-level violations (line 0 or 1), any region anywhere suppresses
            if line <= 1, !regions.isEmpty {
                return true
            }
            // For line-specific violations, check if line is within a region
            for region in regions {
                if line >= region.start, line <= region.end {
                    return true
                }
            }
        }

        return false
    }

    /// Parse a single line for directives
    private func parseLine(_ line: String, lineNumber: Int) {
        // Check for inline comments (after code on same line)
        // Example: Task { ... } // swiftlintcustom:disable:this rule_name
        if let commentStart = line.range(of: "//") {
            let comment = String(line[commentStart.upperBound...])
                .trimmingCharacters(in: .whitespaces)

            if parseDirectiveComment(comment, lineNumber: lineNumber) {
                return
            }
        }

        // Check for comment-only lines
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("//") else { return }

        let comment = trimmed.dropFirst(2).trimmingCharacters(in: .whitespaces)
        _ = parseDirectiveComment(comment, lineNumber: lineNumber)
    }

    /// Parse a directive comment and return true if it was a directive
    private func parseDirectiveComment(_ comment: String, lineNumber: Int) -> Bool {
        // Order matters: check more specific prefixes first

        // swiftlintcustom:disable:next rule_name
        if comment.hasPrefix("swiftlintcustom:disable:next") {
            let rules = extractRules(from: comment, prefix: "swiftlintcustom:disable:next")
            disabledRulesForNextLine[lineNumber] = rules
            return true
        }

        // swiftlintcustom:disable:this rule_name
        if comment.hasPrefix("swiftlintcustom:disable:this") {
            let rules = extractRules(from: comment, prefix: "swiftlintcustom:disable:this")
            disabledRulesForLine[lineNumber] = rules
            return true
        }

        // swiftlintcustom:disable:previous rule_name
        if comment.hasPrefix("swiftlintcustom:disable:previous") {
            let rules = extractRules(from: comment, prefix: "swiftlintcustom:disable:previous")
            disabledRulesForPreviousLine[lineNumber] = rules
            return true
        }

        // swiftlintcustom:enable rule_name (close block region)
        if comment.hasPrefix("swiftlintcustom:enable") {
            let rules = extractRules(from: comment, prefix: "swiftlintcustom:enable")
            for rule in rules {
                closeDisableRegion(for: rule, at: lineNumber)
            }
            return true
        }

        // swiftlintcustom:disable rule_name (start block region - check last to avoid matching :next/:this/:previous)
        if comment.hasPrefix("swiftlintcustom:disable") {
            let rules = extractRules(from: comment, prefix: "swiftlintcustom:disable")
            for rule in rules {
                openDisableRegion(for: rule, at: lineNumber)
            }
            return true
        }

        return false
    }

    /// Open a disable region for a rule
    private func openDisableRegion(for rule: String, at line: Int) {
        // If already open, ignore (don't nest)
        guard openDisableRegions[rule] == nil else { return }
        openDisableRegions[rule] = line
    }

    /// Close a disable region for a rule
    private func closeDisableRegion(for rule: String, at line: Int) {
        guard let startLine = openDisableRegions[rule] else { return }

        // Add the completed region
        var regions = disabledRegions[rule] ?? []
        regions.append((start: startLine, end: line))
        disabledRegions[rule] = regions

        // Remove from open regions
        openDisableRegions.removeValue(forKey: rule)
    }

    /// Close any open regions at end of file
    private func finalizeOpenRegions() {
        for (rule, startLine) in openDisableRegions {
            var regions = disabledRegions[rule] ?? []
            regions.append((start: startLine, end: Int.max))
            disabledRegions[rule] = regions
        }
        openDisableRegions.removeAll()
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
