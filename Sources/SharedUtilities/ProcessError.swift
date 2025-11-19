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
