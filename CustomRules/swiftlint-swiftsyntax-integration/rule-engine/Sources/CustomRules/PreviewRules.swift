import SwiftSyntax

/// Rules related to SwiftUI previews
/// - preview_required: Every file with View/ViewModifier/Shape must have at least one #Preview
public enum PreviewRules {
    private static func checkStructForView(_ structDecl: StructDeclSyntax, hasView: inout Bool, viewNames: inout [String]) {
        guard let inheritance = structDecl.inheritanceClause else { return }

        for inherited in inheritance.inheritedTypes {
            let typeName = inherited.type.description.trimmingCharacters(in: .whitespaces)
            if typeName.contains("View") || typeName.contains("ViewModifier") || typeName == "Shape" {
                hasView = true
                viewNames.append(structDecl.name.text)
                break
            }
        }
    }

    private static func checkMacroForPreview(_ macroDecl: MacroExpansionDeclSyntax, hasPreview: inout Bool) {
        let macroName = macroDecl.macroName.description
        if macroName.contains("Preview") {
            hasPreview = true
        }
    }

    private static func checkFunctionForPreview(_ funcDecl: FunctionDeclSyntax, hasPreview: inout Bool) {
        let hasPreviewAttribute = funcDecl.attributes.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.description.contains("Preview") ?? false
        }
        if hasPreviewAttribute {
            hasPreview = true
        }
    }

    public static func checkPreviewRequired(_ sourceFile: SourceFileSyntax, violations: inout [String]) {
        // Check if file declares any View or ViewModifier
        var hasViewOrModifier = false
        var hasPreview = false
        var viewNames: [String] = []

        // Check the entire source text for #Preview as a fallback for macro detection
        let sourceText = sourceFile.description
        if sourceText.contains("#Preview") || sourceText.contains("@Preview") {
            hasPreview = true
        }

        for statement in sourceFile.statements {
            // Check for struct/class declarations
            if let structDecl = statement.item.as(StructDeclSyntax.self) {
                checkStructForView(structDecl, hasView: &hasViewOrModifier, viewNames: &viewNames)
            }

            // Check for macro declarations (looking for #Preview or @Preview)
            if let macroDecl = statement.item.as(MacroExpansionDeclSyntax.self) {
                checkMacroForPreview(macroDecl, hasPreview: &hasPreview)
            }

            // Also check for function declarations with Preview attribute
            if let funcDecl = statement.item.as(FunctionDeclSyntax.self) {
                checkFunctionForPreview(funcDecl, hasPreview: &hasPreview)
            }
        }

        // If file has View/ViewModifier but no Preview, report violation
        if hasViewOrModifier, !hasPreview {
            let viewList = viewNames.joined(separator: ", ")
            let violation = "⚠️  [preview_required] File declares View/ViewModifier/Shape (\(viewList)) but has no #Preview - add at least one preview for development workflow"
            violations.append(violation)
        }
    }
}
