import CustomRules
import Foundation
import SwiftParser
import SwiftSyntax

// Parse arguments
// Usage: test-custom-rule <file.swift> [--only-rules rule1,rule2,...]
var filePath: String?
var onlyRules: [String]?

var args = Array(CommandLine.arguments.dropFirst())
var i = 0
while i < args.count {
    let arg = args[i]
    if arg == "--list-rules" {
        print(RuleRegistry.formattedList())
        exit(0)
    } else if arg == "--only-rules", i + 1 < args.count {
        onlyRules = args[i + 1].split(separator: ",").map { String($0) }
        i += 2
    } else if !arg.hasPrefix("-") {
        filePath = arg
        i += 1
    } else {
        i += 1
    }
}

guard let filePath else {
    print("Usage: swiftquality-rule-engine <file.swift> [--only-rules rule1,rule2,...] [--list-rules]")
    exit(1)
}

let url = URL(fileURLWithPath: filePath)

do {
    let sourceCode = try String(contentsOf: url)
    let tree = Parser.parse(source: sourceCode)
    let visitor = CustomRulesVisitor(viewMode: .sourceAccurate)
    visitor.setSourceCode(sourceCode, sourceFile: tree)
    visitor.setEnabledRules(onlyRules)
    visitor.walk(tree)

    let violations = visitor.getViolations()
    if violations.isEmpty {
        print("✅ No violations found")
    } else {
        print("Found \(violations.count) violation(s)")
        for violation in violations {
            print(violation)
        }
        // Print suppression hint so LLMs know to use swiftlintcustom, not swiftlint
        print("\n💡 Suppress with: // swiftlintcustom:disable:next <rule_id>")
    }
} catch {
    print("Error reading file: \(error)")
}
