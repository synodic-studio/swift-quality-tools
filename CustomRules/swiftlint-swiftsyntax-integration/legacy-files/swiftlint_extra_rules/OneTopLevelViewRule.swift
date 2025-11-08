import SwiftLintFramework
import SwiftSyntax

struct OneTopLevelViewRule: SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "one_top_level_view",
        name: "One Top-Level View",
        description: "SwiftUI View body property should have exactly one top-level view",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    Text("Single view")
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        Text("First")
                        Text("Second")
                    }
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    Group {
                        Text("First")
                        Text("Second")
                    }
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    ZStack {
                        Color.blue
                        Text("Overlay")
                    }
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓Text("First")
                    Text("Second")
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓Button("First") { }
                    Button("Second") { }
                    Text("Third")
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓Color.blue
                    Text("Overlay")
                }
            }
            """),
        ],
    )

    func makeVisitor(file _: SwiftLintFile) -> ViolationsSyntaxVisitor<Self> {
        OneTopLevelViewVisitor(viewMode: .sourceAccurate)
    }
}

private extension OneTopLevelViewRule {
    final class OneTopLevelViewVisitor: ViolationsSyntaxVisitor<OneTopLevelViewRule> {
        override func visitPost(_ node: VariableDeclSyntax) {
            // Check if this is a SwiftUI View body property
            guard isSwiftUIBodyProperty(node),
                  let accessor = node.bindings.first?.accessorBlock
            else {
                return
            }

            // Count top-level statements in the body
            let topLevelStatements = countTopLevelStatements(in: accessor)

            if topLevelStatements > 1 {
                let position = node.bindings.first?.pattern.positionAfterSkippingLeadingTrivia ?? node.position
                let reason = "SwiftUI View body has \(topLevelStatements) top-level views (should be exactly 1)"

                violations.append(
                    ReasonedRuleViolation(
                        position: position,
                        reason: reason,
                    ),
                )
            }
        }

        private func isSwiftUIBodyProperty(_ node: VariableDeclSyntax) -> Bool {
            // Check if variable name is "body"
            guard let binding = node.bindings.first,
                  let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                  identifier.identifier.text == "body"
            else {
                return false
            }

            // Check if type annotation contains "some View"
            if let typeAnnotation = binding.typeAnnotation {
                let typeText = typeAnnotation.description
                return typeText.contains("some View")
            }

            return false
        }

        private func countTopLevelStatements(in accessor: AccessorBlockSyntax) -> Int {
            var statementCount = 0

            for accessorDecl in accessor.accessors {
                if let body = accessorDecl.body {
                    // Count statements in the getter body
                    for statement in body.statements {
                        // Skip empty statements and comments
                        if !isEmptyStatement(statement) {
                            statementCount += 1
                        }
                    }
                }
            }

            return statementCount
        }

        private func isEmptyStatement(_ statement: CodeBlockItemSyntax) -> Bool {
            // Check if statement is effectively empty (whitespace, comments, etc.)
            let statementText = statement.description.trimmingCharacters(in: .whitespacesAndNewlines)
            return statementText.isEmpty
        }
    }
}
