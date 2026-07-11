import CustomRules
import Foundation
import Testing

/// Exercises the SwiftSkim library through Tuist's SwiftPM integration: lint a
/// known-bad SwiftUI body and assert the built-in `no_group_body` rule fires.
final class DemoTests {
    @Test
    func lintFlagsGroupBody() {
        let bad = """
        import SwiftUI
        struct BadView: View {
            var body: some View {
                Group {
                    Text("hi")
                }
            }
        }
        """
        let violations = SwiftSkim.lint(source: bad)
        #expect(
            violations.contains { $0.contains("no_group_body") },
            "expected a no_group_body violation, got: \(violations)",
        )
    }
}
