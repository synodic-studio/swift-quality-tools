import Foundation

/// ANSI color codes for terminal output
public enum ANSIColor: String {
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[1;33m"
    case blue = "\u{001B}[0;34m"
    case cyan = "\u{001B}[0;36m"
    case reset = "\u{001B}[0m"
}

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

/// Standard error output stream
private struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
        FileHandle.standardError.write(Data(string.utf8))
    }
}

private var standardError = StandardError()
