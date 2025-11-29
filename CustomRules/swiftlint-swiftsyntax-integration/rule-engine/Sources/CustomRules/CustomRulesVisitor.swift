import Foundation
import SwiftSyntax

/// Main coordinator for all custom SwiftLint rules
///
/// Rule identifiers (13 total):
/// - skimmable_body: View/ViewModifier body line count limit (max 15 lines)
/// - no_group_body: Prohibit Group without modifiers (use @ViewBuilder instead)
/// - one_top_level_view: Enforce single top-level view in View bodies
/// - no_if_modifier: Detect custom .if modifier anti-pattern
/// - no_if_without_else: Detect if-without-else in @ViewBuilder (hoist visibility to parent)
/// - excessive_nesting: AST-based nesting depth limit (max 3 levels)
/// - view_structure_order: Enforce View property ordering
/// - no_wrapper_body: Detect pointless wrapper body properties
/// - blank_line_import_separation: Enforce blank line between regular and @testable imports
/// - preview_required: Every file with View/ViewModifier must have at least one #Preview
/// - stack_minimum_children: Stacks must have at least 2 children (or special cases)
/// - prefer_zero_param_onchange: Use 0-param onChange when old value is ignored
/// - single_modifier_per_line: Each modifier on its own line for readability
public final class CustomRulesVisitor: SyntaxVisitor {
    private var violations: [String] = []
    private var currentStructDecl: StructDeclSyntax?
    private var isInSwiftUIView = false
    private let directiveParser = DirectiveParser()
    private var locationConverter: SourceLocationConverter?

    /// Set of enabled rule IDs. If nil, all rules are enabled.
    private var enabledRules: Set<String>?

    /// Initialize visitor with source code for directive parsing
    public func setSourceCode(_ source: String, sourceFile: SourceFileSyntax) {
        directiveParser.parseDirectives(from: source)
        locationConverter = SourceLocationConverter(fileName: "", tree: sourceFile)
    }

    /// Set which rules should run. If nil or empty, all rules run.
    public func setEnabledRules(_ rules: [String]?) {
        if let rules, !rules.isEmpty {
            enabledRules = Set(rules)
        } else {
            enabledRules = nil
        }
    }

    /// Check if a rule should run based on enabledRules filter
    private func shouldRun(_ ruleID: String) -> Bool {
        guard let enabled = enabledRules else { return true }
        return enabled.contains(ruleID)
    }

    /// Add violation with suppression check
    /// - Parameters:
    ///   - ruleID: The rule identifier
    ///   - node: Syntax node where violation occurred (for line number)
    ///   - message: Violation message
    func addViolation(ruleID: String, node: some SyntaxProtocol, message: String) {
        guard let converter = locationConverter else {
            // Fallback if converter not set
            violations.append("⚠️  [\(ruleID)] \(message)")
            return
        }

        let location = converter.location(for: node.position)
        let line = location.line

        // Check if rule is suppressed for this line
        guard !directiveParser.isSuppressed(rule: ruleID, line: line) else {
            return
        }

        let violation = line > 0
            ? "⚠️  [\(ruleID)] Line \(line): \(message)"
            : "⚠️  [\(ruleID)] \(message)"

        violations.append(violation)
    }

    /// Add file-level violation (no line number)
    func addFileViolation(ruleID: String, message: String) {
        // File-level violations can be suppressed with file-level disable
        guard !directiveParser.isSuppressed(rule: ruleID, line: 1) else {
            return
        }

        let violation = "⚠️  [\(ruleID)] \(message)"
        violations.append(violation)
    }

    override public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if this struct conforms to View protocol
        let conformsToView = node.inheritanceClause?.inheritedTypes.contains { inherited in
            inherited.type.description.trimmingCharacters(in: .whitespaces).contains("View")
        } ?? false

        if conformsToView {
            currentStructDecl = node
            isInSwiftUIView = true

            // Rule: view_structure_order
            if shouldRun("view_structure_order") {
                ViewStructureRules.checkViewStructureOrder(node, violations: &violations)
            }
        }

