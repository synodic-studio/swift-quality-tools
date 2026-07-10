import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintCustomSmart: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run custom SwiftSyntax-based linting rules",
        discussion: """
        This tool runs custom SwiftSyntax-based rules including:
        • SwiftUI View body properties limited to 15 lines maximum
        • SwiftUI View body properties must have exactly one top-level view (never Group)
        • Indentation depth limited to 4 levels maximum for all functions, closures, and initializers

        Performance: Files are processed in parallel using all available CPU cores for optimal speed.

        Available rule IDs:
        • skimmable_body
        • no_group_body
        • one_top_level_view
        • no_if_modifier
        • no_if_without_else
        • excessive_nesting
        • view_structure_order
        • no_wrapper_body
        • blank_line_import_separation
        • preview_required
        • stack_minimum_children
        • prefer_zero_param_onchange
        • single_modifier_per_line
        """,
    )

    @Argument(help: "File or directory to check (default: current directory)")
    var target: String = "."

    @Flag(name: .long, help: "Disable parallel processing (useful for debugging)")
    var sequential = false

    @Option(name: .long, help: "Only run specified rules (comma-separated list of rule IDs)")
    var onlyRules: String?

    mutating func run() async throws {
        let targetURL = URL(fileURLWithPath: target)
        try ConfigDiscovery.validateTarget(targetURL)

        let ruleEnginePath = ConfigDiscovery.customRuleEnginePath
        try RuleEngineBuildHelper.ensureBuilt(ruleEnginePath)

        // Auto-detect Xcode environment via XCODE_VERSION_ACTUAL
        let isXcode = ProcessInfo.processInfo.environment["XCODE_VERSION_ACTUAL"] != nil

        if !isXcode {
            Console.section("🔍 Running Custom SwiftSyntax Rules on: \(target)")
        }

        let exclusionPatterns = ConfigDiscovery.readSwiftLintExclusions()
        let filesToCheck = SwiftFileCollector.collect(from: targetURL, excluding: exclusionPatterns)

        // Parse only-rules option
        let rulesToRun = onlyRules?.split(separator: ",").map { String($0) }

        // Print which rules are being run if filtered
        if let rulesToRun, !isXcode {
            Console.info("Running only: \(rulesToRun.joined(separator: ", "))")
        }

        let results = try await checkFiles(
            filesToCheck,
            ruleEngine: ruleEnginePath,
            isXcode: isXcode,
            onlyRules: rulesToRun,
        )

        let violationCount = results.filter(\.hasViolations).count

        if !isXcode {
            CustomRulesChecker.printSummary(totalFiles: filesToCheck.count, violations: violationCount)
        }

        if violationCount > 0 {
            throw ExitCode.failure
        }
    }

    /// Run the rule engine over `files`, in parallel by default (sequential with `--sequential`).
    private func checkFiles(
        _ files: [URL],
        ruleEngine: URL,
        isXcode: Bool,
        onlyRules: [String]?,
    ) async throws -> [CheckResult] {
        if sequential {
            return try files.map {
                try CustomRulesChecker.checkFile($0, ruleEngine: ruleEngine, xcodeFormat: isXcode, onlyRules: onlyRules)
            }
        }

        // Reason: structured-concurrency TaskGroup is irreducibly closure → for →
        // addTask; the per-file task body cannot be hoisted out of that shape.
        // swiftlintcustom:disable excessive_nesting
        return try await withThrowingTaskGroup(of: CheckResult.self) { group in
            for fileURL in files {
                group.addTask {
                    try CustomRulesChecker.checkFile(fileURL, ruleEngine: ruleEngine, xcodeFormat: isXcode, onlyRules: onlyRules)
                }
            }
            var results: [CheckResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        // swiftlintcustom:enable excessive_nesting
    }
}
