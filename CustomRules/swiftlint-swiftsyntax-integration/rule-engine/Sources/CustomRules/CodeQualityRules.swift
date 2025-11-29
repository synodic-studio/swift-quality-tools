import SwiftSyntax

/// Rules related to general code quality
/// - excessive_nesting: Max 3 nesting levels (prevents deep nesting, allows modifier chains)
public enum CodeQualityRules {
    public static func checkExcessiveNesting(_ sourceFile: SourceFileSyntax, violations: inout [String]) {
        let converter = SourceLocationConverter(fileName: "", tree: sourceFile)
        let visitor = NestingDepthVisitor(converter: converter)
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