        return .visitChildren
    }

    override public func visitPost(_: StructDeclSyntax) {
        currentStructDecl = nil
        isInSwiftUIView = false
    }

    override public func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
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
                // ViewBodyRules
                if shouldRun("skimmable_body") {
                    ViewBodyRules.checkSkimmableBody(node, converter: locationConverter, violations: &violations)
                }
                if shouldRun("no_group_body") {
                    ViewBodyRules.checkNoGroupBody(node, converter: locationConverter, violations: &violations)
                }
                if shouldRun("one_top_level_view") {
                    ViewBodyRules.checkOneTopLevelView(node, converter: locationConverter, violations: &violations)
                }

                // ViewStructureRules
                if shouldRun("no_wrapper_body") {
                    ViewStructureRules.checkNoWrapperBody(node, converter: locationConverter, violations: &violations)
                }
            }
        }

        return .visitChildren
    }

    override public func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        // ImportRules
        if shouldRun("blank_line_import_separation") {
            ImportRules.checkBlankLineImportSeparation(node, violations: &violations)
        }

        // PreviewRules
        if shouldRun("preview_required") {
            PreviewRules.checkPreviewRequired(node, violations: &violations)
        }

        // CodeQualityRules: Excessive nesting (AST-based depth check)
        if shouldRun("excessive_nesting") {
            CodeQualityRules.checkExcessiveNesting(node, violations: &violations)
        }

        // ModifierFormattingRules: Single modifier per line
        if shouldRun("single_modifier_per_line") {
            ModifierFormattingRules.checkSingleModifierPerLine(node, violations: &violations)
        }

        return .visitChildren
    }

    override public func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        // ViewBodyRules: Check for Group without modifiers
        if shouldRun("no_group_body") {
            ViewBodyRules.checkGroupWithoutModifiers(node, converter: locationConverter, violations: &violations)
        }

        // ViewBodyRules: Check for .if modifier anti-pattern
        if shouldRun("no_if_modifier") {
            ViewBodyRules.checkNoIfModifier(node, converter: locationConverter, violations: &violations)
        }

        // ViewStructureRules: Check stack minimum children
        if shouldRun("stack_minimum_children") {
            ViewStructureRules.checkStackMinimumChildren(node, converter: locationConverter, violations: &violations)
        }

        // OnChangeRules: Check for 2-param onChange with ignored old value
        if shouldRun("prefer_zero_param_onchange") {
            OnChangeRules.checkOnChangeIgnoredOldValue(node, converter: locationConverter, violations: &violations)
        }

        return .visitChildren
    }

    override public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // ViewBodyRules: Check ViewModifier body line count
        if shouldRun("skimmable_body") {
            ViewBodyRules.checkSkimmableViewModifierBody(node, converter: locationConverter, violations: &violations)
        }

        return .visitChildren
    }

    override public func visit(_ node: IfExprSyntax) -> SyntaxVisitorContinueKind {
        // ViewBodyRules: Check for if-without-else in @ViewBuilder
        if shouldRun("no_if_without_else") {
            ViewBodyRules.checkNoIfWithoutElse(node, converter: locationConverter, violations: &violations)
        }

        return .visitChildren
    }

    public func getViolations() -> [String] {
        // Filter out suppressed violations
        violations.filter { violation in
            !isSuppressed(violation)
        }
    }

    /// Check if a violation is suppressed by directives
    private func isSuppressed(_ violation: String) -> Bool {
        // Parse violation format: "⚠️  [rule_id] Line N: message" or "⚠️  [rule_id] message"
        guard let ruleIDRange = violation.range(of: #"\[([^\]]+)\]"#, options: .regularExpression) else {
            return false
        }

        let ruleID = String(violation[ruleIDRange].dropFirst().dropLast())

        // Try to extract line number
        if let lineRange = violation.range(of: #"Line (\d+)"#, options: .regularExpression) {
            let lineText = violation[lineRange]
            if let lineNumberStr = lineText.split(separator: " ").last,
               let lineNumber = Int(lineNumberStr)
            {
                return directiveParser.isSuppressed(rule: ruleID, line: lineNumber)
            }
        }

        // File-level violation (no line number) - check line 1
        return directiveParser.isSuppressed(rule: ruleID, line: 1)
    }
}
