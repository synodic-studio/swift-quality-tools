import CustomRules
import Foundation
import SwiftParser
import SwiftSyntax

// Parse arguments
// Usage: swiftskim-engine <file.swift> [--only-rules ids] [--disable-rules ids] [--list-rules]
var filePath: String?
var onlyRules: [String]?
var disabledRules: [String]?

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
    } else if arg == "--disable-rules", i + 1 < args.count {
        disabledRules = args[i + 1].split(separator: ",").map { String($0) }
        i += 2
    } else if arg == "--skimmable-body-max", i + 1 < args.count {
        if let value = Int(args[i + 1]) { RuleConfig.skimmableBodyMaxLines = value }
        i += 2
    } else if arg == "--nesting-max-depth", i + 1 < args.count {
        if let value = Int(args[i + 1]) { RuleConfig.excessiveNestingMaxDepth = value }
        i += 2
    } else if !arg.hasPrefix("-") {
        filePath = arg
        i += 1
    } else {
        i += 1
    }
}

// Fail loud on unknown rule ids in either list — a typo must never silently select or
// disable nothing. This is the same "the tool agrees with itself" guarantee the
// registry enforces; an unrecognized id is a configuration error, not a no-op.
let knownIDs = Set(RuleRegistry.allIDs)
let unknown = ((onlyRules ?? []) + (disabledRules ?? [])).filter { !knownIDs.contains($0) }
if !unknown.isEmpty {
    let known = RuleRegistry.allIDs.sorted().joined(separator: ", ")
    FileHandle.standardError.write(Data("""
    Error: unknown rule id(s): \(unknown.sorted().joined(separator: ", "))
    Valid rule ids: \(known)
    Run `swiftskim --list-rules` for the authoritative list.

    """.utf8))
    exit(2)
}

// only_rules wins over disable_rules when both name the same id (allowlist is explicit).
if let onlyRules, !onlyRules.isEmpty {
    disabledRules = disabledRules?.filter { !onlyRules.contains($0) }
}

guard let filePath else {
    print("Usage: swiftskim-engine <file.swift> [--only-rules ids] [--disable-rules ids] [--list-rules]")
    exit(1)
}

let url = URL(fileURLWithPath: filePath)

do {
    let sourceCode = try String(contentsOf: url)
    let tree = Parser.parse(source: sourceCode)
    let visitor = CustomRulesVisitor(viewMode: .sourceAccurate)
    visitor.setSourceCode(sourceCode, sourceFile: tree)
    visitor.setEnabledRules(onlyRules)
    visitor.setDisabledRules(disabledRules)
    visitor.walk(tree)

    let violations = visitor.getViolations()
    if violations.isEmpty {
        print("✅ No violations found")
    } else {
        print("Found \(violations.count) violation(s)")
        for violation in violations {
            print(violation)
        }
        // Print suppression hint so LLMs know to use the swiftskim prefix, not swiftlint
        print("\n💡 Suppress with: // swiftskim:disable:next <rule_id>")
    }
} catch {
    print("Error reading file: \(error)")
}
