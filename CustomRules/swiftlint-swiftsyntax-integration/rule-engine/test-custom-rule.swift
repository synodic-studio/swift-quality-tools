import Foundation
import SwiftParser
import SwiftSyntax

/// Simplified version of our custom rules for testing
final class CustomRulesVisitor: SyntaxVisitor {
    private var violations: [String] = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if this is a body property
        guard let binding = node.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              identifier.identifier.text == "body"
        else {
            return .visitChildren
        }

        // Check if it's a SwiftUI View body
        if let typeAnnotation = binding.typeAnnotation {
            let typeText = typeAnnotation.description
            if typeText.contains("some View") {
                // Rule 1: Skimmable body (line count)
                checkSkimmableBody(node)

                // Rule 2: No Group body (top-level Group)
                checkNoGroupBody(node)

                // Rule 3: One top-level view (multiple statements)
                checkOneTopLevelView(node)
            }
        }

        return .visitChildren
    }

    private func checkSkimmableBody(_ node: VariableDeclSyntax) {
        // Count lines in the body
        let bodyText = node.description
        let lines = bodyText.split(separator: "\n", omittingEmptySubsequences: false)
        let contentLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && !trimmed.hasPrefix("var body") && trimmed != "}" && trimmed != "{"
        }

        if contentLines.count > 15 {
            let violation = "⚠️ SwiftUI View body has \(contentLines.count) lines (maximum: 15)"
            violations.append(violation)
            print(violation)
        }
    }

    private func checkNoGroupBody(_ node: VariableDeclSyntax) {
        // Look for Group as top-level view
        guard let binding = node.bindings.first,
              let accessor = binding.accessorBlock
        else {
            return
        }

        let bodyText = accessor.description
        let lines = bodyText.split(separator: "\n")

        // Look for Group as the first view in the body
        var foundFirstView = false
        var groupLineIndex = -1

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty, !trimmed.contains("get"), !trimmed.contains("var body"), trimmed != "{", trimmed != "}" {
                if !foundFirstView {
                    if trimmed.hasPrefix("Group {") || trimmed.hasPrefix("Group(") || trimmed == "Group {" {
                        groupLineIndex = index
                        foundFirstView = true
                    } else {
                        // Found a different view type, no Group violation
                        break
                    }
                }
            }
        }

        // If we found a Group, check if it has view modifiers
        if groupLineIndex >= 0 {
            let hasModifiers = checkForViewModifiers(lines: lines, groupLineIndex: groupLineIndex)
            if !hasModifiers {
                let violation = "⚠️ SwiftUI View body should not have Group as the top-level view (unless it has view modifiers)"
                violations.append(violation)
                print(violation)
            }
        }
    }

    private func checkForViewModifiers(lines: [Substring], groupLineIndex: Int) -> Bool {
        // Look for lines after the Group closing brace that start with a dot (view modifiers)
        var braceCount = 0
        var inGroupBody = false

        for i in groupLineIndex ..< lines.count {
            let trimmed = lines[i].trimmingCharacters(in: .whitespaces)

            // Track braces to know when we're done with the Group body
            if trimmed.contains("Group {") {
                inGroupBody = true
                braceCount += 1
            } else if inGroupBody {
                braceCount += trimmed.count(where: { $0 == "{" })
                braceCount -= trimmed.count(where: { $0 == "}" })

                // When we close the Group body, check the next lines for modifiers
                if braceCount == 0 {
                    // Check if the next non-empty line starts with a dot (view modifier)
                    for j in (i + 1) ..< lines.count {
                        let nextTrimmed = lines[j].trimmingCharacters(in: .whitespaces)
                        if !nextTrimmed.isEmpty {
                            if nextTrimmed.hasPrefix(".") {
                                return true // Found a view modifier
                            } else {
                                return false // Found something else, no modifier
                            }
                        }
                    }
                    return false // No more lines after Group
                }
            }
        }
        return false
    }

    private func checkOneTopLevelView(_ node: VariableDeclSyntax) {
        // Look for multiple top-level statements in the body
        guard let binding = node.bindings.first,
              let accessor = binding.accessorBlock
        else {
            return
        }

        let bodyText = accessor.description
        let lines = bodyText.split(separator: "\n")

        // Count top-level statements (not nested inside other views)
        var viewStatements = 0
        var braceLevel = 0
        var inBodyContent = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and getter syntax
            if trimmed.isEmpty || trimmed.contains("get") || trimmed.contains("var body") {
                continue
            }

            // Track brace level to know if we're at top level
            braceLevel += trimmed.count(where: { $0 == "{" })
            braceLevel -= trimmed.count(where: { $0 == "}" })

            // We're in the body content area after the first opening brace
            if !inBodyContent, braceLevel > 0 {
                inBodyContent = true
            }

            // Only count statements at the immediate top level (braceLevel == 1)
            if inBodyContent, braceLevel == 1 {
                // Check if this line starts a view statement (not a property or modifier)
                if trimmed.first?.isUppercase == true ||
                    trimmed.contains("Text(") ||
                    trimmed.contains("Button(") ||
                    trimmed.contains("Image(") ||
                    trimmed.contains("Color.") ||
                    trimmed.contains("Stack") ||
                    trimmed.contains("Group") ||
                    trimmed.contains("Spacer("),
                    !trimmed.hasPrefix(".")
                { // Not a view modifier
                    viewStatements += 1
                }
            }
        }

        if viewStatements > 1 {
            let violation = "⚠️ SwiftUI View body has \(viewStatements) top-level views (should be exactly 1)"
            violations.append(violation)
            print(violation)
        }
    }

    func getViolations() -> [String] {
        violations
    }
}

// Test the rules
if CommandLine.arguments.count > 1 {
    let filePath = CommandLine.arguments[1]
    let url = URL(fileURLWithPath: filePath)

    do {
        let sourceCode = try String(contentsOf: url)
        let tree = Parser.parse(source: sourceCode)
        let visitor = CustomRulesVisitor(viewMode: .sourceAccurate)
        visitor.walk(tree)

        let violations = visitor.getViolations()
        if violations.isEmpty {
            print("✅ No violations found")
        } else {
            print("Found \(violations.count) violation(s)")
        }
    } catch {
        print("Error reading file: \(error)")
    }
} else {
    print("Usage: swift test-custom-rule.swift <file.swift>")
}
