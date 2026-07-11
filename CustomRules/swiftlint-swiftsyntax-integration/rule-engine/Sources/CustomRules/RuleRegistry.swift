import Foundation

/// Canonical registry of every custom rule the engine enforces.
///
/// This is the single source of truth for rule identity. `--list-rules` prints
/// straight from this array, and the wrapper `--help` points there rather than
/// copying the list — so the authoritative rule list is always registry-derived.
/// `RuleConformanceTests` asserts this registry and the engine's dispatch sites
/// (`CustomRulesVisitor`) agree in both directions, which locks rule *identity*
/// against the split-identity bug class (a rule gated under one id but emitted
/// and suppressed under another). Prose lists elsewhere (the README grouping) are
/// hand-maintained convenience indexes pointing at `--list-rules`; the test does
/// not police those, so keep them honest by hand or lean on `--list-rules`.
///
/// When adding a rule: append an entry here, dispatch it in `CustomRulesVisitor`
/// using the SAME `id`, and rebuild. Nothing else needs a manual edit.
public struct RuleInfo: Sendable {
    /// Stable identifier: the string emitted in `⚠️  [id]` and matched by
    /// `--only-rules` and `swiftskim:disable` directives. These must agree.
    public let id: String
    /// One-line summary of what the rule enforces.
    public let summary: String

    public init(id: String, summary: String) {
        self.id = id
        self.summary = summary
    }
}

public enum RuleRegistry {
    /// All 16 rules, in dispatch order. Order is not semantically meaningful.
    public static let all: [RuleInfo] = [
        RuleInfo(id: "skimmable_body", summary: "View/ViewModifier body capped at 15 lines"),
        RuleInfo(id: "no_group_body", summary: "body must not be a top-level Group without modifiers (use @ViewBuilder)"),
        RuleInfo(id: "one_top_level_view", summary: "body must have exactly one top-level view (if/else counts as one)"),
        RuleInfo(id: "no_if_modifier", summary: "Ban the custom .if modifier anti-pattern (use ternary or @ViewBuilder)"),
        RuleInfo(id: "no_if_without_else", summary: "No if-without-else in @ViewBuilder (hoist visibility to the caller)"),
        RuleInfo(id: "excessive_nesting", summary: "AST nesting depth capped at 3 (relaxed inside #Preview)"),
        RuleInfo(id: "prefer_shorthand_optional_binding", summary: "Use if-let shorthand with the original name, not `if let foo = foo`"),
        RuleInfo(id: "view_structure_order", summary: "Enforce View member ordering (types → env → props → init → body → methods)"),
        RuleInfo(id: "no_wrapper_body", summary: "Flag pointless wrapper body properties"),
        RuleInfo(id: "blank_line_import_separation", summary: "Blank line required between regular and @testable imports"),
        RuleInfo(id: "no_exported_import", summary: "Ban @_exported import (underscore prefix is unstable Swift API)"),
        RuleInfo(id: "prefer_swift_testing", summary: "Prefer Swift Testing over XCTest (flags import XCTest and XCTAssert*)"),
        RuleInfo(id: "preview_required", summary: "Every file declaring a View/ViewModifier/Shape needs at least one #Preview"),
        RuleInfo(id: "stack_minimum_children", summary: "VStack/HStack/ZStack need 2+ children (ForEach and 2+-branch if/else allowed)"),
        RuleInfo(id: "onchange_ignored_old_value", summary: "Use 0-parameter onChange when the old value is ignored"),
        RuleInfo(id: "single_modifier_per_line", summary: "Each modifier on its own line (no chaining on one line)"),
    ]

    /// Just the identifiers, for filtering and conformance checks.
    public static let allIDs: [String] = all.map(\.id)

    /// Human-readable listing for `--list-rules`.
    public static func formattedList() -> String {
        let width = all.map(\.id.count).max() ?? 0
        let lines = all.map { rule in
            let padded = rule.id.padding(toLength: width, withPad: " ", startingAt: 0)
            return "  \(padded)  \(rule.summary)"
        }
        return "Custom SwiftSyntax rules (\(all.count) total):\n" + lines.joined(separator: "\n")
    }
}
