import CustomRules
import Foundation
import SwiftSyntax

// A complete custom linter built on the SwiftSkim library. It runs swiftskim's 16
// built-in rules PLUS a project-specific rule of our own — no fork of swiftskim needed.
// This is the supported extension model: compose your own tool against the library.

/// Finds `print(...)` call sites in a syntax tree.
final class PrintCallFinder: SyntaxVisitor {
    private(set) var lines: [Int] = []
    private let converter: SourceLocationConverter

    init(converter: SourceLocationConverter) {
        self.converter = converter
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callee = node.calledExpression.as(DeclReferenceExprSyntax.self)
        if callee?.baseName.text == "print" {
            lines.append(converter.location(for: node.positionAfterSkippingLeadingTrivia).line)
        }
        return .visitChildren
    }
}

/// Our own rule: ban `print(...)` — projects usually want a real logger. Its id
/// participates in `swiftskim:disable` exactly like a built-in rule.
struct NoPrintStatements: Rule {
    let id = "no_print_statements"
    let summary = "Use a logger, not print()"

    func check(_ file: SourceFileSyntax, context: RuleContext) -> [Violation] {
        let finder = PrintCallFinder(converter: context.converter)
        finder.walk(file)
        return finder.lines.map { Violation(ruleID: id, line: $0, message: "print() call — use a logger") }
    }
}

/// Lint one source string; print any violations under `label`, return the count.
func lint(source: String, label: String) -> Int {
    let violations = SwiftSkim.lint(source: source, externalRules: [NoPrintStatements()])
    guard !violations.isEmpty else { return 0 }
    print("\(label):")
    violations.forEach { print("  \($0)") }
    return violations.count
}

/// A built-in demo used when no file paths are passed, so `swift run` shows output.
let demoSource = """
import SwiftUI
struct DemoView: View {
    var body: some View {
        Group {
            print("debugging")
            Text("hi")
        }
    }
}
"""

let paths = Array(CommandLine.arguments.dropFirst())
var total = 0

if paths.isEmpty {
    total = lint(source: demoSource, label: "<demo>")
} else {
    for path in paths {
        let source = try? String(contentsOfFile: path, encoding: .utf8)
        guard let source else {
            FileHandle.standardError.write(Data("cannot read \(path)\n".utf8))
            continue
        }
        total += lint(source: source, label: path)
    }
}

if total > 0 {
    print("\n\(total) violation(s) — swiftskim built-ins + no_print_statements")
    exit(1)
}

print("clean")
