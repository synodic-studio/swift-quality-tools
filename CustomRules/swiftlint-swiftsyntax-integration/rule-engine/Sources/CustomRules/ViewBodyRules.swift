import SwiftSyntax

/// Rules related to SwiftUI View body properties
/// - skimmable_body: Line count limit (15 max)
/// - no_group_body: No top-level Group without modifiers
/// - one_top_level_view: Exactly one top-level view
public enum ViewBodyRules {
    public static func checkSkimmableBody(_ node: VariableDeclSyntax, violations: inout [String]) {
        // Count lines in the body
        let bodyText = node.description
        let lines = bodyText.split(separator: "\n", omittingEmptySubsequences: false)
        let contentLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && !trimmed.hasPrefix("var body") && trimmed != "}" && trimmed != "{"
        }

        if contentLines.count > 15 {
            let violation = "⚠️  [skimmable_body] SwiftUI View body has \(contentLines.count) lines (maximum: 15)"
            violations.append(violation)
            print(violation)
        }
    }

    public static func checkNoGroupBody(_ node: VariableDeclSyntax, violations: inout [String]) {
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
                let violation = "⚠️  [no_group_body] SwiftUI View body should not have Group as the top-level view (unless it has view modifiers)"
                violations.append(violation)
                print(violation)
            }
        }
    }

    private static func checkForViewModifiers(lines: [Substring], groupLineIndex: Int) -> Bool {
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

    public static func checkOneTopLevelView(_ node: VariableDeclSyntax, violations: inout [String]) {
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
            let violation = "⚠️  [one_top_level_view] SwiftUI View body has \(viewStatements) top-level views (should be exactly 1)"
            violations.append(violation)
            print(violation)
        }
    }
}
