import Foundation

/// Utilities for colored console output
public enum Console {
    /// Print error message in red
    public static func error(_ message: String) {
        print("\(ANSIColor.red.rawValue)Error: \(message)\(ANSIColor.reset.rawValue)", to: &standardError)
    }

    /// Print success message in green
    public static func success(_ message: String) {
        print("\(ANSIColor.green.rawValue)✅ \(message)\(ANSIColor.reset.rawValue)")
    }

    /// Print info message in cyan
    public static func info(_ message: String) {
        print("\(ANSIColor.cyan.rawValue)ℹ️  \(message)\(ANSIColor.reset.rawValue)")
    }

    /// Print warning message in yellow
    public static func warning(_ message: String) {
        print("\(ANSIColor.yellow.rawValue)⚠️  \(message)\(ANSIColor.reset.rawValue)")
    }

    /// Print message in blue (for section headers)
    public static func section(_ message: String) {
        print("\(ANSIColor.blue.rawValue)\(message)\(ANSIColor.reset.rawValue)")
    }
}
