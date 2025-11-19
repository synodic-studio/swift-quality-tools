import SwiftSyntax

/// Rules related to SwiftUI View structure and organization
/// - view_structure_order: Member ordering enforcement
/// - no_wrapper_body: No pointless wrapper bodies
/// - stack_minimum_children: Stacks (VStack/HStack/ZStack) must have at least 2 children
public enum ViewStructureRules {
    public static func checkViewStructureOrder(_ structDecl: StructDeclSyntax, violations: inout [String]) {
        // Expected order:
        // 1. Embedded types (enum, struct, class, protocol, actor)
        // 2. Environment properties (@Environment, @EnvironmentObject, @AppStorage, @SceneStorage)
        // 3. Other properties (@State, @Binding, let, var)
        // 4. init (must immediately precede body)
        // 5. body property
        // 6. Computed properties and methods

        enum MemberCategory {
            case embeddedType
            case environmentProperty
            case otherProperty
            case initializer
            case body
            case computedOrMethod
        }

        var memberCategories: [(category: MemberCategory, description: String)] = []

        for member in structDecl.memberBlock.members {
            let memberDesc = member.decl.description.trimmingCharacters(in: .whitespacesAndNewlines)

            // Categorize each member
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                // Check if it's body
                if let binding = varDecl.bindings.first,
                   let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                   identifier.identifier.text == "body"
                {
                    memberCategories.append((.body, "body property"))
                    continue
                }

                // Check for environment properties
                let hasEnvironmentAttribute = varDecl.attributes.contains { attr in
                    let attrName = attr.as(AttributeSyntax.self)?.attributeName.description ?? ""
                    return ["Environment", "EnvironmentObject", "AppStorage", "SceneStorage"]
                        .contains(attrName)
                }

                if hasEnvironmentAttribute {
                    memberCategories.append((.environmentProperty, memberDesc.prefix(50).description))
                } else {
                    memberCategories.append((.otherProperty, memberDesc.prefix(50).description))
                }
            } else if member.decl.is(InitializerDeclSyntax.self) {
                memberCategories.append((.initializer, "init"))
            } else if member.decl.is(EnumDeclSyntax.self) || member.decl.is(StructDeclSyntax.self) ||
                member.decl.is(ClassDeclSyntax.self) || member.decl.is(ProtocolDeclSyntax.self) ||
                member.decl.is(ActorDeclSyntax.self)
            {
                memberCategories.append((.embeddedType, memberDesc.prefix(50).description))
            } else if member.decl.is(FunctionDeclSyntax.self) ||
                (member.decl.is(VariableDeclSyntax.self) &&
                    member.decl.as(VariableDeclSyntax.self)?.bindings.first?.accessorBlock != nil)
            {
                memberCategories.append((.computedOrMethod, memberDesc.prefix(50).description))
            }
        }

        // Check order violations
        var maxCategorySeen = -1
        let categoryOrder: [MemberCategory] = [
            .embeddedType,
            .environmentProperty,
            .otherProperty,
            .initializer,
            .body,
            .computedOrMethod,
        ]

        for (category, description) in memberCategories {
            guard let currentIndex = categoryOrder.firstIndex(of: category) else { continue }

            if currentIndex < maxCategorySeen {
                let violation = "⚠️  [view_structure_order] SwiftUI View has incorrect member order - '\(description)' should come before later members (expected: embedded types → env props → other props → init → body → computed/methods)"
                violations.append(violation)
                print(violation)
                return // Report once per struct
            }

            maxCategorySeen = max(maxCategorySeen, currentIndex)
        }

