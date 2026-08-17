import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintCustomSmart: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftskim",
        abstract: "Run custom SwiftSyntax-based linting rules",
        discussion: """
        Runs custom SwiftSyntax-based rules that enforce SwiftUI structure and general
        Swift hygiene text-pattern linters cannot express. Files are processed in parallel.

        For the authoritative list of rule IDs and summaries, run --list-rules (the
        single source of truth is the engine's RuleRegistry). Project configuration
        lives in a dedicated .swiftskim.yml — disabled_rules / only_rules to choose which
        rules run, plus skimmable_body_max_lines and excessive_nesting_max_depth
        thresholds. (A legacy swiftskim: block in .swiftlint.yml still supplies
        thresholds when no .swiftskim.yml is present.) --only-rules on the command line
        overrides the config's rule selection.
        """,
    )

    @Argument(help: "File or directory to check (default: current directory)")
    var target: String = "."

    @Flag(name: .long, help: "Disable parallel processing (useful for debugging)")
    var sequential = false

    @Option(name: .long, help: "Only run specified rules (comma-separated list of rule IDs)")
    var onlyRules: String?

    @Flag(name: .long, help: "List all custom rule IDs and summaries, then exit")
    var listRules = false

    mutating func run() async throws {
        if listRules {
            try printRuleList()
            return
        }

        let targetURL = URL(fileURLWithPath: target)
        try ConfigDiscovery.validateTarget(targetURL)

        let ruleEnginePath = ConfigDiscovery.customRuleEnginePath
        try RuleEngineBuildHelper.ensureBuilt(ruleEnginePath)

        // Auto-detect Xcode environment via XCODE_VERSION_ACTUAL
        let isXcode = ProcessInfo.processInfo.environment["XCODE_VERSION_ACTUAL"] != nil

        if !isXcode {
            Console.section("🔍 Running Custom SwiftSyntax Rules on: \(target)")
        }

        // Reason: only `excluded:` is shared with SwiftLint. swiftskim's rule selection
        // lives in .swiftskim.yml, and its directory scan has never honored SwiftLint's
        // `included:`, so adopting it for named files would make a single-file run
        // stricter than `swiftskim .` — the inconsistency this scoping exists to remove.
        let scope = LintScope.discover().withoutInclusions
        let filesToCheck = SwiftFileCollector.collect(from: targetURL, scope: scope)

        // Rule selection. A CLI --only-rules is a *full* override of config selection;
        // otherwise use .swiftskim.yml's only_rules / disabled_rules.
        let config = ConfigDiscovery.readSwiftSkimConfig()
        let cliOnly = onlyRules?.split(separator: ",").map { String($0) }
        let effectiveOnly: [String]?
        let effectiveDisabled: [String]?
        if let cliOnly, !cliOnly.isEmpty {
            effectiveOnly = cliOnly
            effectiveDisabled = nil
        } else {
            effectiveOnly = config.onlyRules
            effectiveDisabled = config.disabledRules
        }

        if !isXcode {
            if let effectiveOnly {
                Console.info("Running only: \(effectiveOnly.joined(separator: ", "))")
            } else if let effectiveDisabled {
                Console.info("Disabled: \(effectiveDisabled.joined(separator: ", "))")
            }
        }

        let results = try await checkFiles(
            filesToCheck,
            ruleEngine: ruleEnginePath,
            isXcode: isXcode,
            onlyRules: effectiveOnly,
            disabledRules: effectiveDisabled,
            thresholds: config.thresholds,
        )

        let violationCount = results.filter(\.hasViolations).count

        if !isXcode {
            CustomRulesChecker.printSummary(totalFiles: filesToCheck.count, violations: violationCount)
        }

        if violationCount > 0 {
            throw ExitCode.failure
        }
    }

    /// Print the canonical rule list by delegating to the engine's --list-rules.
    private func printRuleList() throws {
        let enginePath = ConfigDiscovery.customRuleEnginePath
        try RuleEngineBuildHelper.ensureBuilt(enginePath)
        let process = Process()
        process.executableURL = enginePath
        process.arguments = ["--list-rules"]
        try process.run()
        process.waitUntilExit()
    }

    /// Run the rule engine over `files`, in parallel by default (sequential with `--sequential`).
    private func checkFiles(
        _ files: [URL],
        ruleEngine: URL,
        isXcode: Bool,
        onlyRules: [String]?,
        disabledRules: [String]?,
        thresholds: RuleThresholds,
    ) async throws -> [CheckResult] {
        if sequential {
            return try files.map {
                try CustomRulesChecker.checkFile($0, ruleEngine: ruleEngine, xcodeFormat: isXcode, onlyRules: onlyRules, disabledRules: disabledRules, thresholds: thresholds)
            }
        }

        // Reason: structured-concurrency TaskGroup is irreducibly closure → for →
        // addTask; the per-file task body cannot be hoisted out of that shape.
        // swiftskim:disable excessive_nesting
        return try await withThrowingTaskGroup(of: CheckResult.self) { group in
            for fileURL in files {
                group.addTask {
                    try CustomRulesChecker.checkFile(fileURL, ruleEngine: ruleEngine, xcodeFormat: isXcode, onlyRules: onlyRules, disabledRules: disabledRules, thresholds: thresholds)
                }
            }
            var results: [CheckResult] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        // swiftskim:enable excessive_nesting
    }
}
