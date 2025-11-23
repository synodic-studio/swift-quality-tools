import Foundation

/// A single violation found during linting
public struct Violation {
    public let line: Int
    public let ruleID: String
    public let message: String

    public init(line: Int, ruleID: String, message: String) {
        self.line = line
        self.ruleID = ruleID
        self.message = message
    }
}
