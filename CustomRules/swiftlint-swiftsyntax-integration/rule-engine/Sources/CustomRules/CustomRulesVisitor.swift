import Foundation
import SwiftSyntax

// Reason: SwiftSyntax visitors match nested tree shapes (decl → binding → type →
// call → closure); depth-4 traversal is intrinsic to AST matching. excessive_nesting
// is a SwiftUI view-code readability heuristic and does not fit traversal internals.
// swiftskim:disable excessive_nesting

/// Main coordinator for all custom SwiftLint rules.
///
/// The canonical list of rule identifiers and summaries lives in
/// `RuleRegistry.all` (the single source of truth). Each `shouldRun("id")`
/// dispatch site below must use an `id` that exists in that registry.
public final class CustomRulesVisitor: SyntaxVisitor {
    private var violations: [String] = []
    private var currentStructDecl: StructDeclSyntax?
    private var isInSwiftUIView = false
    private let directiveParser = DirectiveParser()
    private var locationConverter: SourceLocationConverter?

    /// Set of enabled rule IDs. If nil, all rules are enabled.
    private var enabledRules: Set<String>?

    /// Set of disabled rule IDs (a denylist subtracted after the enabled filter).
    private var disabledRules: Set<String> = []

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

    /// Set which rules must not run (a denylist). Empty or nil clears it.
    public func setDisabledRules(_ rules: [String]?) {
        disabledRules = Set(rules ?? [])
    }

    /// Check if a rule should run: the denylist wins, then the enabled filter.
    private func shouldRun(_ ruleID: String) -> Bool {
        if disabledRules.contains(ruleID) { return false }
        guard let enabledRules else { return true }
        return enabledRules.contains(ruleID)
    }

    /// Add violation with suppression check
    /// - Parameters:
    ///   - ruleID: The rule identifier
    ///   - node: Syntax node where violation occurred (for line number)
    ///   - message: Violation message
    func addViolation(ruleID: String, node: some SyntaxProtocol, message: String) {
        guard let locationConverter else {
            // Fallback if converter not set
            violations.append("⚠️  [\(ruleID)] \(message)")
            return
        }

        let location = locationConverter.location(for: node.position)
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
        if shouldRun("no_exported_import") {
            ImportRules.checkNoExportedImport(node, violations: &violations)
        }
        if shouldRun("prefer_swift_testing") {
            ImportRules.checkPreferSwiftTesting(node, violations: &violations)
        }

        // PreviewRules
        if shouldRun("preview_required") {
            PreviewRules.checkPreviewRequired(node, violations: &violations)
        }

        // CodeQualityRules: Excessive nesting (AST-based depth check)
        if shouldRun("excessive_nesting") {
            CodeQualityRules.checkExcessiveNesting(node, violations: &violations)
        }

        // CodeQualityRules: Prefer shorthand optional binding
        if shouldRun("prefer_shorthand_optional_binding") {
            CodeQualityRules.checkPreferShorthandOptionalBinding(node, violations: &violations)
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
        if shouldRun("onchange_ignored_old_value") {
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

    /// Run consumer-supplied rules alongside the built-ins.
    ///
    /// Their structured violations are formatted into the same `⚠️  [id] Line N:`
    /// shape and pass through the identical suppression path via `getViolations()`,
    /// so external rules behave exactly like built-ins (including
    /// `swiftskim:disable`). The built-in dispatch is untouched.
    public func run(externalRules rules: [Rule], on file: SourceFileSyntax) {
        guard let locationConverter else { return }
        let context = RuleContext(converter: locationConverter)
        for rule in rules where shouldRun(rule.id) {
            for violation in rule.check(file, context: context) {
                appendExternalViolation(violation)
            }
        }
    }

    /// Format a structured violation into the shared string representation.
    private func appendExternalViolation(_ violation: Violation) {
        let prefix = "⚠️  [\(violation.ruleID)]"
        violations.append(
            violation.line > 0
                ? "\(prefix) Line \(violation.line): \(violation.message)"
                : "\(prefix) \(violation.message)",
        )
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
