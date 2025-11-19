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
