import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintCustomSmart: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swift-skim",
        abstract: "Run custom SwiftSyntax-based linting rules",
        discussion: """
        Runs custom SwiftSyntax-based rules that enforce SwiftUI structure and general
        Swift hygiene text-pattern linters cannot express. Files are processed in parallel.

        For the authoritative list of rule IDs and summaries, run the rule engine's
        --list-rules (the single source of truth is its RuleRegistry). Thresholds for
        skimmable_body and excessive_nesting are configurable via a swift_skim: block
        in .swiftlint.yml.
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

        let exclusionPatterns = ConfigDiscovery.readSwiftLintExclusions()
        let filesToCheck = SwiftFileCollector.collect(from: targetURL, excluding: exclusionPatterns)

        // Parse only-rules option
        let rulesToRun = onlyRules?.split(separator: ",").map { String($0) }

        // Print which rules are being run if filtered
        if let rulesToRun, !isXcode {
            Console.info("Running only: \(rulesToRun.joined(separator: ", "))")
        }

        let thresholds = ConfigDiscovery.readRuleThresholds()

        let results = try await checkFiles(
            filesToCheck,
            ruleEngine: ruleEnginePath,
            isXcode: isXcode,
            onlyRules: rulesToRun,
            thresholds: thresholds,
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
        thresholds: RuleThresholds,
    ) async throws -> [CheckResult] {
        if sequential {
            return try files.map {
                try CustomRulesChecker.checkFile($0, ruleEngine: ruleEngine, xcodeFormat: isXcode, onlyRules: onlyRules, thresholds: thresholds)
            }
        }

        // Reason: structured-concurrency TaskGroup is irreducibly closure → for →
        // addTask; the per-file task body cannot be hoisted out of that shape.
        // swiftlintcustom:disable excessive_nesting
        return try await withThrowingTaskGroup(of: CheckResult.self) { group in
            for fileURL in files {
                group.addTask {
                    try CustomRulesChecker.checkFile(fileURL, ruleEngine: ruleEngine, xcodeFormat: isXcode, onlyRules: onlyRules, thresholds: thresholds)
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
