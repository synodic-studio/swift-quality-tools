import SwiftSyntax

/// Rules related to general code quality
/// - excessive_nesting: Max 3 nesting levels (prevents deep nesting, allows modifier chains)
/// - prefer_shorthand_optional_binding: Use shorthand with original name (if let bar, not if let foo = bar)
public enum CodeQualityRules {
    public static func checkExcessiveNesting(_ sourceFile: SourceFileSyntax, violations: inout [String]) {
        let converter = SourceLocationConverter(fileName: "", tree: sourceFile)
        let visitor = NestingDepthVisitor(converter: converter)
        visitor.walk(sourceFile)

        for violation in visitor.violations {
            violations.append(violation)
        }
    }

    /// Check for optional binding renames like `if let foo = bar`
    /// These should use the original name with shorthand: `if let bar`
    public static func checkPreferShorthandOptionalBinding(
        _ sourceFile: SourceFileSyntax,
        violations: inout [String],
    ) {
        let converter = SourceLocationConverter(fileName: "", tree: sourceFile)
        let visitor = ShorthandOptionalBindingVisitor(converter: converter)
        visitor.walk(sourceFile)

        for violation in visitor.violations {
            violations.append(violation)
        }
    }
}

/// Visitor to track nesting depth in code
/// Tracks both CodeBlockSyntax (functions, if statements) and ClosureExprSyntax (trailing closures)
/// Relaxes checking inside #Preview macros where setup code naturally nests deeper
private final class NestingDepthVisitor: SyntaxVisitor {
    private var currentDepth = 0
    private let maxDepth = 3 // Triggers at depth 4, matching ~16 spaces physical indentation
    private let converter: SourceLocationConverter
    fileprivate var violations: [String] = []
    private var isInPreviewMacro = false

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    private func addNestingViolation(at position: AbsolutePosition) {
        let location = converter.location(for: position)
        let violation = """
        ⚠️  [excessive_nesting] Line \(location.line): nesting level \(currentDepth) (max \(maxDepth))
           Extract nested logic to a separate method or computed property.
           Do not flatten by combining conditions or removing structure.
        """
        violations.append(violation)
    }

    // MARK: - Preview macro tracking

    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.macroName.text == "Preview" {
            isInPreviewMacro = true
        }
        return .visitChildren
    }

    override func visitPost(_ node: MacroExpansionDeclSyntax) {
        if node.macroName.text == "Preview" {
            isInPreviewMacro = false
        }
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        if node.macroName.text == "Preview" {
            isInPreviewMacro = true
        }
        return .visitChildren
    }

    override func visitPost(_ node: MacroExpansionExprSyntax) {
        if node.macroName.text == "Preview" {
            isInPreviewMacro = false
        }
    }

    // MARK: - Nesting depth tracking

    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        if currentDepth > maxDepth, !isInPreviewMacro {
            addNestingViolation(at: node.position)
        }
        return .visitChildren
    }

    override func visitPost(_: CodeBlockSyntax) {
        currentDepth -= 1
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        if currentDepth > maxDepth, !isInPreviewMacro {
            addNestingViolation(at: node.position)
        }
        return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) {
        currentDepth -= 1
    }
}

// MARK: - Shorthand Optional Binding Visitor

/// Visitor to detect optional binding renames like `if let foo = bar`
/// When binding name differs from source, suggests using original name with shorthand
private final class ShorthandOptionalBindingVisitor: SyntaxVisitor {
    private let converter: SourceLocationConverter
    fileprivate var violations: [String] = []

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: OptionalBindingConditionSyntax) -> SyntaxVisitorContinueKind {
        // Get the binding pattern name
        guard let pattern = node.pattern.as(IdentifierPatternSyntax.self) else {
            return .visitChildren
        }
        let bindingName = pattern.identifier.text

        // Get the initializer expression - must be a simple identifier
        guard let initializer = node.initializer,
              let sourceExpr = initializer.value.as(DeclReferenceExprSyntax.self)
        else {
            return .visitChildren
        }
        let sourceName = sourceExpr.baseName.text

        // If names differ, it's a rename - flag it
        // Note: if names are the same (foo = foo), SwiftLint's shorthand_optional_binding handles it
        if bindingName != sourceName {
            let location = converter.location(for: node.position)
            let bindingKeyword = node.bindingSpecifier.text // "let" or "var"
            let violation = "⚠️  [prefer_shorthand_optional_binding] Line \(location.line): " +
                "Use shorthand '\(bindingKeyword) \(sourceName)' instead of renaming '\(bindingKeyword) \(bindingName) = \(sourceName)'"
            violations.append(violation)
        }

        return .visitChildren
    }
}
