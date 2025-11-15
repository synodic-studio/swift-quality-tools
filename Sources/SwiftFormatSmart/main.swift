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
        let baseConfigURL: URL
        do {
            let explicitConfig = config.map { URL(fileURLWithPath: $0) }
            baseConfigURL = try ConfigDiscovery.findConfig(
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

        // Check for project-specific overrides
        let overridesURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".swiftformat-overrides")

        let configURL: URL
        var tempConfigURL: URL?

        if FileManager.default.fileExists(atPath: overridesURL.path) {
            // Merge base config with overrides
            do {
                Console.info("Found overrides: \(overridesURL.path)")
                let mergedConfig = try ConfigMerger.createMergedConfig(
                    baseConfig: baseConfigURL,
                    overrides: overridesURL,
                )
                tempConfigURL = mergedConfig
                configURL = mergedConfig
                Console.info("Using merged config (base + overrides)")
            } catch {
                let errorMsg = ErrorFormatter.format(
                    tool: "SwiftFormatSmart",
                    errorType: "ConfigMergeError",
                    problem: "Failed to merge config with overrides: \(error.localizedDescription)",
                    context: "Merging \(baseConfigURL.lastPathComponent) + .swiftformat-overrides",
                    fix: "Check .swiftformat-overrides syntax",
                )
                Console.error(errorMsg)
                throw ExitCode.failure
            }
        } else {
            configURL = baseConfigURL
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

        // Clean up temp config file after execution
        defer {
            if let tempURL = tempConfigURL {
                try? FileManager.default.removeItem(at: tempURL)
            }
        }

        do {
            let exitCode = try ProcessRunner.run(
                "swiftformat",
                arguments: [target, "--config", configURL.path],
            )

            if exitCode == 0 {
                Console.success("SwiftFormat completed successfully")
            } else {
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
}
