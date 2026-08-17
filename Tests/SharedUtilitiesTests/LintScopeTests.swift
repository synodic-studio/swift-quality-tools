import Foundation
import Testing

@testable import SharedUtilities

/// A file's verdict must not depend on how the linter reached it. SwiftLint applies
/// `included:`/`excluded:` only to files it discovers itself, so without `LintScope` a
/// path named on the command line — what the post-edit hook always passes — is linted
/// with default scope and blocks on files a repo-wide run never checks.
@Suite("LintScope Tests")
struct LintScopeTests {
    private func makeProject(config: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .resolvingSymlinksInPath()
        for directory in ["Sources", "Vendor", "Engine"] {
            try FileManager.default.createDirectory(
                at: root.appendingPathComponent(directory),
                withIntermediateDirectories: true,
            )
        }
        try config.write(
            to: root.appendingPathComponent(".swiftlint.yml"),
            atomically: true,
            encoding: .utf8,
        )
        return root
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private static let scopedConfig = """
    included:
      - Sources
    excluded:
      - Vendor  # inline comments must not become part of the pattern
      - "**/Generated"
    """

    // MARK: - Inclusion

    @Test("A file under an included: path is covered")
    func includedFileIsCovered() throws {
        let root = try makeProject(config: Self.scopedConfig)
        defer { cleanup(root) }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        #expect(scope.included == ["Sources"])
        #expect(scope.covers(root.appendingPathComponent("Sources/Deep/Nested/File.swift")))
    }

    @Test("A file outside every included: path is not covered")
    func fileOutsideInclusionsIsNotCovered() throws {
        let root = try makeProject(config: Self.scopedConfig)
        defer { cleanup(root) }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        #expect(!scope.covers(root.appendingPathComponent("Engine/Rules.swift")))
    }

    @Test("An empty included: list places no inclusion filter")
    func noInclusionsCoversEverything() throws {
        let root = try makeProject(config: "excluded:\n  - Vendor\n")
        defer { cleanup(root) }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        #expect(scope.included.isEmpty)
        #expect(scope.covers(root.appendingPathComponent("Engine/Rules.swift")))
    }

    // MARK: - Exclusion

    @Test("An excluded: path is not covered, even inside an included: one")
    func exclusionBeatsInclusion() throws {
        let root = try makeProject(config: "included:\n  - Sources\nexcluded:\n  - Sources/Generated\n")
        defer { cleanup(root) }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        #expect(!scope.covers(root.appendingPathComponent("Sources/Generated/API.swift")))
        #expect(scope.covers(root.appendingPathComponent("Sources/App.swift")))
    }

    @Test("An inline YAML comment is stripped from an exclusion pattern")
    func inlineCommentStrippedFromPattern() throws {
        let root = try makeProject(config: Self.scopedConfig)
        defer { cleanup(root) }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        #expect(scope.excluded.contains("Vendor"))
        #expect(!scope.covers(root.appendingPathComponent("Vendor/Thing.swift")))
    }

    @Test("A **/ wildcard exclusion matches at any depth")
    func wildcardExclusionMatches() throws {
        let root = try makeProject(config: Self.scopedConfig)
        defer { cleanup(root) }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        #expect(!scope.covers(root.appendingPathComponent("Sources/Generated/API.swift")))
    }

    // MARK: - Boundaries

    @Test("A file outside the config's directory is covered, not silently skipped")
    func fileOutsideConfigRootIsCovered() throws {
        let root = try makeProject(config: Self.scopedConfig)
        defer { cleanup(root) }

        let elsewhere = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)/Scratch.swift")
        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        #expect(scope.covers(elsewhere))
    }

    @Test("withoutInclusions drops the inclusion filter and keeps exclusions")
    func withoutInclusionsKeepsExclusions() throws {
        let root = try makeProject(config: Self.scopedConfig)
        defer { cleanup(root) }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml")).withoutInclusions
        #expect(scope.covers(root.appendingPathComponent("Engine/Rules.swift")))
        #expect(!scope.covers(root.appendingPathComponent("Vendor/Thing.swift")))
    }

    // MARK: - Collector parity

    @Test("A named file and a directory scan agree on the same file")
    func namedFileMatchesDirectoryScan() throws {
        let root = try makeProject(config: Self.scopedConfig)
        defer { cleanup(root) }

        let inScope = root.appendingPathComponent("Sources/App.swift")
        let outOfScope = root.appendingPathComponent("Engine/Rules.swift")
        for file in [inScope, outOfScope] {
            try "struct S {}\n".write(to: file, atomically: true, encoding: .utf8)
        }

        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        let discovered = SwiftFileCollector.collect(from: root, scope: scope)
        #expect(discovered.map(\.lastPathComponent) == ["App.swift"])
        #expect(SwiftFileCollector.collect(from: inScope, scope: scope) == [inScope])
        #expect(SwiftFileCollector.collect(from: outOfScope, scope: scope).isEmpty)
    }

    @Test("This repo's own engine sources are outside its .swiftlint.yml scope")
    func repoEngineSourcesAreOutOfScope() throws {
        let root = TestSupport.repoRoot
        let scope = LintScope.read(configPath: root.appendingPathComponent(".swiftlint.yml"))
        let engineFile = root.appendingPathComponent(
            "CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules/ViewBodyRules.swift",
        )

        #expect(FileManager.default.fileExists(atPath: engineFile.path))
        #expect(!scope.covers(engineFile))
        #expect(scope.covers(root.appendingPathComponent("Sources/SharedUtilities/LintScope.swift")))
        #expect(scope.covers(root.appendingPathComponent("Tests/SharedUtilitiesTests/LintScopeTests.swift")))
    }
}
