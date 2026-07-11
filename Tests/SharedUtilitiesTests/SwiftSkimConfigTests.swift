import Foundation
import Testing

@testable import SharedUtilities

@Suite("swiftskim config (.swiftskim.yml)", .serialized)
struct SwiftSkimConfigTests {
    // MARK: - Helpers

    private func writeConfig(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftskim-\(UUID().uuidString).yml")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func writeSwift(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Test-\(UUID().uuidString).swift")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    /// Run the engine with extra args, returning stdout+stderr and the exit code.
    private func runEngine(on file: URL, _ args: [String]) throws -> (output: String, exit: Int32) {
        TestSupport.ensureSwiftskimHome()
        let process = Process()
        process.executableURL = ConfigDiscovery.customRuleEnginePath
        process.arguments = [file.path] + args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (String(data: data, encoding: .utf8) ?? "", process.terminationStatus)
    }

    /// A view that trips both `no_group_body` and `preview_required`.
    private let badView = """
    import SwiftUI
    struct BadView: View {
        var body: some View {
            Group {
                Text("hi")
            }
        }
    }
    """

    // MARK: - Parser

    @Test("Parses disabled_rules, only_rules, and thresholds")
    func parsesAllKeys() throws {
        let url = try writeConfig("""
        # a comment
        disabled_rules:
          - preview_required
          - prefer_swift_testing

        only_rules:
          - skimmable_body

        skimmable_body_max_lines: 20
        excessive_nesting_max_depth: 4
        """)
        defer { try? FileManager.default.removeItem(at: url) }

        let config = SwiftSkimConfigParser.parse(from: url)
        #expect(config.disabledRules == ["preview_required", "prefer_swift_testing"])
        #expect(config.onlyRules == ["skimmable_body"])
        #expect(config.thresholds.skimmableBodyMaxLines == 20)
        #expect(config.thresholds.excessiveNestingMaxDepth == 4)
    }

    @Test("Absent list keys parse as nil, not empty")
    func absentKeysAreNil() throws {
        let url = try writeConfig("skimmable_body_max_lines: 12\n")
        defer { try? FileManager.default.removeItem(at: url) }

        let config = SwiftSkimConfigParser.parse(from: url)
        #expect(config.onlyRules == nil)
        #expect(config.disabledRules == nil)
        #expect(config.thresholds.skimmableBodyMaxLines == 12)
        #expect(config.thresholds.excessiveNestingMaxDepth == nil)
    }

    // MARK: - Engine denylist + validation

    @Test("--disable-rules suppresses only the named rule")
    func denylistSuppresses() throws {
        let file = try writeSwift(badView)
        defer { try? FileManager.default.removeItem(at: file) }

        let (output, _) = try runEngine(on: file, ["--disable-rules", "preview_required"])
        #expect(!output.contains("[preview_required]"))
        #expect(output.contains("[no_group_body]"))
    }

    @Test("Unknown rule id is a hard error (exit 2), not a silent no-op")
    func unknownIDErrors() throws {
        let file = try writeSwift("import SwiftUI\n")
        defer { try? FileManager.default.removeItem(at: file) }

        let (output, exit) = try runEngine(on: file, ["--disable-rules", "preview_requird"])
        #expect(exit == 2)
        #expect(output.contains("unknown rule id"))
        #expect(output.contains("preview_requird"))
    }

    @Test("only_rules wins over disable_rules for the same id")
    func onlyRulesWinsOverDisable() throws {
        let file = try writeSwift(badView)
        defer { try? FileManager.default.removeItem(at: file) }

        let (output, _) = try runEngine(on: file, ["--only-rules", "no_group_body", "--disable-rules", "no_group_body"])
        #expect(output.contains("[no_group_body]"))
    }
}
