import Foundation

/// Utility for collecting Swift files with exclusion pattern support
public enum SwiftFileCollector {
    /// Collect Swift files from the target URL, excluding specified patterns
    public static func collect(from targetURL: URL, excluding patterns: [String]) -> [URL] {
        var filesToCheck: [URL] = []
        let fileManager = FileManager.default

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: targetURL.path, isDirectory: &isDirectory) else {
            return []
        }

        if isDirectory.boolValue {
            filesToCheck = collectFromDirectory(targetURL, excluding: patterns)
        } else if targetURL.pathExtension == "swift" {
            filesToCheck.append(targetURL)
        } else {
            Console.warning("File '\(targetURL.path)' is not a Swift file")
        }

        return filesToCheck
    }

    /// Collect Swift files from a directory recursively
    private static func collectFromDirectory(_ directoryURL: URL, excluding patterns: [String]) -> [URL] {
        var files: [URL] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift", !shouldExclude(fileURL, patterns: patterns) {
                files.append(fileURL)
            }
        }

        return files.sorted { $0.path < $1.path }
    }

    /// Check if a file should be excluded from linting based on SwiftLint exclusion patterns
    /// - Parameters:
    ///   - fileURL: The file URL to check
    ///   - patterns: Exclusion patterns from SwiftLint config
    /// - Returns: True if the file should be excluded
    private static func shouldExclude(_ fileURL: URL, patterns: [String]) -> Bool {
        let path = fileURL.path
        return patterns.contains { matchesPattern($0, in: path) }
    }

    /// Check if a path matches an exclusion pattern
    private static func matchesPattern(_ pattern: String, in path: String) -> Bool {
        if pattern.hasPrefix("**/") {
            let suffix = String(pattern.dropFirst(3))
            return path.contains("/\(suffix)")
        }

        if pattern.hasSuffix("/**") {
            let prefix = String(pattern.dropLast(3))
            return path.contains("/\(prefix)/")
        }

        if pattern.contains("*") {
            let nonWildcard = pattern.replacingOccurrences(of: "*", with: "")
            return path.contains(nonWildcard)
        }

        return path.contains("/\(pattern)/") || path.hasSuffix("/\(pattern)")
    }
}
