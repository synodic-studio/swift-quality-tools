import ArgumentParser
import Foundation
import SharedUtilities

@main
struct SwiftFormatSmart: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Run SwiftFormat with smart config discovery",
        discussion: """
        Smart config discovery order:
        1. --config parameter if provided
        2. .swiftformat.yml or .swiftformat in current directory (error if both)
        3. Walk up directories until finding config file
        4. Fallback to shared config in ~/Developer/swift-quality-tools/Configs/
        5. Error if no config found
        """,
    )

    @Argument(help: "File or directory to format (default: current directory)")
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
                tool: "SwiftFormatSmart",
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
                configNames: [".swiftformat.yml", ".swiftformat"],
                sharedConfigName: "shared-swiftformat.yml",
                explicitConfig: explicitConfig,
            )
        } catch ConfigDiscoveryError.noConfigFound {
            let errorMsg = ErrorFormatter.formatConfigError(
                tool: "SwiftFormatSmart",
                searchPath: targetURL.path,
                configName: ".swiftformat.yml",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        } catch {
            Console.error(error.localizedDescription)
            throw ExitCode.failure
        }

        // Check if swiftformat is installed
        guard ProcessRunner.commandExists("swiftformat") else {
            let errorMsg = ErrorFormatter.formatCommandError(
                tool: "SwiftFormatSmart",
                command: "swiftformat",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }

        // Run SwiftFormat
        Console.section("🔧 Running SwiftFormat on: \(target)")

        do {
            let exitCode = try ProcessRunner.run(
                "swiftformat",
                arguments: [target, "--config", configURL.path],
            )

            if exitCode == 0 {
                Console.success("SwiftFormat completed successfully")
            } else {
                try throwFormattingError(exitCode: exitCode, target: target)
            }
        } catch let error as ProcessError {
            let errorMsg = ErrorFormatter.format(
                tool: "SwiftFormatSmart",
                errorType: "ProcessError",
                problem: error.localizedDescription,
                context: "Running swiftformat command",
                fix: "Check that swiftformat is properly installed and the target path is accessible",
            )
            Console.error(errorMsg)
            throw ExitCode.failure
        }
    }

    /// Throw an error when formatting fails
    private func throwFormattingError(exitCode: Int, target: String) throws -> Never {
        let errorMsg = ErrorFormatter.format(
            tool: "SwiftFormatSmart",
            errorType: "ExecutionFailed",
            problem: "SwiftFormat failed with exit code \(exitCode)",
            context: "Formatting \(target)",
            fix: "Review SwiftFormat output above for syntax errors or formatting issues",
        )
        Console.error(errorMsg)
        throw ExitCode(Int32(exitCode))
    }
}
