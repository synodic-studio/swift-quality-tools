import CustomRules
import SwiftSyntax
import Testing

/// Example of a consumer-defined rule: bans a struct named `Foo`.
/// Demonstrates the whole extensibility surface — walk the tree, return
/// structured `Violation`s keyed by a rule id.
private struct NoStructNamedFoo: Rule {
    let id = "no_struct_named_foo"
    let summary = "Example external rule: a struct may not be named Foo"

    func check(_ file: SourceFileSyntax, context: RuleContext) -> [Violation] {
        let finder = FooFinder(viewMode: .sourceAccurate)
        finder.walk(file)
        return finder.positions.map { position in
            Violation(
                ruleID: id,
                line: context.converter.location(for: position).line,
                message: "Struct must not be named Foo",
            )
        }
    }

    private final class FooFinder: SyntaxVisitor {
        var positions: [AbsolutePosition] = []
        override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
            if node.name.text == "Foo" {
                positions.append(node.positionAfterSkippingLeadingTrivia)
            }
            return .visitChildren
        }
    }
}

@Suite("Rule protocol (external rules)")
struct RuleProtocolTests {
    @Test("An external rule fires through the engine")
    func externalRuleFires() {
        let output = SwiftSkim.lint(
            source: "struct Foo {}\n",
            externalRules: [NoStructNamedFoo()],
            runBuiltIns: false,
        )
        #expect(output.contains { $0.contains("[no_struct_named_foo]") })
    }

    @Test("An external rule honors swiftskim:disable:next")
    func externalRuleIsSuppressible() {
        let source = """
        // swiftskim:disable:next no_struct_named_foo
        struct Foo {}
        """
        let output = SwiftSkim.lint(
            source: source,
            externalRules: [NoStructNamedFoo()],
            runBuiltIns: false,
        )
        #expect(!output.contains { $0.contains("[no_struct_named_foo]") })
    }

    @Test("Built-in rules still run alongside external ones")
    func builtInsStillRun() {
        // A 2-param onChange with an ignored old value trips the built-in rule.
        let source = """
        import SwiftUI
        struct Bar: View {
            @State private var v = 0
            var body: some View {
                Text("x").onChange(of: v) { _, newValue in print(newValue) }
            }
        }
        """
        let output = SwiftSkim.lint(source: source, externalRules: [NoStructNamedFoo()])
        #expect(output.contains { $0.contains("[onchange_ignored_old_value]") })
    }
}
