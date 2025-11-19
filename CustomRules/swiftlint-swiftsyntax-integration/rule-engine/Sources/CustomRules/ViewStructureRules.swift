import SwiftSyntax

/// Rules related to SwiftUI View structure and organization
/// - view_structure_order: Member ordering enforcement
/// - no_wrapper_body: No pointless wrapper bodies
/// - stack_minimum_children: Stacks (VStack/HStack/ZStack) must have at least 2 children
public enum ViewStructureRules {
    enum MemberCategory {
        case embeddedType
        case environmentProperty
        case otherProperty
        case initializer
        case body
        case computedOrMethod
    }

    private static func hasEnvironmentAttribute(_ varDecl: VariableDeclSyntax) -> Bool {
        varDecl.attributes.contains { attr in
            guard let attrSyntax = attr.as(AttributeSyntax.self) else { return false }
            let attrName = attrSyntax.attributeName.trimmedDescription
            return ["Environment", "EnvironmentObject", "AppStorage", "SceneStorage"].contains(attrName)
        }
    }

    private static func isBodyProperty(_ varDecl: VariableDeclSyntax) -> Bool {
        guard let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else { return false }
        return identifier.identifier.text == "body"
    }

    private static func isComputedProperty(_ varDecl: VariableDeclSyntax) -> Bool {
        varDecl.bindings.first?.accessorBlock != nil
    }

    private static func getPropertyName(_ varDecl: VariableDeclSyntax) -> String? {
        guard let binding = varDecl.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)
        else {
            return nil
        }
        return identifier.identifier.text
    }

    private static func getCategoryName(_ category: MemberCategory) -> String {
        switch category {
        case .embeddedType: "embedded type"
        case .environmentProperty: "environment property"
        case .otherProperty: "stored property"
        case .initializer: "initializer"
        case .body: "body property"
        case .computedOrMethod: "computed/method"
        }
    }

    private static func categorizeMember(
        _ member: MemberBlockItemSyntax,
        memberDesc: String,
        categories: inout [(category: MemberCategory, description: String)],
    ) {
        if let varDecl = member.decl.as(VariableDeclSyntax.self) {
            if isBodyProperty(varDecl) {
                categories.append((.body, "body property"))
                return
            }

            if isComputedProperty(varDecl) {
                let propName = getPropertyName(varDecl) ?? "computed property"
                categories.append((.computedOrMethod, propName))
                return
            }

            let category: MemberCategory = hasEnvironmentAttribute(varDecl) ? .environmentProperty : .otherProperty
            let propName = getPropertyName(varDecl) ?? "property"
            categories.append((category, propName))
        } else if member.decl.is(InitializerDeclSyntax.self) {
            categories.append((.initializer, "init"))
        } else if member.decl.is(EnumDeclSyntax.self) || member.decl.is(StructDeclSyntax.self) ||
            member.decl.is(ClassDeclSyntax.self) || member.decl.is(ProtocolDeclSyntax.self) ||
            member.decl.is(ActorDeclSyntax.self)
        {
            categories.append((.embeddedType, memberDesc.prefix(50).description))
        } else if let funcDecl = member.decl.as(FunctionDeclSyntax.self) {
            let funcName = funcDecl.name.text
            categories.append((.computedOrMethod, funcName))
        }
    }

    public static func checkViewStructureOrder(_ structDecl: StructDeclSyntax, violations: inout [String]) {
        // Expected order:
        // 1. Embedded types (enum, struct, class, protocol, actor)
        // 2. Environment properties (@Environment, @EnvironmentObject, @AppStorage, @SceneStorage)
        // 3. Other properties (@State, @Binding, let, var)
        // 4. init (must immediately precede body)
        // 5. body property
        // 6. Computed properties and methods

        var memberCategories: [(category: MemberCategory, description: String)] = []

        for member in structDecl.memberBlock.members {
            let memberDesc = member.decl.description.trimmingCharacters(in: .whitespacesAndNewlines)

            // Categorize each member
            categorizeMember(member, memberDesc: memberDesc, categories: &memberCategories)
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
                let categoryName = getCategoryName(category)
                let violation = "⚠️  [view_structure_order] '\(description)' (\(categoryName)) is out of order (expected: embedded types → env props → other props → init → body → computed/methods)"
                violations.append(violation)
                print(violation)
                // Don't return - report all violations
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
        if topLevelCount == 1, isSingleChildAllowed(statements.first!) {
            return
        }

        // If we get here, it's a violation
        let violation = "⚠️  [stack_minimum_children] \(calledExpr) should have at least 2 children (or use ForEach, or have if/else with a branch containing 2+ views)"
        violations.append(violation)
        print(violation)
    }

    private static func isSingleChildAllowed(_ statement: CodeBlockItemSyntax) -> Bool {
        let itemNode = statement.item

        // Extract expression from either ExpressionStmtSyntax or direct ExprSyntax
        var expr: (any ExprSyntaxProtocol)?
        if let exprStmt = itemNode.as(ExpressionStmtSyntax.self) {
            expr = exprStmt.expression
        } else if let directExpr = itemNode.as(ExprSyntax.self) {
            expr = directExpr
        }

        guard let expr else { return false }

        // Allow ForEach as single child
        if let functionCall = expr.as(FunctionCallExprSyntax.self) {
            let funcName = functionCall.calledExpression.trimmedDescription
            if funcName == "ForEach" || funcName.hasSuffix(".ForEach") {
                return true
            }
        }

        // Check if it's an if/else expression with any branch having 2+ views
        if let ifExpr = expr.as(IfExprSyntax.self) {
            return anyBranchHasMultipleViews(ifExpr)
        }

        // Check if it's a switch expression with any case having 2+ views
        if let switchExpr = expr.as(SwitchExprSyntax.self) {
            return anyCaseHasMultipleViews(switchExpr)
        }

        return false
    }

    private static func anyBranchHasMultipleViews(_ ifExpr: IfExprSyntax) -> Bool {
        // Check the main 'then' branch
        if ifExpr.body.statements.count >= 2 { return true }

        // Check the 'else' branch if it exists
        guard let elseBody = ifExpr.elseBody else { return false }

        if let elseIfExpr = elseBody.as(IfExprSyntax.self) {
            return anyBranchHasMultipleViews(elseIfExpr)
        }

        if let codeBlock = elseBody.as(CodeBlockSyntax.self) {
            return codeBlock.statements.count >= 2
        }

        return false
    }

    private static func anyCaseHasMultipleViews(_ switchExpr: SwitchExprSyntax) -> Bool {
        switchExpr.cases.contains { caseItem in
            guard let switchCase = caseItem.as(SwitchCaseSyntax.self) else { return false }
            return switchCase.statements.count >= 2
        }
    }
}
