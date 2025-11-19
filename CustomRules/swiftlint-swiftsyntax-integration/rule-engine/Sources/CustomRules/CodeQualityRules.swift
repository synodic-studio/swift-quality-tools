import SwiftSyntax

/// Rules related to general code quality
/// - constants_enum_usage: No magic numbers (DISABLED)
/// - excessive_indentation: Max 16 spaces of physical indentation (4 tabs)
public enum CodeQualityRules {
    public static func checkMagicNumber(_ node: IntegerLiteralExprSyntax, isInSwiftUIView: Bool, violations: inout [String]) {
        let value = node.literal.text

        // Ignore common safe values (0, 1, 2) and array indices
        let safeValues = ["0", "1", "2"]
        if safeValues.contains(value) {
            return
        }

        // Only flag if we're in a SwiftUI View context
        guard isInSwiftUIView else { return }

        let violation = "⚠️  [constants_enum_usage] Magic number '\(value)' detected - consider using an enum Constants pattern at the top of the type"
        violations.append(violation)
        print(violation)
    }

    public static func checkMagicFloatNumber(_ node: FloatLiteralExprSyntax, isInSwiftUIView: Bool, violations: inout [String]) {
        let value = node.literal.text

        // Ignore common safe values (0.0, 1.0, 0.5)
        let safeValues = ["0.0", "1.0", "0.5", "0", "1"]
        if safeValues.contains(value) {
            return
        }

        // Only flag if we're in a SwiftUI View context
        guard isInSwiftUIView else { return }

        let violation = "⚠️  [constants_enum_usage] Magic number '\(value)' detected - consider using an enum Constants pattern at the top of the type"
        violations.append(violation)
        print(violation)
    }

    public static func checkExcessiveIndentation(_ sourceFile: SourceFileSyntax, violations: inout [String]) {
        let sourceText = sourceFile.description
        let lines = sourceText.components(separatedBy: .newlines)

        for (lineNumber, line) in lines.enumerated() {
            // Count leading spaces
            let leadingSpaces = line.prefix(while: { $0 == " " }).count

            // Skip empty lines and lines with only whitespace
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }

            // Check if indentation exceeds 16 spaces (4 tabs × 4 spaces)
            if leadingSpaces > 16 {
                let violation = "⚠️  [excessive_indentation] Line \(lineNumber + 1) has excessive indentation (\(leadingSpaces) spaces, maximum: 16) - refactor code to reduce nesting depth"
                violations.append(violation)
                print(violation)
            }
        }
    }
}
