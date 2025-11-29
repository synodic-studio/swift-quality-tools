import SwiftSyntax

/// Rules related to modifier formatting and line structure
/// - single_modifier_per_line: Each SwiftUI modifier should be on its own line for readability
public enum ModifierFormattingRules {
    /// Check for multiple SwiftUI modifiers on the same line
    /// Only flags within View/ViewModifier body contexts
    public static func checkSingleModifierPerLine(
        _ sourceFile: SourceFileSyntax,
        violations: inout [String],
    ) {
        let converter = SourceLocationConverter(fileName: "", tree: sourceFile)
        let visitor = ModifierLineVisitor(converter: converter)
        visitor.walk(sourceFile)

        for violation in visitor.violations {
            violations.append(violation)
        }
    }
}

/// Visitor to detect multiple SwiftUI modifiers on the same line
private final class ModifierLineVisitor: SyntaxVisitor {
    private let converter: SourceLocationConverter
    private var isInViewBody = false
    private var modifierLineNumbers: [Int: Int] = [:] // line -> count of modifier chains on that line
    private var reportedLines: Set<Int> = []
    fileprivate var violations: [String] = []

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    /// Track when we enter a View body (var body: some View)
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard let binding = node.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              identifier.identifier.text == "body",
              let typeAnnotation = binding.typeAnnotation,
              typeAnnotation.description.contains("some View")
        else {
            return .visitChildren
        }

        isInViewBody = true
        return .visitChildren
    }

    override func visitPost(_ node: VariableDeclSyntax) {
        guard let binding = node.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
              identifier.identifier.text == "body"
        else {
            return
        }
        isInViewBody = false
        modifierLineNumbers.removeAll()
        reportedLines.removeAll()
    }

    /// Track when we enter a function returning some View (including ViewModifier body)
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if function returns some View
        guard let returnClause = node.signature.returnClause,
              returnClause.type.description.contains("some View")
        else {
            return .visitChildren
        }

        isInViewBody = true
        return .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        // Reset if we were in a function returning some View
        guard let returnClause = node.signature.returnClause,
              returnClause.type.description.contains("some View")
        else {
            return
        }
        isInViewBody = false
        modifierLineNumbers.removeAll()
        reportedLines.removeAll()
    }

    /// Check for modifier chains (FunctionCallExpr with MemberAccessExpr base)
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard isInViewBody else { return .visitChildren }

        // Check if this is a modifier call (called via member access on another expression)
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.base != nil
        else {
            return .visitChildren
        }

        // Skip method calls that are nested inside another call's argument list
        // This filters out cases like `geometry.frame(in: .local)` inside `.position(...)`
        if isInsideArgumentList(node) {
            return .visitChildren
        }

        // Get the line number of this modifier's period (the . in .modifier())
        let thisModifierLine = converter.location(for: memberAccess.period.position).line

        // Get the line of this call's closing paren
        guard let rightParen = node.rightParen else { return .visitChildren }
        let thisEndLine = converter.location(for: rightParen.position).line

        // If the modifier starts and ends on the same line, count it as a chained modifier on that line
        // This catches cases like .padding().background() where both are on same line
        if thisModifierLine == thisEndLine {
            modifierLineNumbers[thisModifierLine, default: 0] += 1

            // Flag when we see 2+ modifiers on the same line
            if (modifierLineNumbers[thisModifierLine] ?? 0) >= 2, !reportedLines.contains(thisModifierLine) {
                reportedLines.insert(thisModifierLine)
                let violation = "⚠️  [single_modifier_per_line] Line \(thisModifierLine): Multiple modifiers on same line - place each modifier on its own line for readability"
                violations.append(violation)
            }
        }

        return .visitChildren
    }

    /// Check if this node is inside another function call's argument list
    private func isInsideArgumentList(_ node: FunctionCallExprSyntax) -> Bool {
        var current: Syntax? = node._syntaxNode.parent
        while let parent = current {
            // If we hit a LabeledExprSyntax, we're inside an argument
            if parent.is(LabeledExprSyntax.self) {
                return true
            }
            // If we hit another FunctionCallExpr before a modifier chain, check if we're in its arguments
            if let funcCall = parent.as(FunctionCallExprSyntax.self) {
                // Check if node is in funcCall's argument list (not its calledExpression)
                if funcCall.arguments.contains(where: { arg in
                    arg.expression.id == node.id || isDescendant(node, of: arg.expression)
                }) {
                    return true
                }
            }
            current = parent.parent
        }
        return false
    }

    /// Check if child is a descendant of parent
    private func isDescendant(_ child: FunctionCallExprSyntax, of parent: ExprSyntax) -> Bool {
        var current: Syntax? = child._syntaxNode
        while let node = current {
            if node.id == parent.id {
                return true
            }
            current = node.parent
        }
        return false
    }

    /// Check for modifier after closing delimiter: ).modifier()
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard isInViewBody else { return .visitChildren }

        // Check if this member access follows a closing paren on a different line
        guard let base = node.base else { return .visitChildren }

        // Get positions
        let dotLocation = converter.location(for: node.period.position)
        let dotLine = dotLocation.line

        // Check if the base ends on a previous line (multiline expression)
        let baseEndLocation = converter.location(for: base.endPosition)
        let baseEndLine = baseEndLocation.line

        // If base ends on same line as dot, check if line starts with closing delimiter
        if baseEndLine == dotLine {
            // Get the source text for this line to check if it starts with )
            let sourceText = node.root.description
            let lines = sourceText.split(separator: "\n", omittingEmptySubsequences: false)

            if dotLine > 0, dotLine <= lines.count {
                let lineContent = String(lines[dotLine - 1]).trimmingCharacters(in: .whitespaces)

                // Check if line starts with ) or ] followed by .
                if let firstChar = lineContent.first,
                   firstChar == ")" || firstChar == "]",
                   !reportedLines.contains(dotLine)
                {
                    // Verify there's a dot after the closing delimiters
                    var idx = lineContent.startIndex
                    while idx < lineContent.endIndex, lineContent[idx] == ")" || lineContent[idx] == "]" {
                        idx = lineContent.index(after: idx)
                    }
                    if idx < lineContent.endIndex, lineContent[idx] == "." {
                        reportedLines.insert(dotLine)
                        let violation = "⚠️  [single_modifier_per_line] Line \(dotLine): Modifier chained on same line as closing delimiter - place modifier on its own line"
                        violations.append(violation)
                    }
                }
            }
        }

        return .visitChildren
    }
}
