import Foundation

/// Reader for a top-level YAML list of path patterns (`included:` / `excluded:`).
///
/// Deliberately minimal: swiftskim ships no YAML dependency, and these two keys are
/// always a flat list of strings.
enum YAMLPathList {
    /// Parse a top-level list of path patterns from a config file.
    /// - Parameters:
    ///   - section: The top-level key introducing the list, including its colon.
    ///   - config: Config file to read.
    static func parse(section: String, from config: URL) -> [String] {
        guard let contents = try? String(contentsOf: config, encoding: .utf8) else {
            return []
        }

        var patterns: [String] = []
        var inSection = false

        for line in contents.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix(section) {
                inSection = true
                continue
            }

            guard inSection else { continue }
            inSection = handle(line: line, trimmed: trimmed, patterns: &patterns)
        }

        return patterns
    }

    /// Handle one line inside the list.
    /// - Returns: True while still inside the list, false once a new top-level key starts.
    private static func handle(line: String, trimmed: String, patterns: inout [String]) -> Bool {
        // A new top-level (non-indented) key ends the list.
        if !line.isEmpty, !line.first!.isWhitespace, trimmed.contains(":") {
            return false
        }

        if trimmed.hasPrefix("- ") {
            let pattern = stripInlineComment(String(trimmed.dropFirst(2)))
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if !pattern.isEmpty {
                patterns.append(pattern)
            }
        }

        return true
    }

    /// Drop a trailing ` # …` comment so it does not become part of the pattern.
    private static func stripInlineComment(_ value: String) -> String {
        guard let range = value.range(of: " #") else { return value }
        return String(value[value.startIndex ..< range.lowerBound])
    }
}
