import Foundation
import SwiftSyntax

// Reason: SwiftSyntax visitors match nested tree shapes (decl → binding → type →
// call → closure); depth-4 traversal is intrinsic to AST matching. excessive_nesting
// is a SwiftUI view-code readability heuristic and does not fit traversal internals.
// swiftskim:disable excessive_nesting

/// Handles parsing and tracking of swiftskim directive comments.
///
/// The primary prefix is `swiftskim:`; `swiftlintcustom:` is accepted as a legacy
/// alias so existing directives keep working. Supports (with either prefix):
/// - `<prefix>:disable:next rule_name` - suppress next line
/// - `<prefix>:disable:this rule_name` - suppress current line
/// - `<prefix>:disable:previous rule_name` - suppress previous line
/// - `<prefix>:disable rule_name` - start disabled region (until enable or EOF)
/// - `<prefix>:enable rule_name` - end disabled region
public final class DirectiveParser {
    /// Accepted directive prefixes; primary first, legacy alias second.
    private static let prefixes = ["swiftskim", "swiftlintcustom"]

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
        // Example: Task { ... } // swiftskim:disable:this rule_name
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

    /// Parse a directive comment and return true if it was a directive.
    /// Tries each accepted prefix (primary `swiftskim:`, legacy `swiftlintcustom:`).
    private func parseDirectiveComment(_ comment: String, lineNumber: Int) -> Bool {
        for prefix in Self.prefixes where parseDirective(comment, prefix: prefix, lineNumber: lineNumber) {
            return true
        }
        return false
    }

    /// Parse a directive comment for one brand prefix. Order matters: check the
    /// more specific `:disable:*` forms before the bare `:disable` region form.
    private func parseDirective(_ comment: String, prefix: String, lineNumber: Int) -> Bool {
        if comment.hasPrefix("\(prefix):disable:next") {
            disabledRulesForNextLine[lineNumber] = extractRules(from: comment, prefix: "\(prefix):disable:next")
            return true
        }
        if comment.hasPrefix("\(prefix):disable:this") {
            disabledRulesForLine[lineNumber] = extractRules(from: comment, prefix: "\(prefix):disable:this")
            return true
        }
        if comment.hasPrefix("\(prefix):disable:previous") {
            disabledRulesForPreviousLine[lineNumber] = extractRules(from: comment, prefix: "\(prefix):disable:previous")
            return true
        }
        if comment.hasPrefix("\(prefix):enable") {
            extractRules(from: comment, prefix: "\(prefix):enable").forEach { closeDisableRegion(for: $0, at: lineNumber) }
            return true
        }
        if comment.hasPrefix("\(prefix):disable") {
            extractRules(from: comment, prefix: "\(prefix):disable").forEach { openDisableRegion(for: $0, at: lineNumber) }
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
