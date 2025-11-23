import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintCustomSmart: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run custom SwiftSyntax-based linting rules",
        discussion: """
        This tool runs custom SwiftSyntax-based rules including:
        • SwiftUI View body properties limited to 15 lines maximum
        • SwiftUI View body properties must have exactly one top-level view (never Group)
        • Indentation depth limited to 4 levels maximum for all functions, closures, and initializers
        """,
    )

    @Argument(help: "File or directory to check (default: current directory)")
    var target: String = "."

    mutating func run() throws {
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

        let results = try filesToCheck.map { try CustomRulesChecker.checkFile($0, ruleEngine: ruleEnginePath, xcodeFormat: isXcode) }
        let violationCount = results.filter(\.hasViolations).count

        if !isXcode {
            CustomRulesChecker.printSummary(totalFiles: filesToCheck.count, violations: violationCount)
        }

        if violationCount > 0 {
            throw ExitCode.failure
        }
    }
}
