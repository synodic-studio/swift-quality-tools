// swiftlint:disable file_length type_body_length

import Foundation
import Testing

@testable import SharedUtilities

@Suite("Custom SwiftSyntax Rules Tests", .serialized)
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

    @Test("no_group_body: Detects Group in computed property")
    func noGroupBodyInComputedProperty() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    contentView
                }
            }

            private var contentView: some View {
                Group {
                    Text("One")
                    Text("Two")
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

    @Test("no_group_body: Detects Group in extension")
    func noGroupBodyInExtension() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                Text("Main")
            }
        }

        extension TestView {
            var extraContent: some View {
                Group {
                    Text("Extra 1")
                    Text("Extra 2")
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

    @Test("no_group_body: Detects multiple Group instances")
    func noGroupBodyMultipleInstances() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    content1
                    content2
                }
            }

            private var content1: some View {
                Group {
                    Text("First")
                }
            }

            private var content2: some View {
                Group {
                    Text("Second")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        // Should detect both violations
        let violationCount = output.components(separatedBy: "[no_group_body]").count - 1
        #expect(violationCount == 2)
    }

    @Test("no_group_body: Detects Group in function returning some View")
    func noGroupBodyInFunction() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                makeContent()
            }

            func makeContent() -> some View {
                Group {
                    Text("Function Content")
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

    @Test("no_group_body: Detects Group in conditional branches")
    func noGroupBodyInConditional() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let condition = true

            var body: some View {
                contentView
            }

            private var contentView: some View {
                if condition {
                    Group {
                        Text("True Branch")
                    }
                } else {
                    Text("False")
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

    @Test("no_group_body: Accepts Group in switch expression with modifier")
    func noGroupBodySwitchWithModifier() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            enum DisplayMode {
                case compact, expanded
            }

            let mode: DisplayMode = .compact

            var body: some View {
                switch mode {
                case .compact:
                    Group {
                        Text("Compact")
                    }
                    .padding(.small)
                case .expanded:
                    Text("Expanded")
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

    // MARK: - Excessive Nesting Rule Tests

    @Test("excessive_nesting: Detects nesting level over 3")
    func excessiveNestingViolation() throws {
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
        #expect(output.contains("[excessive_nesting]"))
    }

    @Test("excessive_nesting: Accepts nesting level up to 3")
    func excessiveNestingNoViolation() throws {
        let code = """
        import SwiftUI

        func test() {
            if true {
                if true {
                    print("Acceptable")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[excessive_nesting]"))
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

    // MARK: - Stack Minimum Children Rule Tests

    @Test("stack_minimum_children: Detects VStack with single child")
    func stackMinimumChildrenVStack() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    Text("Only one")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[stack_minimum_children]"))
    }

    @Test("stack_minimum_children: Accepts VStack with ForEach as single child")
    func stackMinimumChildrenForEach() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let items = ["A", "B", "C"]

            var body: some View {
                VStack {
                    ForEach(items, id: \\.self) { item in
                        Text(item)
                    }
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[stack_minimum_children]"))
    }

    @Test("stack_minimum_children: Accepts VStack with if/else containing multiple views")
    func stackMinimumChildrenIfElse() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let condition = true

            var body: some View {
                VStack {
                    if condition {
                        Text("First")
                        Text("Second")
                    } else {
                        Text("Alternative")
                    }
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[stack_minimum_children]"))
    }

    @Test("stack_minimum_children: Detects HStack and ZStack violations")
    func stackMinimumChildrenAllTypes() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    HStack {
                        Text("Only one")
                    }
                    ZStack {
                        Text("Also one")
                    }
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        // Should detect violations for both HStack and ZStack
        let violationCount = output.components(separatedBy: "[stack_minimum_children]").count - 1
        #expect(violationCount == 2)
    }

    // MARK: - No If Modifier Rule Tests

    @Test("no_if_modifier: Detects custom .if modifier usage")
    func noIfModifierViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let condition = true

            var body: some View {
                Text("Hello")
                    .if(condition) { view in
                        view.padding()
                    }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[no_if_modifier]"))
    }

    @Test("no_if_modifier: Accepts standard if statement")
    func noIfModifierStandardIf() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let condition = true

            var body: some View {
                if condition {
                    Text("Hello").padding()
                } else {
                    Text("Goodbye")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_if_modifier]"))
    }

    // MARK: - No If Without Else Rule Tests

    @Test("no_if_without_else: Detects if-without-else in View body")
    func noIfWithoutElseViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let showContent: Bool

            var body: some View {
                VStack {
                    if showContent {
                        Text("Content")
                    }
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[no_if_without_else]"))
    }

    @Test("no_if_without_else: Detects if-without-else in @ViewBuilder property")
    func noIfWithoutElseInViewBuilder() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let condition: Bool

            var body: some View {
                contentView
            }

            @ViewBuilder
            private var contentView: some View {
                if condition {
                    Text("Conditional")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[no_if_without_else]"))
    }

    @Test("no_if_without_else: Accepts if-else in View body")
    func noIfWithoutElseWithElse() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let showContent: Bool

            var body: some View {
                if showContent {
                    Text("Content")
                } else {
                    Text("No Content")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_if_without_else]"))
    }

    @Test("no_if_without_else: Accepts if-without-else outside ViewBuilder")
    func noIfWithoutElseOutsideViewBuilder() throws {
        let code = """
        import Foundation

        struct Calculator {
            func compute(_ value: Int) -> Int {
                if value > 0 {
                    return value * 2
                }
                return 0
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_if_without_else]"))
    }

    @Test("no_if_without_else: Accepts if-else-if chain")
    func noIfWithoutElseChain() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            enum State { case loading, success, error }
            let state: State

            var body: some View {
                if state == .loading {
                    ProgressView()
                } else if state == .success {
                    Text("Done")
                } else {
                    Text("Error")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_if_without_else]"))
    }

    @Test("no_if_without_else: Accepts if in .overlay closure")
    func noIfWithoutElseInOverlay() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var showOverlay = true

            var body: some View {
                Text("Main content")
                    .overlay {
                        if showOverlay {
                            Text("Overlay")
                        }
                    }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_if_without_else]"))
    }

    @Test("no_if_without_else: Accepts if in .background closure")
    func noIfWithoutElseInBackground() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var showBackground = true

            var body: some View {
                Text("Main content")
                    .background {
                        if showBackground {
                            Color.blue
                        }
                    }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[no_if_without_else]"))
    }

    @Test("no_if_without_else: Detects if in .sheet closure")
    func noIfWithoutElseInSheet() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var showSheet = false
            @State private var condition = true

            var body: some View {
                Text("Main")
                    .sheet(isPresented: $showSheet) {
                        if condition {
                            Text("Sheet content")
                        }
                    }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("[no_if_without_else]"))
    }

    // MARK: - View Structure Order Rule Tests

    @Test("view_structure_order: Detects properties out of order")
    func viewStructureOrderViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @State private var counter = 0
            @Environment(\\.colorScheme) var colorScheme

            var body: some View {
                Text("Count: \\(counter)")
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[view_structure_order]"))
    }

    @Test("view_structure_order: Accepts correct property order")
    func viewStructureOrderNoViolation() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            @Environment(\\.colorScheme) var colorScheme
            @State private var counter = 0

            var body: some View {
                Text("Count: \\(counter)")
            }

            private var formattedCount: String {
                "\\(counter)"
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[view_structure_order]"))
    }

    @Test("view_structure_order: Detects init not immediately before body")
    func viewStructureOrderInitPlacement() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            let title: String

            init(title: String) {
                self.title = title
            }

            private var subtitle: String {
                "Subtitle"
            }

            var body: some View {
                Text(title)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[view_structure_order]"))
    }

    // MARK: - Comprehensive Edge Case Tests

    @Test("skimmable_body: Counts content lines accurately")
    func skimmableBodyLineCountAccuracy() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack {
                    Text("1")
                    Text("2")
                    Text("3")
                    Text("4")
                    Text("5")
                    Text("6")
                    Text("7")
                    Text("8")
                    Text("9")
                    Text("10")
                    Text("11")
                    Text("12")
                    Text("13")
                    Text("14")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        // Should not violate - 14 content lines is within limit
        #expect(!output.contains("[skimmable_body]"))
    }

    @Test("excessive_nesting: Allows modifier chains without counting as nesting")
    func excessiveNestingModifierChains() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                Text("Hello")
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .padding()
                    .background(Color.white)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[excessive_nesting]"))
    }

    // MARK: - Single Modifier Per Line Rule Tests

    @Test("single_modifier_per_line: Detects multiple modifiers on same line")
    func singleModifierPerLineMultipleModifiers() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                Text("Hello").padding().background(.red)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[single_modifier_per_line]"))
    }

    @Test("single_modifier_per_line: Accepts modifiers on separate lines")
    func singleModifierPerLineSeparateLines() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                Text("Hello")
                    .padding()
                    .background(.red)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[single_modifier_per_line]"))
    }

    @Test("single_modifier_per_line: Detects modifier after closing delimiter")
    func singleModifierPerLineClosingDelimiter() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                VStack(
                    alignment: .leading
                ).padding()
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[single_modifier_per_line]"))
    }

    @Test("single_modifier_per_line: Accepts non-View context")
    func singleModifierPerLineNonViewContext() throws {
        let code = """
        import Foundation

        class Calculator {
            func calculate() {
                let range1 = (0.0...1.0).contains(0.5)
                let range2 = (1.0...2.0).contains(1.5)
                print(range1 || range2)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[single_modifier_per_line]"))
    }

    @Test("single_modifier_per_line: Detects in ViewModifier body")
    func singleModifierPerLineViewModifier() throws {
        let code = """
        import SwiftUI

        struct TestModifier: ViewModifier {
            func body(content: Content) -> some View {
                content.padding().background(.red)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[single_modifier_per_line]"))
    }

    @Test("single_modifier_per_line: Detects in function returning some View")
    func singleModifierPerLineFunctionReturningView() throws {
        let code = """
        import SwiftUI

        struct TestView: View {
            var body: some View {
                makeContent()
            }

            func makeContent() -> some View {
                Text("Hello").padding().background(.red)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[single_modifier_per_line]"))
    }

    @Test("Multiple rules: File with multiple different violations")
    func multipleRuleViolations() throws {
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

            private var content: some View {
                Group {
                    Text("Content")
                }
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("[skimmable_body]"))
        #expect(output.contains("[no_group_body]"))
    }

    // MARK: - Prefer Swift Testing Rule Tests

    @Test("prefer_swift_testing: Detects import XCTest")
    func preferSwiftTestingImportViolation() throws {
        let code = """
        import XCTest

        class MyTests: XCTestCase {
            func testSomething() {
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[prefer_swift_testing]"))
        #expect(output.contains("import Testing"))
    }

    @Test("prefer_swift_testing: Detects XCTAssertEqual")
    func preferSwiftTestingAssertEqualViolation() throws {
        let code = """
        XCTAssertEqual(1, 1)
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[prefer_swift_testing]"))
        #expect(output.contains("#expect(a == b)"))
    }

    @Test("prefer_swift_testing: Detects XCTAssertTrue")
    func preferSwiftTestingAssertTrueViolation() throws {
        let code = """
        XCTAssertTrue(result)
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[prefer_swift_testing]"))
        #expect(output.contains("#expect(value)"))
    }

    @Test("prefer_swift_testing: Detects XCTFail")
    func preferSwiftTestingFailViolation() throws {
        let code = """
        XCTFail("message")
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[prefer_swift_testing]"))
        #expect(output.contains("Issue.record"))
    }

    @Test("prefer_swift_testing: Accepts Swift Testing imports")
    func preferSwiftTestingNoViolation() throws {
        let code = """
        import Testing

        @Test
        func testSomething() {
            #expect(true)
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[prefer_swift_testing]"))
    }

    @Test("prefer_swift_testing: Detects multiple XCT assertions")
    func preferSwiftTestingMultipleAssertions() throws {
        let code = """
        import XCTest

        class MyTests: XCTestCase {
            func testSomething() {
                XCTAssertEqual(1, 1)
                XCTAssertTrue(true)
                XCTAssertNil(nil as String?)
                XCTFail("fail")
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        // Should have 5 violations: 1 import + 4 assertions
        let violationCount = output.components(separatedBy: "[prefer_swift_testing]").count - 1
        #expect(violationCount == 5)
    }

    // MARK: - Prefer Shorthand Optional Binding Rule Tests

    @Test("prefer_shorthand_optional_binding: Detects if let rename")
    func preferShorthandOptionalBindingIfLetRename() throws {
        let code = """
        func test(value: String?) {
            if let foo = value {
                print(foo)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[prefer_shorthand_optional_binding]"))
        #expect(output.contains("let value"))
    }

    @Test("prefer_shorthand_optional_binding: Detects guard let rename")
    func preferShorthandOptionalBindingGuardLetRename() throws {
        let code = """
        func test(input: Int?) {
            guard let number = input else { return }
            print(number)
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[prefer_shorthand_optional_binding]"))
        #expect(output.contains("let input"))
    }

    @Test("prefer_shorthand_optional_binding: Detects if var rename")
    func preferShorthandOptionalBindingIfVarRename() throws {
        let code = """
        func test(data: [Int]?) {
            if var items = data {
                items.append(1)
                print(items)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(output.contains("⚠️"))
        #expect(output.contains("[prefer_shorthand_optional_binding]"))
        #expect(output.contains("var data"))
    }

    @Test("prefer_shorthand_optional_binding: Accepts shorthand syntax")
    func preferShorthandOptionalBindingShorthand() throws {
        let code = """
        func test(value: String?) {
            if let value {
                print(value)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[prefer_shorthand_optional_binding]"))
    }

    @Test("prefer_shorthand_optional_binding: Ignores same-name binding (SwiftLint handles)")
    func preferShorthandOptionalBindingSameName() throws {
        // Note: SwiftLint's shorthand_optional_binding rule handles this case
        let code = """
        func test(value: String?) {
            if let value = value {
                print(value)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        // Our custom rule should NOT flag same-name bindings
        #expect(!output.contains("[prefer_shorthand_optional_binding]"))
    }

    @Test("prefer_shorthand_optional_binding: Ignores complex expressions")
    func preferShorthandOptionalBindingComplexExpression() throws {
        // Only simple identifier references should be flagged
        let code = """
        func test(dict: [String: String]) {
            if let value = dict["key"] {
                print(value)
            }
        }
        """

        let file = try createTempSwiftFile(content: code)
        defer { cleanup(file) }

        let output = try runRuleEngine(on: file)
        #expect(!output.contains("[prefer_shorthand_optional_binding]"))
    }
}
