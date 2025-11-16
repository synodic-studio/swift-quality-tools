import SwiftSyntax

/// Rules related to import organization
/// - blank_line_import_separation: Blank line between regular and @testable imports
public enum ImportRules {
    public static func checkBlankLineImportSeparation(_ sourceFile: SourceFileSyntax, violations: inout [String]) {
        // Enforce blank line between regular imports and @testable imports:
        // import Foundation
        // import SwiftUI
        //
        // @testable import MyPackage

        var regularImports: [ImportDeclSyntax] = []
        var testableImports: [ImportDeclSyntax] = []

        // Collect imports
        for statement in sourceFile.statements {
            if let importDecl = statement.item.as(ImportDeclSyntax.self) {
                let isTestable = importDecl.attributes.contains { attr in
                    attr.as(AttributeSyntax.self)?.attributeName.description.contains("testable") ?? false
                }

                if isTestable {
                    testableImports.append(importDecl)
                } else {
                    regularImports.append(importDecl)
                }
            }
        }

        // If we have both types, check for blank line separation
        guard !regularImports.isEmpty, !testableImports.isEmpty else { return }

        // Check if there's a blank line between the last regular import and first testable import
        if let lastRegular = regularImports.last,
           let firstTestable = testableImports.first
        {
            // Check the leading trivia of the first testable import for blank lines
            let leadingTrivia = firstTestable.leadingTrivia.description

            // Count newlines - should have at least 2 (one for the previous line, one for blank line)
            let newlineCount = leadingTrivia.count(where: { $0 == "\n" })

            // If less than 2 newlines, missing blank line
            if newlineCount < 2 {
                let violation = "⚠️  [blank_line_import_separation] Missing blank line between regular imports and @testable imports"
                violations.append(violation)
                print(violation)
            }
        }
    }
}
