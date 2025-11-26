import SwiftSyntax

/// Rules related to modifier formatting and line structure
/// - single_modifier_per_line: Each modifier should be on its own line for readability
public enum ModifierFormattingRules {
    /// Check for multiple modifiers on the same line or modifiers on the same line as closing delimiter
    /// Examples of violations:
    /// - `.padding().background(.red)` - multiple modifiers on same line
    /// - `).padding()` - modifier on same line as multiline expression's closing paren
    public static func checkSingleModifierPerLine(
        _ sourceFile: SourceFileSyntax,
        violations: inout [String],
    ) {
        let sourceText = sourceFile.description
        let lines = sourceText.split(separator: "\n", omittingEmptySubsequences: false)

        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            let lineStr = String(line)
            let trimmed = lineStr.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("//") {
                continue
            }

            // Check 1: Multiple modifiers on the same line
            // Pattern: .something().something() or .something().something
            if hasMultipleModifiersOnLine(trimmed) {
                let violation = "⚠️  [single_modifier_per_line] Line \(lineNumber): Multiple modifiers on same line - place each modifier on its own line for readability"
                violations.append(violation)
                continue
            }

            // Check 2: Modifier on same line as closing delimiter from multiline expression
            // Pattern: ).modifier( or ].modifier(
            if hasModifierAfterClosingDelimiter(trimmed) {
                let violation = "⚠️  [single_modifier_per_line] Line \(lineNumber): Modifier chained on same line as closing delimiter - place modifier on its own line"
                violations.append(violation)
            }
        }
    }

    /// Detect multiple modifier calls on the same line
    /// Returns true if line contains patterns like `.foo().bar()` or `.foo().bar`
    private static func hasMultipleModifiersOnLine(_ line: String) -> Bool {
        // Find all occurrences of ").identifier" or ")." patterns
        // This indicates a method/modifier being chained after a closing paren

        // Count the number of modifier starts (lines starting with . don't count for this rule)
        // We're looking for chained modifiers in the middle of a line

        var modifierCount = 0
        var inString = false
        var prevChar: Character = " "
        var i = line.startIndex

        while i < line.endIndex {
            let char = line[i]

            // Basic string detection (doesn't handle escapes but good enough for this)
            if char == "\"" {
                inString.toggle()
            }

            if !inString {
                // Pattern: ).something or ].something (chained call after closing delimiter)
                if prevChar == ")" || prevChar == "]", char == "." {
                    modifierCount += 1
                }
            }

            prevChar = char
            i = line.index(after: i)
        }

        // Multiple modifiers = more than one chain point on the line
        return modifierCount >= 2
    }

    /// Detect modifier chained on same line as a closing delimiter
    /// Returns true if line starts with a closing delimiter followed by a modifier
    /// Example: `).padding()` when the opening `(` was on a previous line
    private static func hasModifierAfterClosingDelimiter(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // Pattern: line starts with ) or ] followed by .
        // This means the closing delimiter and modifier are on the same line
        guard let firstChar = trimmed.first else { return false }

        if firstChar == ")" || firstChar == "]" {
            // Find the position after all closing delimiters
            var index = trimmed.startIndex
            while index < trimmed.endIndex {
                let char = trimmed[index]
                if char != ")", char != "]" {
                    break
                }
                index = trimmed.index(after: index)
            }

            // Check if the next character is a dot (modifier)
            if index < trimmed.endIndex, trimmed[index] == "." {
                return true
            }
        }

        return false
    }
}
