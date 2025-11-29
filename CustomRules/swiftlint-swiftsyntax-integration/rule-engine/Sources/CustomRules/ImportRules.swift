import SwiftSyntax

/// Rules related to import organization
/// - blank_line_import_separation: Blank line between regular and @testable imports
/// - no_exported_import: Prohibit @_exported import (internal Swift API, not stable)
public enum ImportRules {
    /// Check for @_exported import usage
    /// This is an internal Swift API (underscore prefix) that is not guaranteed stable
    /// across Swift versions. Use explicit public API surface instead.
    public static func checkNoExportedImport(
        _ sourceFile: SourceFileSyntax,
        violations: inout [String],
    ) {
        for statement in sourceFile.statements {
            guard let importDecl = statement.item.as(ImportDeclSyntax.self) else {
                continue
            }

            let hasExported = importDecl.attributes.contains { attr in
                attr.as(AttributeSyntax.self)?.attributeName.description.contains("_exported") ?? false
            }

            if hasExported {
                let location = importDecl.startLocation(converter: SourceLocationConverter(fileName: "", tree: sourceFile))
                let line = location.line
                let moduleName = importDecl.path.description.trimmingCharacters(in: .whitespaces)
                let violation = "⚠️  [no_exported_import] Line \(line): @_exported import is an internal Swift API - use explicit public API surface instead of re-exporting '\(moduleName)'"
                violations.append(violation)
            }
        }
    }

    private static func classifyImport(
        _ importDecl: ImportDeclSyntax,
        regularImports: inout [ImportDeclSyntax],
        testableImports: inout [ImportDeclSyntax],
    ) {
        let isTestable = importDecl.attributes.contains { attr in
            attr.as(AttributeSyntax.self)?.attributeName.description.contains("testable") ?? false
        }

        if isTestable {
            testableImports.append(importDecl)
        } else {
            regularImports.append(importDecl)
        }
    }

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
                classifyImport(importDecl, regularImports: &regularImports, testableImports: &testableImports)
            }
        }

        // If we have both types, check for blank line separation
        guard !regularImports.isEmpty, !testableImports.isEmpty else { return }

        // Check if there's a blank line between the last regular import and first testable import
        if let firstTestable = testableImports.first {
            // Check the leading trivia of the first testable import for blank lines
            let leadingTrivia = firstTestable.leadingTrivia.description

            // Count newlines - should have at least 2 (one for the previous line, one for blank line)
            let newlineCount = leadingTrivia.count(where: { $0 == "\n" })

            // If less than 2 newlines, missing blank line
            if newlineCount < 2 {
                let violation = "⚠️  [blank_line_import_separation] Missing blank line between regular imports and @testable imports"
                violations.append(violation)
            }
        }
    }
}
