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
        """,
    )

    @Argument(help: "File or directory to check (default: current directory)")
    var target: String = "."

    @Flag(name: .long, help: "Disable parallel processing (useful for debugging)")
    var sequential = false

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

        // Process files in parallel or sequentially based on flag
        let results: [CheckResult] = if sequential {
            // Sequential processing (for debugging or when order matters)
            try filesToCheck.map { try CustomRulesChecker.checkFile($0, ruleEngine: ruleEnginePath, xcodeFormat: isXcode) }
        } else {
            // Parallel processing using TaskGroup for optimal performance
            try await withThrowingTaskGroup(of: CheckResult.self) { group in
                for fileURL in filesToCheck {
                    group.addTask {
                        try CustomRulesChecker.checkFile(fileURL, ruleEngine: ruleEnginePath, xcodeFormat: isXcode)
                    }
                }

                // Collect results as tasks complete
                var collectedResults: [CheckResult] = []
                for try await result in group {
                    collectedResults.append(result)
                }
                return collectedResults
            }
        }

        let violationCount = results.filter(\.hasViolations).count

        if !isXcode {
            CustomRulesChecker.printSummary(totalFiles: filesToCheck.count, violations: violationCount)
        }

        if violationCount > 0 {
            throw ExitCode.failure
        }
    }
}
