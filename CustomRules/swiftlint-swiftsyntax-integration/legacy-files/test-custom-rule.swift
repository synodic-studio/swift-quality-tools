import Foundation
import SwiftParser
import SwiftSyntax

/// Simplified version of our custom rule for testing
final class SkimmableBodyVisitor: SyntaxVisitor {
    private var violations: [String] = []

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
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
                // Count lines in the body
                let bodyText = node.description
                let lines = bodyText.split(separator: "\n", omittingEmptySubsequences: false)
                let contentLines = lines.filter { line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    return !trimmed.isEmpty && !trimmed.hasPrefix("var body") && trimmed != "}" && trimmed != "{"
                }

                if contentLines.count > 10 {
                    let violation = "⚠️ SwiftUI View body has \(contentLines.count) lines (maximum: 10)"
                    violations.append(violation)
                    print(violation)
                }
            }
        }

        return .visitChildren
    }

    func getViolations() -> [String] {
        violations
    }
}

// Test the rule
if CommandLine.arguments.count > 1 {
    let filePath = CommandLine.arguments[1]
    let url = URL(fileURLWithPath: filePath)

    do {
        let sourceCode = try String(contentsOf: url)
        let tree = Parser.parse(source: sourceCode)
        let visitor = SkimmableBodyVisitor(viewMode: .sourceAccurate)
        visitor.walk(tree)

        let violations = visitor.getViolations()
        if violations.isEmpty {
            print("✅ No violations found")
        } else {
            print("Found \(violations.count) violation(s)")
        }
    } catch {
        print("Error reading file: \(error)")
    }
} else {
    print("Usage: swift test-custom-rule.swift <file.swift>")
}
