import Foundation
import Testing

@testable import SharedUtilities

/// Tests for swiftlint directive parsing
struct DirectiveParserTests {
    /// Test swiftlint:disable:next directive
    @Test
    func disableNextDirective() throws {
        let source = """
        // swiftlint:disable:next excessive_nesting
        func deeplyNested() {
            if true {
                if true {
                    if true {
                        print("deep")
                    }
                }
            }
        }
        """

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        // Line 2 is the function declaration
        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 2))
        // Line 3 should not be suppressed
        #expect(!parser.isSuppressed(rule: "excessive_nesting", line: 3))
    }

    /// Test swiftlint:disable:this directive
    @Test
    func disableThisDirective() throws {
        let source = """
        func deeplyNested() { // swiftlint:disable:this excessive_nesting
            if true {
                if true {
                    if true {
                        print("deep")
                    }
                }
            }
        }
        """

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        // Line 1 should be suppressed
        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 1))
        // Line 2 should not be suppressed
        #expect(!parser.isSuppressed(rule: "excessive_nesting", line: 2))
    }

    /// Test file-level swiftlint:disable directive
    @Test
    func fileLevelDisable() throws {
        let source = """
        // swiftlint:disable excessive_nesting

        func deeplyNested1() {
            if true {
                if true {
                    if true {
                        print("deep")
                    }
                }
            }
        }

        func deeplyNested2() {
            if true {
                if true {
                    if true {
                        print("deep")
                    }
                }
            }
        }
        """

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        // All lines should be suppressed
        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 3))
        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 13))
    }

    /// Test file-level swiftlint:enable re-enables rules
    @Test
    func fileLevelEnableAfterDisable() throws {
        let source = """
        // swiftlint:disable excessive_nesting

        func deeplyNested1() {
            if true {
                if true {
                    if true {
                        print("deep")
                    }
                }
            }
        }

        // swiftlint:enable excessive_nesting

        func deeplyNested2() {
            if true {
                if true {
                    if true {
                        print("deep")
                    }
                }
            }
        }
        """

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        // Before enable should be suppressed
        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 3))
        // After enable should NOT be suppressed
        #expect(!parser.isSuppressed(rule: "excessive_nesting", line: 15))
    }

    /// Test multiple rules in same directive
    @Test
    func multipleRulesInDirective() throws {
        let source = """
        // swiftlint:disable:next excessive_nesting skimmable_body
        var body: some View {
            VStack {
                if true {
                    if true {
                        if true {
                            Text("deep")
                        }
                    }
                }
            }
        }
        """

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        // Both rules should be suppressed on line 2
        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 2))
        #expect(parser.isSuppressed(rule: "skimmable_body", line: 2))
        // But not other rules
        #expect(!parser.isSuppressed(rule: "no_group_body", line: 2))
    }

    /// Test rule suppression doesn't affect other rules
    @Test
    func suppressionIsRuleSpecific() throws {
        let source = """
        // swiftlint:disable:next excessive_nesting
        var body: some View {
            Group {
                Text("test")
            }
        }
        """

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        // excessive_nesting should be suppressed
        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 2))
        // But no_group_body should NOT be suppressed
        #expect(!parser.isSuppressed(rule: "no_group_body", line: 2))
    }

    /// Test directive with leading whitespace
    @Test
    func directiveWithWhitespace() throws {
        let source = """
            // swiftlint:disable:next excessive_nesting
        func deeplyNested() {
            print("test")
        }
        """

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        #expect(parser.isSuppressed(rule: "excessive_nesting", line: 2))
    }

    /// Test empty source code
    @Test
    func emptySource() throws {
        let source = ""

        let parser = DirectiveParser()
        parser.parseDirectives(from: source)

        #expect(!parser.isSuppressed(rule: "excessive_nesting", line: 1))
    }
}
