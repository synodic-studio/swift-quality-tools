import SwiftUI

struct DirectiveSuppressTest: View {
    // swiftlint:disable excessive_nesting
    // This should trigger excessive_nesting but is suppressed by file-level disable
    var deeplyNestedComputed: String {
        if true {
            if true {
                if true {
                    if true {
                        return "deep"
                    }
                }
            }
        }
        return ""
    }

    // swiftlint:enable excessive_nesting

    /// This should trigger excessive_nesting (NOT suppressed)
    var deeplyNestedComputedNoSuppress: String {
        if true {
            if true {
                if true {
                    if true {
                        return "deep"
                    }
                }
            }
        }
        return ""
    }

    // This should trigger skimmable_body but is suppressed
    // swiftlint:disable:next skimmable_body
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
            Text("Line 16 - too many lines!")
        }
    }
}