        // Check that init immediately precedes body if both exist
        if let initIndex = memberCategories.firstIndex(where: { $0.category == .initializer }),
           let bodyIndex = memberCategories.firstIndex(where: { $0.category == .body }),
           bodyIndex != initIndex + 1
        {
            let violation = "⚠️  [view_structure_order] SwiftUI View init must immediately precede body property"
            violations.append(violation)
            print(violation)
        }
    }

    public static func checkNoWrapperBody(_ node: VariableDeclSyntax, violations: inout [String]) {
        // Detect pointless wrapper pattern:
        // var body: some View {
        //     mainContent  // ← Just returns another property
        // }

        guard let binding = node.bindings.first,
              let accessor = binding.accessorBlock
        else {
            return
        }

        let bodyText = accessor.description
        let lines = bodyText.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0 != "{" && $0 != "}" && !$0.contains("get") }

        // If body has exactly one line and it's just an identifier (not a function call, not a view constructor)
        if lines.count == 1 {
            let line = lines[0]
            // Check if it's just an identifier (lowercase start, no parens, no dots except trailing modifiers)
            let isSimpleIdentifier = line.first?.isLowercase == true &&
                !line.contains("(") &&
                !line.hasPrefix(".")

            if isSimpleIdentifier {
                let violation = "⚠️  [no_wrapper_body] SwiftUI View body is a pointless wrapper - just returns '\(line)'. Merge the logic directly into body or use @ViewBuilder if needed."
                violations.append(violation)
                print(violation)
            }
        }
    }

    public static func checkStackMinimumChildren(_ node: FunctionCallExprSyntax, violations: inout [String]) {
        // Check if this is a VStack, HStack, or ZStack call
        // Note: Using trimmedDescription to avoid whitespace issues
        let calledExpr = node.calledExpression.trimmedDescription
        guard calledExpr == "VStack" || calledExpr == "HStack" || calledExpr == "ZStack" else {
            return
        }

        // Find the trailing closure (the content block)
        guard let trailingClosure = node.trailingClosure else {
            return
        }

        // Count top-level statements in the closure
        let statements = trailingClosure.statements
        let topLevelCount = statements.count

        // If there are 2+ top-level children, it's fine
        if topLevelCount >= 2 {
            return
        }

        // If there's exactly 1 top-level child, check if it's an allowed exception
        if topLevelCount == 1 {
            let firstItem = statements.first!
            let itemNode = firstItem.item

            // The item can be either a direct expression (functionCallExpr, memberAccessExpr, etc.)
            // or wrapped in an ExpressionStmtSyntax (for if/switch expressions)
            var expr: (any ExprSyntaxProtocol)?

            if let exprStmt = itemNode.as(ExpressionStmtSyntax.self) {
                expr = exprStmt.expression
            } else if let directExpr = itemNode.as(ExprSyntax.self) {
                expr = directExpr
            }

            guard let expr else {
                return // Can't determine expression type
            }

            // Allow ForEach as single child
            if let functionCall = expr.as(FunctionCallExprSyntax.self) {
                let funcName = functionCall.calledExpression.trimmedDescription
                if funcName == "ForEach" || funcName.hasSuffix(".ForEach") {
                    return // ForEach is allowed as single child
                }
            }

            // Check if it's an if/else expression
            if let ifExpr = expr.as(IfExprSyntax.self) {
                // Check if any branch has 2+ views
                if anyBranchHasMultipleViews(ifExpr) {
                    return // Allowed because at least one branch has multiple children
                }
            }

            // Check if it's a switch expression
            if let switchExpr = expr.as(SwitchExprSyntax.self) {
                // Check if any case has 2+ views
                if anyCaseHasMultipleViews(switchExpr) {
                    return // Allowed because at least one case has multiple children
                }
            }
        }

        // If we get here, it's a violation
        let violation = "⚠️  [stack_minimum_children] \(calledExpr) should have at least 2 children (or use ForEach, or have if/else with a branch containing 2+ views)"
        violations.append(violation)
        print(violation)
    }

    private static func anyBranchHasMultipleViews(_ ifExpr: IfExprSyntax) -> Bool {
        // Check the main 'then' branch
        if ifExpr.body.statements.count >= 2 {
            return true
        }

        // Check the 'else' branch if it exists
        if let elseBody = ifExpr.elseBody {
            if let elseIfExpr = elseBody.as(IfExprSyntax.self) {
                // Recursive check for else-if
                return anyBranchHasMultipleViews(elseIfExpr)
            } else if let codeBlock = elseBody.as(CodeBlockSyntax.self) {
                if codeBlock.statements.count >= 2 {
                    return true
                }
            }
        }

        return false
    }

    private static func anyCaseHasMultipleViews(_ switchExpr: SwitchExprSyntax) -> Bool {
        for caseItem in switchExpr.cases {
            if let switchCase = caseItem.as(SwitchCaseSyntax.self) {
                if switchCase.statements.count >= 2 {
                    return true
                }
            }
        }
        return false
    }
}
