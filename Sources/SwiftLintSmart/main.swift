import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftLintSmart: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run SwiftLint with smart config discovery",
        discussion: """
        Smart config discovery order:
        1. --config parameter if provided
        2. .swiftlint.yml or .swiftlint.yaml in current directory (error if both)
        3. Walk up directories until finding config file
        4. Fallback to shared config in ~/Developer/swift-quality-tools/Configs/
        5. Error if no config found
        """,
    )

    @Argument(help: "File or directory to lint (default: current directory)")
    var target: String = "."

    @Option(help: "Explicit config file path")
    var config: String?

    mutating func run() throws {
        let targetURL = URL(fileURLWithPath: target)

        // Validate target exists
        do {
            try ConfigDiscovery.validateTarget(targetURL)
        } catch {
            let errorMsg = ErrorFormatter.formatTargetError(
                tool: "SwiftLintSmart",
                target: target,
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }

        // Discover config file
        let configURL: URL
        do {
            let explicitConfig = config.map { URL(fileURLWithPath: $0) }
            configURL = try ConfigDiscovery.findConfig(
                configNames: [".swiftlint.yml", ".swiftlint.yaml"],
                sharedConfigName: "shared-swiftlint.yml",
                explicitConfig: explicitConfig,
            )
        } catch ConfigDiscoveryError.noConfigFound {
            let errorMsg = ErrorFormatter.formatConfigError(
                tool: "SwiftLintSmart",
                searchPath: targetURL.path,
                configName: ".swiftlint.yml",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        } catch {
            Console.error(error.localizedDescription)
            throw ExitCode.failure
        }

        // Check if swiftlint is installed
        guard ProcessRunner.commandExists("swiftlint") else {
            let errorMsg = ErrorFormatter.formatCommandError(
                tool: "SwiftLintSmart",
                command: "swiftlint",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }

        // Run SwiftLint
        Console.section("🔍 Running SwiftLint on: \(target)")

        do {
            let exitCode = try ProcessRunner.run(
                "swiftlint",
                arguments: ["lint", target, "--config", configURL.path],
            )

            if exitCode == 0 {
                Console.success("SwiftLint completed with no violations")
            } else {
                Console.warning("SwiftLint found violations (exit code: \(exitCode))")
                throw ExitCode(Int32(exitCode))
            }
        } catch let error as ProcessError {
            let errorMsg = ErrorFormatter.format(
                tool: "SwiftLintSmart",
                errorType: "ProcessError",
                problem: error.localizedDescription,
                context: "Running swiftlint command",
                fix: "Check that swiftlint is properly installed and the target path is accessible",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }
    }
}
