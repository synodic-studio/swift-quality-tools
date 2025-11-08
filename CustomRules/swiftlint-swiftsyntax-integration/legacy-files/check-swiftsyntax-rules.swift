#!/usr/bin/env swift

import Foundation
import SwiftParser
import SwiftSyntax

// Direct implementation of our skimmable body rule for faster execution
final class SkimmableBodyVisitor: SyntaxVisitor {
    private var violations: [(String, Int)] = []

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
                    // Get line number (approximate)
                    let beforeBody = bodyText.prefix(while: { $0 != "{" })
                    let lineNumber = beforeBody.components(separatedBy: "\n").count
                    violations.append(("SwiftUI View body has \(contentLines.count) lines (maximum: 10)", lineNumber))
                }
            }
        }

        return .visitChildren
    }

    func getViolations() -> [(String, Int)] {
        violations
    }
}

// Main execution
if CommandLine.arguments.count > 1 {
    let filePath = CommandLine.arguments[1]
    let url = URL(fileURLWithPath: filePath)

    do {
        let sourceCode = try String(contentsOf: url)
        let tree = Parser.parse(source: sourceCode)
        let visitor = SkimmableBodyVisitor(viewMode: .sourceAccurate)
        visitor.walk(tree)

        let violations = visitor.getViolations()
        for (message, line) in violations {
            print("\(filePath):\(line):1: warning: \(message)")
        }

        if violations.isEmpty {
            // Silent success for Xcode
        }
    } catch {
        print("\(filePath):1:1: error: Could not read file: \(error)")
    }
} else {
    print("Usage: swift check-swiftsyntax-rules.swift <file.swift>")
    exit(1)
}
