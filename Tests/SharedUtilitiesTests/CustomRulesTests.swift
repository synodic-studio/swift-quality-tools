import Foundation
import Testing
@testable import SharedUtilities

@Suite("Custom SwiftSyntax Rules Tests")
struct CustomRulesTests {
    // MARK: - Test Fixtures

    private func createTempSwiftFile(content: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let file = tempDir.appendingPathComponent("Test-\(UUID().uuidString).swift")
        try content.write(to: file, atomically: true, encoding: .utf8)
        return file
    }

    private func cleanup(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    private func runRuleEngine(on file: URL) throws -> String {
        let ruleEnginePath = ConfigDiscovery.customRuleEnginePath

        guard FileManager.default.fileExists(atPath: ruleEnginePath.path) else {
            throw TestError.ruleEngineNotBuilt
        }

        let process = Process()
        process.executableURL = ruleEnginePath
        process.arguments = [file.path]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    enum TestError: Error {
        case ruleEngineNotBuilt
    }

    // MARK: - Skimmable Body Rule Tests

    @Test("skimmable_body: Detects View body over 15 lines")
    func skimmableBodyViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                    Text("Line 4")
                    Text("Line 5")
                    Text("Line 6")
                    Text("Line 7")
                    Text("Line 8")
                    Text("Line 9")
                    Text("Line 10")
                    Text("Line 11")
                    Text("Line 12")
                    Text("Line 13")
                    Text("Line 14")
                    Text("Line 15")
                    Text("Line 16")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[skimmable_body]"))
    }

    @Test("skimmable_body: Accepts View body within 15 lines")
    func skimmableBodyNoViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    Text("Line 1")
                    Text("Line 2")
                    Text("Line 3")
                    Text("Line 4")
                    Text("Line 5")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[skimmable_body]"))
    }

    // MARK: - No Group Body Rule Tests

    @Test("no_group_body: Detects top-level Group in View body")
    func noGroupBodyViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                Group {
                    Text("Hello")
                    Text("World")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[no_group_body]"))
    }

    @Test("no_group_body: Accepts Group with modifiers")
    func noGroupBodyWithModifiers() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                Group {
                    Text("Hello")
                    Text("World")
                }
                .padding()
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_group_body]"))
    }

    @Test("no_group_body: Accepts non-Group top-level views")
    func noGroupBodyNoViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_group_body]"))
    }

    // MARK: - One Top Level View Rule Tests

    @Test("one_top_level_view: Detects multiple top-level views")
    func oneTopLevelViewViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                Text("First")
                Text("Second")
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[one_top_level_view]"))
    }

    @Test("one_top_level_view: Accepts single top-level view")
    func oneTopLevelViewNoViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    Text("First")
                    Text("Second")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[one_top_level_view]"))
    }

    @Test("one_top_level_view: Accepts if-else as single statement")
    func oneTopLevelViewIfElse() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let condition = true
            var body: some View {
                if condition {
                    Text("True")
                } else {
                    Text("False")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[one_top_level_view]"))
    }

    // MARK: - Excessive Indentation Rule Tests

    @Test("excessive_indentation: Detects more than 16 spaces")
    func excessiveIndentationViolation() throws {
        let code = """
        import SwiftUI

        func test() {
            if true {
                if true {
                    if true {
                        if true {
                            if true {
                                print("Too deep")
                            }
                        }
                    }
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[excessive_indentation]"))
    }

    @Test("excessive_indentation: Accepts up to 16 spaces")
    func excessiveIndentationNoViolation() throws {
        let code = """
        import SwiftUI

        func test() {
            if true {
                if true {
                    if true {
                        print("Acceptable")
                    }
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[excessive_indentation]"))
    }

    // MARK: - OnChange Ignored Old Value Rule Tests

    @Test("onchange_ignored_old_value: Detects 2-param onChange with _ old value")
    func onChangeIgnoredOldValueViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var value = 0

            var body: some View {
                Text("Value: \\(value)")
                    .onChange(of: value) { _, newValue in
                        print("Changed to: \\(newValue)")
                    }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[onchange_ignored_old_value]"))
    }

    @Test("onchange_ignored_old_value: Detects 2-param onChange with _oldValue pattern")
    func onChangeIgnoredOldValueUnderscorePrefix() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var value = false

            var body: some View {
                Text("Value: \\(value)")
                    .onChange(of: value) { _oldValue, newValue in
                        doSomething(with: newValue)
                    }
            }

            func doSomething(with value: Bool) {
                print(value)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[onchange_ignored_old_value]"))
    }

    @Test("onchange_ignored_old_value: Accepts 0-param onChange")
    func onChangeZeroParamNoViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var value = ""

            var body: some View {
                Text("Value: \\(value)")
                    .onChange(of: value) {
                        print("Changed to: \\(value)")
                    }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[onchange_ignored_old_value]"))
    }

    @Test("onchange_ignored_old_value: Accepts 2-param onChange where both params are used")
    func onChangeBothParamsUsedNoViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var value = 0

            var body: some View {
                Text("Value: \\(value)")
                    .onChange(of: value) { oldValue, newValue in
                        print("Changed from \\(oldValue) to \\(newValue)")
                    }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[onchange_ignored_old_value]"))
    }
}
