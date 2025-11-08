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
            """
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
            Console.error(error.localizedDescription)
            throw ExitCode.failure
        }

        // Discover config file
        let configURL: URL
        do {
            let explicitConfig = config.map { URL(fileURLWithPath: $0) }
            configURL = try ConfigDiscovery.findConfig(
                configNames: [".swiftlint.yml", ".swiftlint.yaml"],
                sharedConfigName: "shared-swiftlint.yml",
                explicitConfig: explicitConfig
            )
        } catch {
            Console.error(error.localizedDescription)
            throw ExitCode.failure
        }

        // Check if swiftlint is installed
        guard ProcessRunner.commandExists("swiftlint") else {
            Console.error("swiftlint command not found. Install via: brew install swiftlint")
            throw ExitCode.failure
        }

        // Run SwiftLint
        Console.section("🔍 Running SwiftLint on: \(target)")

        do {
            let exitCode = try ProcessRunner.run(
                "swiftlint",
                arguments: ["lint", target, "--config", configURL.path]
            )

            if exitCode == 0 {
                Console.success("SwiftLint completed with no violations")
            } else {
                Console.warning("SwiftLint found violations (exit code: \(exitCode))")
                throw ExitCode(Int32(exitCode))
            }
        } catch let error as ProcessError {
            Console.error(error.localizedDescription)
            throw ExitCode.failure
        }
    }
}
