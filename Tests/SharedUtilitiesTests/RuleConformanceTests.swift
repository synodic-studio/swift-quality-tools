import Foundation
import Testing

/// Locks the single-source-of-truth invariant: every rule in `RuleRegistry` is
/// dispatched by `CustomRulesVisitor`, and every dispatched rule is registered.
///
/// This is the guarantee that prevents the class of bug where a rule was gated
/// under one id (`prefer_zero_param_onchange`) but emitted/suppressed under another
/// (`onchange_ignored_old_value`), so filtering by the documented id matched nothing.
@Suite("Rule registry conformance")
struct RuleConformanceTests {
    private var engineSources: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // SharedUtilitiesTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules")
    }

    /// Rule ids matched by `pattern` in `file`, ignoring comment lines.
    private func ids(in file: String, pattern: String) throws -> Set<String> {
        let url = engineSources.appendingPathComponent(file)
        let text = try String(contentsOf: url, encoding: .utf8)
        let regex = try NSRegularExpression(pattern: pattern)

        var found: Set<String> = []
        for line in text.components(separatedBy: .newlines) {
            if line.trimmingCharacters(in: .whitespaces).hasPrefix("//") { continue }
            let range = NSRange(line.startIndex..., in: line)
            regex.enumerateMatches(in: line, range: range) { match, _, _ in
                guard let match, let idRange = Range(match.range(at: 1), in: line) else { return }
                found.insert(String(line[idRange]))
            }
        }
        return found
    }

    @Test("Registry ids and dispatch sites agree in both directions")
    func registryMatchesDispatch() throws {
        let registered = try ids(in: "RuleRegistry.swift", pattern: #"RuleInfo\(id: "([a-z_]+)""#)
        let dispatched = try ids(in: "CustomRulesVisitor.swift", pattern: #"if shouldRun\("([a-z_]+)"\)"#)

        #expect(registered.count == 16)
        #expect(
            registered == dispatched,
            """
            Registry and dispatch sites disagree.
            Registered but not dispatched: \(registered.subtracting(dispatched).sorted())
            Dispatched but not registered: \(dispatched.subtracting(registered).sorted())
            """,
        )
    }
}
