import SwiftLintFramework
import SwiftSyntax

struct SkimmableBodyRule: SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "skimmable_body",
        name: "Skimmable Body",
        description: "SwiftUI View body property should be 10 lines or fewer to remain skimmable",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        Text("Line 1")
                        Text("Line 2")
                        Text("Line 3")
                        Text("Line 4")
                        Text("Line 5")
                        Text("Line 6")
                        Text("Line 7")
                        Text("Line 8")
                        Text("Line 9")
                    }
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        headerView
                        contentView
                    }
                }

                var headerView: some View {
                    Text("Header")
                }

                var contentView: some View {
                    Text("Content")
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓VStack {
                        Text("Line 1")
                        Text("Line 2")
                        Text("Line 3")
                        Text("Line 4")
                        Text("Line 5")
                        Text("Line 6")
                        Text("Line 7")
                        Text("Line 8")
                        Text("Line 9")
                        Text("Line 10")
                        Text("Line 11")
                        Text("Line 12")
                    }
                }
            }
            """),
        ],
    )

    func makeVisitor(file _: SwiftLintFile) -> ViolationsSyntaxVisitor<Self> {
        SkimmableBodyVisitor(viewMode: .sourceAccurate)
    }
}

private extension SkimmableBodyRule {
    final class SkimmableBodyVisitor: ViolationsSyntaxVisitor<SkimmableBodyRule> {
        override func visitPost(_ node: VariableDeclSyntax) {
            // Check if this is a SwiftUI View body property
            guard isSwiftUIBodyProperty(node),
                  let accessor = node.bindings.first?.accessorBlock
            else {
                return
            }

            // Count the lines in the body
            let lineCount = countBodyLines(accessor)

            if lineCount > 10 {
                let position = node.bindings.first?.pattern.positionAfterSkippingLeadingTrivia ?? node.position
                let reason = "SwiftUI View body has \(lineCount) lines (maximum allowed: 10)"

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

        private func countBodyLines(_ accessor: AccessorBlockSyntax) -> Int {
            let bodyText = accessor.accessors.description
            let lines = bodyText.split(separator: "\n", omittingEmptySubsequences: false)

            // Filter out the opening and closing braces
            let contentLines = lines.dropFirst().dropLast()

            // Count non-empty lines
            let nonEmptyLines = contentLines.filter { line in
                !line.trimmingCharacters(in: .whitespaces).isEmpty
            }

            return nonEmptyLines.count
        }
    }
}
