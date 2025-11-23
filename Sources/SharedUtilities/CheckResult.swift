import Foundation

/// Result of checking a single file
public struct CheckResult {
    public let hasViolations: Bool
    public let relativePath: String
    public let violations: [Violation]

    public init(hasViolations: Bool, relativePath: String, violations: [Violation] = []) {
        self.hasViolations = hasViolations
        self.relativePath = relativePath
        self.violations = violations
    }
}
