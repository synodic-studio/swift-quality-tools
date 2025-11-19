import Foundation

/// Result of checking a single file
public struct CheckResult {
    public let hasViolations: Bool
    public let relativePath: String

    public init(hasViolations: Bool, relativePath: String) {
        self.hasViolations = hasViolations
        self.relativePath = relativePath
    }
}
