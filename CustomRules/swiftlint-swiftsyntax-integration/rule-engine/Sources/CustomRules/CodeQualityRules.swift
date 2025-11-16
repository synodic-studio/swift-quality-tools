import SwiftSyntax

/// Rules related to general code quality
/// - constants_enum_usage: No magic numbers
/// - excessive_nesting: Max 4 indentation levels
public enum CodeQualityRules {
    public static func checkMagicNumber(_ node: IntegerLiteralExprSyntax, isInSwiftUIView: Bool, violations: inout [String]) {
        let value = node.literal.text

        // Ignore common safe values (0, 1, 2) and array indices
        let safeValues = ["0", "1", "2"]
        if safeValues.contains(value) {
            return
        }

        // Only flag if we're in a SwiftUI View context
        guard isInSwiftUIView else { return }

        let violation = "⚠️  [constants_enum_usage] Magic number '\(value)' detected - consider using an enum Constants pattern at the top of the type"
        violations.append(violation)
        print(violation)
    }

    public static func checkMagicFloatNumber(_ node: FloatLiteralExprSyntax, isInSwiftUIView: Bool, violations: inout [String]) {
        let value = node.literal.text

        // Ignore common safe values (0.0, 1.0, 0.5)
        let safeValues = ["0.0", "1.0", "0.5", "0", "1"]
        if safeValues.contains(value) {
            return
        }

        // Only flag if we're in a SwiftUI View context
        guard isInSwiftUIView else { return }

        let violation = "⚠️  [constants_enum_usage] Magic number '\(value)' detected - consider using an enum Constants pattern at the top of the type"
        violations.append(violation)
        print(violation)
    }

    public static func checkExcessiveIndentationInCodeBlock(_ block: CodeBlockSyntax, context: String, violations: inout [String]) {
        let depthTracker = IndentationDepthTracker(viewMode: .sourceAccurate)
        depthTracker.walk(block)

        if let maxDepth = depthTracker.maxDepth, maxDepth > 4 {
            let violation = "⚠️  [excessive_nesting] \(context) has excessive indentation depth (\(maxDepth) levels, maximum: 4) - consider refactoring"
            violations.append(violation)
            print(violation)
        }
    }

    public static func checkExcessiveIndentationInClosure(_ closure: ClosureExprSyntax, violations: inout [String]) {
        let depthTracker = IndentationDepthTracker(viewMode: .sourceAccurate)
        depthTracker.walk(closure)

        if let maxDepth = depthTracker.maxDepth, maxDepth > 4 {
            let violation = "⚠️  [excessive_nesting] Closure has excessive indentation depth (\(maxDepth) levels, maximum: 4) - consider refactoring"
            violations.append(violation)
            print(violation)
        }
    }
}

/// Tracks indentation depth through syntax tree
final class IndentationDepthTracker: SyntaxVisitor {
    private(set) var maxDepth: Int?
    private var currentDepth = 0

    override func visit(_: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        maxDepth = max(maxDepth ?? 0, currentDepth)
        return .visitChildren
    }

    override func visitPost(_: CodeBlockSyntax) {
        currentDepth -= 1
    }

    override func visit(_: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        maxDepth = max(maxDepth ?? 0, currentDepth)
        return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) {
        currentDepth -= 1
    }

    override func visit(_: IfExprSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        maxDepth = max(maxDepth ?? 0, currentDepth)
        return .visitChildren
    }

    override func visitPost(_: IfExprSyntax) {
        currentDepth -= 1
    }

    override func visit(_: SwitchExprSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        maxDepth = max(maxDepth ?? 0, currentDepth)
        return .visitChildren
    }

    override func visitPost(_: SwitchExprSyntax) {
        currentDepth -= 1
    }

    override func visit(_: ForStmtSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        maxDepth = max(maxDepth ?? 0, currentDepth)
        return .visitChildren
    }

    override func visitPost(_: ForStmtSyntax) {
        currentDepth -= 1
    }

    override func visit(_: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        maxDepth = max(maxDepth ?? 0, currentDepth)
        return .visitChildren
    }

    override func visitPost(_: WhileStmtSyntax) {
        currentDepth -= 1
    }

    override func visit(_: GuardStmtSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1
        maxDepth = max(maxDepth ?? 0, currentDepth)
        return .visitChildren
    }

    override func visitPost(_: GuardStmtSyntax) {
        currentDepth -= 1
    }
}
