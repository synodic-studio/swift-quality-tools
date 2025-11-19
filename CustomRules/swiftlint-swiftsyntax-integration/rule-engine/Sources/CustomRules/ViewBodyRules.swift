import SwiftSyntax

/// Rules related to SwiftUI View body properties
/// - skimmable_body: Line count limit (15 max)
/// - no_group_body: No Group usage without modifiers (use @ViewBuilder instead)
/// - one_top_level_view: Exactly one top-level view
/// - no_if_modifier: Detect custom .if modifier anti-pattern
public enum ViewBodyRules {
    private static func isRelevantBodyLine(_ trimmed: String) -> Bool {
        !trimmed.isEmpty && !trimmed.contains("get") && !trimmed.contains("var body") && trimmed != "{" && trimmed != "}"
    }

    private static func findFirstGroupView(in lines: [Substring]) -> Int {
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard isRelevantBodyLine(trimmed) else { continue }

            if trimmed.hasPrefix("Group {") || trimmed.hasPrefix("Group(") || trimmed == "Group {" {
                return index
            } else {
                return -1 // Found a different view type
            }
        }
        return -1
    }

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
        let groupLineIndex = findFirstGroupView(in: lines)

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
                continue
            }

            guard inGroupBody else { continue }

            braceCount += trimmed.count(where: { $0 == "{" })
            braceCount -= trimmed.count(where: { $0 == "}" })

            // When we close the Group body, check the next lines for modifiers
            if braceCount == 0 {
                return checkNextLineForModifier(lines: lines, afterIndex: i)
            }
        }
        return false
    }

    private static func checkNextLineForModifier(lines: [Substring], afterIndex: Int) -> Bool {
        // Check if the next non-empty line starts with a dot (view modifier)
        for j in (afterIndex + 1) ..< lines.count {
            let nextTrimmed = lines[j].trimmingCharacters(in: .whitespaces)
            if !nextTrimmed.isEmpty {
                return nextTrimmed.hasPrefix(".")
            }
        }
        return false // No more lines after Group
    }

    private static func isViewStatement(_ trimmed: String) -> Bool {
        // Check if this line starts a view statement (not a property or modifier)
        guard !trimmed.hasPrefix(".") else { return false } // Not a view modifier

        return trimmed.first?.isUppercase == true ||
            trimmed.contains("Text(") ||
            trimmed.contains("Button(") ||
            trimmed.contains("Image(") ||
            trimmed.contains("Color.") ||
            trimmed.contains("Stack") ||
            trimmed.contains("Group") ||
            trimmed.contains("Spacer(")
    }

    /// Check if a Group initializer has view modifiers applied
    /// - Parameter node: The function call expression node
    /// - Returns: True if the Group has modifiers
    private static func groupHasModifiers(_ node: FunctionCallExprSyntax) -> Bool {
        // Walk up the syntax tree to see if this Group is part of a modifier chain
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            // Check if parent is a MemberAccessExprSyntax (e.g., .padding(), .background())
            if parent.as(MemberAccessExprSyntax.self) != nil {
                // The member access's base should be our Group (or a chain containing it)
                return true
            }

            // Check if parent is a FunctionCallExprSyntax with our node as the called expression
            if let functionCall = parent.as(FunctionCallExprSyntax.self) {
                // This means our Group is being used as the base for a modifier call
                if functionCall.calledExpression.description.contains(node.description) {
                    return true
                }
            }

            current = parent
        }

        return false
    }

    /// Check for Group usage without modifiers anywhere in SwiftUI code
    /// If Group has no modifiers, suggest using @ViewBuilder instead
    public static func checkGroupWithoutModifiers(_ node: FunctionCallExprSyntax, violations: inout [String]) {
        // Check if this is a Group initializer
        let calledExpr = node.calledExpression.description.trimmingCharacters(in: .whitespaces)

        guard calledExpr == "Group" else {
            return
        }

        // Check if the Group has modifiers
        if !groupHasModifiers(node) {
            let violation = "⚠️  [no_group_body] Avoid Group without modifiers - use @ViewBuilder instead for multiple views"
            violations.append(violation)
            print(violation)
        }
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
            if inBodyContent, braceLevel == 1, isViewStatement(trimmed) {
                viewStatements += 1
            }
        }

        if viewStatements > 1 {
            let violation = "⚠️  [one_top_level_view] SwiftUI View body has \(viewStatements) top-level views (should be exactly 1)"
            violations.append(violation)
            print(violation)
        }
    }

    /// Detect custom .if modifier anti-pattern
    /// Suggests using standard SwiftUI patterns instead (ternary, @ViewBuilder, etc.)
    public static func checkNoIfModifier(_ node: FunctionCallExprSyntax, violations: inout [String]) {
        // Check if this is a call to .if(
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "if"
        else {
            return
        }

        let violation = """
        ⚠️  [no_if_modifier] Avoid custom .if modifier - use standard SwiftUI patterns instead
           • For simple conditionals: .foregroundColor(condition ? .red : .blue)
           • For complex cases: Use @ViewBuilder with if/else
           • Rationale: .if bypasses SwiftUI's view identity system
        """
        violations.append(violation)
        print(violation)
    }
}
