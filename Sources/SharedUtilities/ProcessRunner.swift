import Foundation

/// Errors that can occur when running processes
public enum ProcessError: LocalizedError {
    case commandNotFound(String)
    case executionFailed(Int32, String)

    public var errorDescription: String? {
        switch self {
        case let .commandNotFound(command):
            "Command not found: \(command)"
        case let .executionFailed(exitCode, command):
            "\(command) failed with exit code: \(exitCode)"
        }
    }
}

/// Utility for running external processes
public enum ProcessRunner {
    /// Check if a command exists in PATH
    ///
    /// - Parameter command: Name of command to check
    /// - Returns: true if command exists, false otherwise
    public static func commandExists(_ command: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    /// Run a command and return its exit code
    ///
    /// - Parameters:
    ///   - executable: Path or name of executable
    ///   - arguments: Arguments to pass to executable
    ///   - workingDirectory: Working directory for command (optional)
    /// - Returns: Exit code from command
    /// - Throws: ProcessError if command cannot be found or executed
    @discardableResult
    public static func run(
        _ executable: String,
        arguments: [String] = [],
        workingDirectory: URL? = nil
    ) throws -> Int32 {
        // If executable doesn't contain a path separator, check if it exists in PATH
        if !executable.contains("/") && !commandExists(executable) {
            throw ProcessError.commandNotFound(executable)
        }

        let process = Process()

        // Set executable URL
        if executable.hasPrefix("/") || executable.hasPrefix("~") {
            // Absolute path or home directory
            let expandedPath = NSString(string: executable).expandingTildeInPath
            process.executableURL = URL(fileURLWithPath: expandedPath)
        } else if executable.contains("/") {
            // Relative path
            process.executableURL = URL(fileURLWithPath: executable)
        } else {
            // Command in PATH
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [executable] + arguments
            return try executeProcess(process)
        }

        process.arguments = arguments

        if let workingDir = workingDirectory {
            process.currentDirectoryURL = workingDir
        }

        return try executeProcess(process)
    }

    /// Execute a process and handle its output
    private static func executeProcess(_ process: Process) throws -> Int32 {
        // Inherit standard output and error from parent process
        // This allows colored output to work properly
        process.standardOutput = FileHandle.standardOutput
        process.standardError = FileHandle.standardError

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus
        } catch {
            throw ProcessError.executionFailed(-1, process.executableURL?.lastPathComponent ?? "unknown")
        }
    }
}
