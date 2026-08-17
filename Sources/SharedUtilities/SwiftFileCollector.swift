import Foundation

/// Utility for collecting the Swift files a `LintScope` covers.
public enum SwiftFileCollector {
    /// Collect the Swift files under `targetURL` that `scope` covers.
    ///
    /// The scope is applied to an explicitly named file exactly as it is to a discovered
    /// one, so a file that a directory-wide run skips is also skipped when it is named on
    /// the command line — one file, one verdict.
    public static func collect(from targetURL: URL, scope: LintScope) -> [URL] {
        let fileManager = FileManager.default

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: targetURL.path, isDirectory: &isDirectory) else {
            return []
        }

        if isDirectory.boolValue {
            return collectFromDirectory(targetURL, scope: scope)
        }

        guard targetURL.pathExtension == "swift" else {
            Console.warning("File '\(targetURL.path)' is not a Swift file")
            return []
        }

        guard scope.covers(targetURL) else {
            Console.info("Skipping '\(targetURL.path)': outside the configured lint scope")
            return []
        }

        return [targetURL]
    }

    /// Collect Swift files from a directory recursively
    private static func collectFromDirectory(_ directoryURL: URL, scope: LintScope) -> [URL] {
        var files: [URL] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: nil) else {
            return []
        }

        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift", scope.covers(fileURL) {
                files.append(fileURL)
            }
        }

        return files.sorted { $0.path < $1.path }
    }
}
