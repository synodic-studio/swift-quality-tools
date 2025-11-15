import CustomRules
import Foundation
import SwiftParser
import SwiftSyntax

// Test the rules
if CommandLine.arguments.count > 1 {
    let filePath = CommandLine.arguments[1]
    let url = URL(fileURLWithPath: filePath)

    do {
        let sourceCode = try String(contentsOf: url)
        let tree = Parser.parse(source: sourceCode)
        let visitor = CustomRulesVisitor(viewMode: .sourceAccurate)
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
    print("Usage: test-custom-rule <file.swift>")
}
