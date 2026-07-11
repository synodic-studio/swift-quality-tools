import Foundation

/// Shared test setup.
///
/// Under the test runner the executable directory is the Swift toolchain, not the
/// repo, so `ConfigDiscovery`'s binary-relative walk-up can't find the bundled
/// `Configs/` or the built engine. Tests therefore declare the resource root
/// explicitly via `SWIFTSKIM_HOME`, derived from this file's own location rather
/// than any hardcoded path.
enum TestSupport {
    /// Repo root: …/Tests/SharedUtilitiesTests/TestSupport.swift → up three levels.
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    /// Point config/engine resolution at the repo when running under the test runner.
    /// Idempotent; respects an already-set `SWIFTSKIM_HOME`.
    static func ensureSwiftskimHome() {
        let existing = ProcessInfo.processInfo.environment["SWIFTSKIM_HOME"]
        if existing?.isEmpty ?? true {
            setenv("SWIFTSKIM_HOME", repoRoot.path, 1)
        }
    }
}
