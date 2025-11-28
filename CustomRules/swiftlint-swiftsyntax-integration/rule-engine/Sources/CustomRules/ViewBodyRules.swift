import SwiftSyntax

/// Rules related to SwiftUI View body properties
/// - skimmable_body: Line count limit (15 max) - applies to View body and ViewModifier body
/// - no_group_body: No Group usage without modifiers (use @ViewBuilder instead)
/// - one_top_level_view: Exactly one top-level view
/// - no_if_modifier: Detect custom .if modifier anti-pattern
/// - no_if_without_else: Detect if-without-else in @ViewBuilder (visibility logic should be hoisted to parent)
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

    private static let maxBodyLines = 15

    public static func checkSkimmableBody(
        _ node: VariableDeclSyntax,
        converter: SourceLocationConverter?,
        violations: inout [String],
    ) {
        // Count lines in the body
        let bodyText = node.description
        let lines = bodyText.split(separator: "\n", omittingEmptySubsequences: false)
        let contentLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && !trimmed.hasPrefix("var body") && trimmed != "}" && trimmed != "{"
        }

        if contentLines.count > maxBodyLines {
            let lineInfo = converter.map { "Line \($0.location(for: node.positionAfterSkippingLeadingTrivia).line): " } ?? ""
            let violation = "⚠️  [skimmable_body] \(lineInfo)SwiftUI View body has \(contentLines.count) lines (maximum: \(maxBodyLines))"
            violations.append(violation)
        }
    }

    /// Check line count in ViewModifier body function
    /// ViewModifiers use `func body(content: Content) -> some View` instead of `var body`
    public static func checkSkimmableViewModifierBody(
        _ node: FunctionDeclSyntax,
        converter: SourceLocationConverter?,
        violations: inout [String],
    ) {
        // Verify this is a body function with content parameter
        guard node.name.text == "body",
              let firstParam = node.signature.parameterClause.parameters.first,
              firstParam.firstName.text == "content"
        else {
            return
        }

        // Count lines in the function body
        guard let body = node.body else { return }

        let bodyText = body.description
        let lines = bodyText.split(separator: "\n", omittingEmptySubsequences: false)
        let contentLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && trimmed != "}" && trimmed != "{"
        }

        if contentLines.count > maxBodyLines {
            let lineInfo = converter.map { "Line \($0.location(for: node.positionAfterSkippingLeadingTrivia).line): " } ?? ""
            let violation = "⚠️  [skimmable_body] \(lineInfo)ViewModifier body has \(contentLines.count) lines (maximum: \(maxBodyLines))"
            violations.append(violation)
        }
    }

    public static func checkNoGroupBody(
        _ node: VariableDeclSyntax,
        converter: SourceLocationConverter?,
        violations: inout [String],
    ) {
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
                let lineInfo = converter.map { "Line \($0.location(for: node.positionAfterSkippingLeadingTrivia).line): " } ?? ""
                let violation = "⚠️  [no_group_body] \(lineInfo)SwiftUI View body should not have Group as the top-level view (unless it has view modifiers)"
                violations.append(violation)
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
    public static func checkGroupWithoutModifiers(
        _ node: FunctionCallExprSyntax,
        converter: SourceLocationConverter?,
        violations: inout [String],
    ) {
        // Check if this is a Group initializer
        let calledExpr = node.calledExpression.description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard calledExpr == "Group" else {
            return
        }

        // Check if the Group has modifiers
        if !groupHasModifiers(node) {
            let lineInfo = converter.map { "Line \($0.location(for: node.positionAfterSkippingLeadingTrivia).line): " } ?? ""
            let violation = "⚠️  [no_group_body] \(lineInfo)Avoid Group without modifiers - use @ViewBuilder instead for multiple views"
            violations.append(violation)
        }
    }

    public static func checkOneTopLevelView(
        _ node: VariableDeclSyntax,
        converter: SourceLocationConverter?,
        violations: inout [String],
    ) {
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
            let lineInfo = converter.map { "Line \($0.location(for: node.positionAfterSkippingLeadingTrivia).line): " } ?? ""
            let violation = "⚠️  [one_top_level_view] \(lineInfo)SwiftUI View body has \(viewStatements) top-level views (should be exactly 1)"
            violations.append(violation)
        }
    }

    /// Detect custom .if modifier anti-pattern
    /// Suggests using standard SwiftUI patterns instead (ternary, @ViewBuilder, etc.)
    public static func checkNoIfModifier(
        _ node: FunctionCallExprSyntax,
        converter: SourceLocationConverter?,
        violations: inout [String],
    ) {
        // Check if this is a call to .if(
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "if"
        else {
            return
        }

        let lineInfo = converter.map { "Line \($0.location(for: node.positionAfterSkippingLeadingTrivia).line): " } ?? ""
        let violation = """
        ⚠️  [no_if_modifier] \(lineInfo)Avoid custom .if modifier - use standard SwiftUI patterns instead
           • For simple conditionals: .foregroundColor(condition ? .red : .blue)
           • For complex cases: Use @ViewBuilder with if/else
           • Rationale: .if bypasses SwiftUI's view identity system
        """
        violations.append(violation)
    }

    /// Detect if-without-else in @ViewBuilder contexts
    /// A view should not decide its own visibility - hoist the condition to the parent
    ///
    /// However, if the `if` is one of multiple siblings in a container, it's fine -
    /// that's just conditionally showing a section, not controlling the view's existence.
    public static func checkNoIfWithoutElse(
        _ node: IfExprSyntax,
        converter: SourceLocationConverter?,
        violations: inout [String],
    ) {
        // Only flag if there's no else branch
        guard node.elseBody == nil else { return }

        // Check if we're in a @ViewBuilder context by walking up the tree
        guard isInViewBuilderContext(node) else { return }

        // If the `if` has multiple siblings, it's fine - it's just one conditional section among many
        // Only flag when the `if` is the sole/primary content (controlling the view's existence)
        guard !hasMultipleSiblings(node) else { return }

        let lineInfo = converter.map { "Line \($0.location(for: node.positionAfterSkippingLeadingTrivia).line): " } ?? ""
        let violation = """
        ⚠️  [no_if_without_else] \(lineInfo)Avoid if-without-else in @ViewBuilder - hoist visibility to the CALLER
           • WRONG: `else { EmptyView() }` - same identity problem, just hidden
           • WRONG: `.opacity(condition ? 1 : 0)` - view still in hierarchy, wastes resources
           • WRONG: extracting to computed property - moves problem, doesn't fix it
           • RIGHT: remove the condition entirely; let the parent/caller decide whether to show this view
           • This may require changes in another file where this view is instantiated
        """
        violations.append(violation)
    }

    /// Check if the node has multiple siblings in its parent code block
    /// If true, the `if` is just one of several items (fine)
    /// If false, the `if` is the sole/primary content (problematic)
    private static func hasMultipleSiblings(_ node: IfExprSyntax) -> Bool {
        // Walk up to find the FIRST containing CodeBlockItemListSyntax
        // Only check that immediate container - don't walk up to file level
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            // Found the code block item list (e.g., inside a closure or function body)
            if let codeBlockItemList = parent.as(CodeBlockItemListSyntax.self) {
                // Before returning, check if this code block is inside a switch case
                // If so, treat multiple switch cases as "siblings"
                if let grandparent = codeBlockItemList.parent,
                   let switchCase = grandparent.as(SwitchCaseSyntax.self),
                   let switchExpr = findParentSwitch(switchCase),
                   switchExpr.cases.count > 1
                {
                    return true
                }

                // Count siblings - if more than 1 item, we have siblings
                // Return immediately - only check the first/immediate container
                return codeBlockItemList.count > 1
            }

            current = parent
        }

        return false
    }

    /// Find the parent SwitchExprSyntax for a switch case
    private static func findParentSwitch(_ switchCase: SwitchCaseSyntax) -> SwitchExprSyntax? {
        var current: Syntax? = Syntax(switchCase)
        while let parent = current?.parent {
            if let switchExpr = parent.as(SwitchExprSyntax.self) {
                return switchExpr
            }
            current = parent
        }
        return nil
    }

    /// Check if a node is inside a @ViewBuilder context
    private static func isInViewBuilderContext(_ node: some SyntaxProtocol) -> Bool {
        var current: Syntax? = Syntax(node)

        while let parent = current?.parent {
            // Check for @ViewBuilder on a computed property
            if let varDecl = parent.as(VariableDeclSyntax.self) {
                if hasViewBuilderAttribute(varDecl.attributes) {
                    return true
                }
                // Also check if it returns `some View` (implicit @ViewBuilder in body)
                if let binding = varDecl.bindings.first,
                   let typeAnnotation = binding.typeAnnotation,
                   typeAnnotation.description.contains("some View")
                {
                    return true
                }
            }

            // Check for @ViewBuilder on a function
            if let funcDecl = parent.as(FunctionDeclSyntax.self) {
                if hasViewBuilderAttribute(funcDecl.attributes) {
                    return true
                }
                // Check return type
                if let returnClause = funcDecl.signature.returnClause,
                   returnClause.description.contains("some View")
                {
                    return true
                }
            }

            current = parent
        }

        return false
    }

    /// Check if attributes contain @ViewBuilder
    private static func hasViewBuilderAttribute(_ attributes: AttributeListSyntax) -> Bool {
        attributes.contains { attr in
            guard let attrSyntax = attr.as(AttributeSyntax.self) else { return false }
            return attrSyntax.attributeName.trimmedDescription == "ViewBuilder"
        }
    }
}
