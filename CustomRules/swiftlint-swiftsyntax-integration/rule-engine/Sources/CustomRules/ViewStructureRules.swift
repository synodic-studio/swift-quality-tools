import SwiftSyntax

/// Rules related to SwiftUI View structure and organization
/// - view_structure_order: Member ordering enforcement
/// - no_wrapper_body: No pointless wrapper bodies
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
}
