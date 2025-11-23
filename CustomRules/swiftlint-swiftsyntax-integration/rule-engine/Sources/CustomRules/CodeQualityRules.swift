import SwiftSyntax

/// Rules related to general code quality
/// - constants_enum_usage: No magic numbers (DISABLED)
/// - excessive_nesting: Max 3 nesting levels (prevents deep nesting, allows modifier chains)
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
    }

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
private final class NestingDepthVisitor: SyntaxVisitor {
    private var currentDepth = 0
    private let maxDepth = 3 // Triggers at depth 4, matching ~16 spaces physical indentation
    private let converter: SourceLocationConverter
    fileprivate var violations: [String] = []

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: CodeBlockSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1

        if currentDepth > maxDepth {
            let location = converter.location(for: node.position)
            let violation = "⚠️  [excessive_nesting] Line \(location.line) has excessive nesting (level \(currentDepth), maximum: \(maxDepth)) - refactor code to reduce nesting depth"
            violations.append(violation)
        }

        return .visitChildren
    }

    override func visitPost(_: CodeBlockSyntax) {
        currentDepth -= 1
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        currentDepth += 1

        if currentDepth > maxDepth {
            let location = converter.location(for: node.position)
            let violation = "⚠️  [excessive_nesting] Line \(location.line) has excessive nesting (level \(currentDepth), maximum: \(maxDepth)) - refactor code to reduce nesting depth"
            violations.append(violation)
        }

        return .visitChildren
    }

    override func visitPost(_: ClosureExprSyntax) {
        currentDepth -= 1
    }
}
