import SwiftLintFramework
import SwiftSyntax

struct NoGroupBodyRule: SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "no_group_body",
        name: "No Group Body",
        description: "SwiftUI View body property should never have Group as the top-level view unless it has view modifiers",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    VStack {
                        Text("Content")
                    }
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    HStack {
                        Text("Left")
                        Text("Right")
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
                    Group {
                        Text("First")
                        Text("Second")
                    }
                    .background(Color.gray)
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
                    .padding()
                    .background(Color.blue)
                }
            }
            """),
        ],
        triggeringExamples: [
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓Group {
                        Text("First")
                        Text("Second")
                    }
                }
            }
            """),
            Example("""
            struct MyView: View {
                var body: some View {
                    ↓Group {
                        if condition {
                            Text("Conditional")
                        }
                        Text("Always")
                    }
                }
            }
            """),
        ],
    )

    func makeVisitor(file _: SwiftLintFile) -> ViolationsSyntaxVisitor<Self> {
        NoGroupBodyVisitor(viewMode: .sourceAccurate)
    }
}

private extension NoGroupBodyRule {
    final class NoGroupBodyVisitor: ViolationsSyntaxVisitor<NoGroupBodyRule> {
        override func visitPost(_ node: VariableDeclSyntax) {
            // Check if this is a SwiftUI View body property
            guard isSwiftUIBodyProperty(node),
                  let accessor = node.bindings.first?.accessorBlock
            else {
                return
            }

            // Find the top-level view in the body
            if let topLevelGroup = findTopLevelGroup(in: accessor) {
                let position = topLevelGroup.positionAfterSkippingLeadingTrivia
                let reason = "SwiftUI View body should not have Group as the top-level view. Use VStack, HStack, ZStack, or a single view instead."

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

        private func findTopLevelGroup(in accessor: AccessorBlockSyntax) -> FunctionCallExprSyntax? {
            // Look for the first function call expression that could be a Group
            for statement in accessor.accessors {
                if let codeBlock = statement.body {
                    for stmt in codeBlock.statements {
                        if let exprStmt = stmt.item.as(ExpressionStmtSyntax.self),
                           let functionCall = exprStmt.expression.as(FunctionCallExprSyntax.self)
                        {
                            // Check if this is a Group call
                            if isGroupCall(functionCall) {
                                return functionCall
                            }
                        }

                        // Also check return statements
                        if let returnStmt = stmt.item.as(ReturnStmtSyntax.self),
                           let returnExpr = returnStmt.expression,
                           let functionCall = returnExpr.as(FunctionCallExprSyntax.self)
                        {
                            if isGroupCall(functionCall) {
                                return functionCall
                            }
                        }
                    }
                }
            }

            return nil
        }

        private func isGroupCall(_ functionCall: FunctionCallExprSyntax) -> Bool {
            // Check if the callee is "Group"
            if let memberAccess = functionCall.calledExpression.as(MemberAccessExprSyntax.self) {
                return memberAccess.declName.baseName.text == "Group"
            }

            if let identifier = functionCall.calledExpression.as(DeclReferenceExprSyntax.self) {
                return identifier.baseName.text == "Group"
            }

            return false
        }
    }
}
