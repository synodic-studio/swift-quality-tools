import SwiftParser
import SwiftSyntax

/// A structured violation emitted by a `Rule`.
///
/// External rules return these; the engine formats and suppression-filters them
/// through the same path as the built-in rules, so there is one output path.
public struct Violation: Equatable, Sendable {
    /// Rule identifier (appears as `⚠️  [ruleID]` and matches suppression directives).
    public let ruleID: String
    /// 1-based line number, or 0 for a file-level violation.
    public let line: Int
    /// Human-readable message (without the `[ruleID]` prefix).
    public let message: String

    public init(ruleID: String, line: Int, message: String) {
        self.ruleID = ruleID
        self.line = line
        self.message = message
    }
}

/// Context handed to a rule during a check.
public struct RuleContext {
    /// Maps syntax positions to file line/column.
    public let converter: SourceLocationConverter

    public init(converter: SourceLocationConverter) {
        self.converter = converter
    }
}

/// A custom lint rule.
///
/// The 16 built-in rules are dispatched by `CustomRulesVisitor` in a single tree
/// walk for efficiency. Consumers add their own rules by conforming to this
/// protocol and passing them to `SwiftSkim.lint(externalRules:)`; each is run over
/// the parsed file and its structured violations join the built-ins' output.
public protocol Rule {
    /// Stable identifier. Also the token that `swiftlintcustom:disable` matches.
    var id: String { get }
    /// One-line summary.
    var summary: String { get }
    /// Inspect the parsed file and return any violations.
    func check(_ file: SourceFileSyntax, context: RuleContext) -> [Violation]
}

/// Library entry point for running rules over Swift source.
public enum SwiftSkim {
    /// Lint `source` with the built-in rules and any `externalRules`.
    ///
    /// - Parameters:
    ///   - source: Swift source text.
    ///   - externalRules: Consumer-supplied rules to run alongside the built-ins.
    ///   - only: If non-nil, only rules whose id is in this list run.
    ///   - runBuiltIns: Set false to run only `externalRules`.
    /// - Returns: Formatted, suppression-filtered violation lines.
    public static func lint(
        source: String,
        externalRules: [Rule] = [],
        only: [String]? = nil,
        runBuiltIns: Bool = true,
    ) -> [String] {
        let tree = Parser.parse(source: source)
        let visitor = CustomRulesVisitor(viewMode: .sourceAccurate)
        visitor.setSourceCode(source, sourceFile: tree)
        visitor.setEnabledRules(only)
        if runBuiltIns {
            visitor.walk(tree)
        }
        if !externalRules.isEmpty {
            visitor.run(externalRules: externalRules, on: tree)
        }
        return visitor.getViolations()
    }
}
