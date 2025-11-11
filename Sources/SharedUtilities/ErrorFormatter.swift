import Foundation

/// Self-healing error formatter following CLAUDE.md pattern
/// Provides actionable error messages that enable LLM auto-repair
public enum ErrorFormatter {
    /// Format an error with actionable information for LLM
    /// - Parameters:
    ///   - tool: Name of the tool that failed (e.g., "SwiftFormatSmart")
    ///   - errorType: Type of error (e.g., "ConfigNotFound")
    ///   - problem: Clear description of what failed
    ///   - context: What was being attempted
    ///   - file: Optional file location where error occurred
    ///   - fix: Actionable suggestion for how to resolve
    /// - Returns: Formatted error message string
    public static func format(
        tool: String,
        errorType: String,
        problem: String,
        context: String? = nil,
        file: String? = nil,
        fix: String
    ) -> String {
        var lines: [String] = []

        // Header with emoji for visibility
        lines.append("🚨 \(tool) Error: \(errorType)")

        // Problem description
        lines.append("Problem: \(problem)")

        // Optional context
        if let context {
            lines.append("Context: \(context)")
        }

        // Optional file location
        if let file {
            lines.append("File: \(file)")
        }

        // Actionable fix suggestion
        lines.append("Fix: \(fix)")

        return lines.joined(separator: "\n")
    }

    /// Format a config discovery error
    public static func formatConfigError(
        tool: String,
        searchPath: String,
        configName: String,
        fix: String? = nil
    ) -> String {
        let defaultFix = "Create \(configName) in project root or use --config flag to specify location"

        return format(
            tool: tool,
            errorType: "ConfigNotFound",
            problem: "No \(configName) found in current directory or ancestors",
            context: "Searching from \(searchPath)",
            fix: fix ?? defaultFix,
        )
    }

    /// Format a command not found error
    public static func formatCommandError(
        tool: String,
        command: String
    ) -> String {
        format(
            tool: tool,
            errorType: "CommandNotFound",
            problem: "Required command '\(command)' not found in PATH",
            fix: "Install \(command) using: brew install \(command)",
        )
    }

    /// Format a target validation error
    public static func formatTargetError(
        tool: String,
        target: String
    ) -> String {
        format(
            tool: tool,
            errorType: "TargetNotFound",
            problem: "Target path does not exist: \(target)",
            fix: "Verify the path exists and is accessible",
        )
    }

    /// Format a build failure error
    public static func formatBuildError(
        tool: String,
        project: String,
        exitCode: Int32,
        output: String? = nil
    ) -> String {
        var problem = "Build failed for \(project) with exit code \(exitCode)"
        if let output, !output.isEmpty {
            problem += "\n\nBuild output:\n\(output)"
        }

        return format(
            tool: tool,
            errorType: "BuildFailed",
            problem: problem,
            fix: "Review build errors above and fix Swift compilation issues",
        )
    }

    /// Format a multiple configs found error
    public static func formatMultipleConfigsError(
        tool: String,
        configs: [String],
        directory: String
    ) -> String {
        let configList = configs.map { "  - \($0)" }.joined(separator: "\n")

        return format(
            tool: tool,
            errorType: "MultipleConfigsFound",
            problem: "Found multiple config files in \(directory):\n\(configList)",
            fix: "Keep only one config file or use --config to specify which one to use",
        )
    }
}
