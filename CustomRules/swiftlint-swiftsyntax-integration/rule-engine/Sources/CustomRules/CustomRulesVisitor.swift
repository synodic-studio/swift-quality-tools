import Foundation
import SwiftSyntax

/// Main coordinator for all custom SwiftLint rules
///
/// Rule identifiers (9 total):
/// - skimmable_body: View body line count limit (max 15 lines)
/// - no_group_body: Prohibit top-level Group in View bodies
/// - one_top_level_view: Enforce single top-level view in View bodies
/// - excessive_nesting: Indentation depth limit for all code (max 4 levels)
/// - view_structure_order: Enforce View property ordering
/// - no_wrapper_body: Detect pointless wrapper body properties
/// - constants_enum_usage: Detect magic numbers, suggest Constants enum
/// - blank_line_import_separation: Enforce blank line between regular and @testable imports
/// - preview_required: Every file with View/ViewModifier must have at least one #Preview
public final class CustomRulesVisitor: SyntaxVisitor {
    private var violations: [String] = []
    private var currentStructDecl: StructDeclSyntax?
    private var isInSwiftUIView = false

    override public func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        // Check if this struct conforms to View protocol
        let conformsToView = node.inheritanceClause?.inheritedTypes.contains { inherited in
            inherited.type.description.trimmingCharacters(in: .whitespaces).contains("View")
        } ?? false

        if conformsToView {
            currentStructDecl = node
            isInSwiftUIView = true

            // Rule: view_structure_order
            // DISABLED: Rule has bugs with computed property detection
            // See: docs/TODO-view-structure-order-fix.md
            // ViewStructureRules.checkViewStructureOrder(node, violations: &violations)
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
                ViewBodyRules.checkSkimmableBody(node, violations: &violations)
                ViewBodyRules.checkNoGroupBody(node, violations: &violations)
                ViewBodyRules.checkOneTopLevelView(node, violations: &violations)

                // ViewStructureRules
                ViewStructureRules.checkNoWrapperBody(node, violations: &violations)
            }
        }

        return .visitChildren
    }

    override public func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
        // ImportRules
        ImportRules.checkBlankLineImportSeparation(node, violations: &violations)

        // PreviewRules
        PreviewRules.checkPreviewRequired(node, violations: &violations)

        return .visitChildren
    }

    override public func visit(_ node: IntegerLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        // CodeQualityRules: Magic numbers
        CodeQualityRules.checkMagicNumber(node, isInSwiftUIView: isInSwiftUIView, violations: &violations)
        return .visitChildren
    }

    override public func visit(_ node: FloatLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        // CodeQualityRules: Magic float numbers
        CodeQualityRules.checkMagicFloatNumber(node, isInSwiftUIView: isInSwiftUIView, violations: &violations)
        return .visitChildren
    }

    override public func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        // CodeQualityRules: Excessive indentation in functions
        if let body = node.body {
            CodeQualityRules.checkExcessiveIndentationInCodeBlock(body, context: "Function '\(node.name.text)'", violations: &violations)
        }
        return .visitChildren
    }

    override public func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        // CodeQualityRules: Excessive indentation in initializers
        if let body = node.body {
            CodeQualityRules.checkExcessiveIndentationInCodeBlock(body, context: "Initializer", violations: &violations)
        }
        return .visitChildren
    }

    override public func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        // CodeQualityRules: Excessive indentation in closures
        CodeQualityRules.checkExcessiveIndentationInClosure(node, violations: &violations)
        return .visitChildren
    }

    public func getViolations() -> [String] {
        violations
    }
}
