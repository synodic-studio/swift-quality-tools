import SwiftUI

// Test that all rules now include line numbers

struct TestView: View {
    var body: some View {
        // This VStack has only 1 child - should report line number
        VStack {
            Text("Single child")
        }
    }
}

struct AnotherView: View {
    var body: some View {
        VStack {
            // swiftlintcustom:disable stack_minimum_children
            HStack {
                Text("Suppressed single child")
            }
            // swiftlintcustom:enable stack_minimum_children

            // This if-without-else should report line number
            if true {
                Text("No else")
            }
        }
    }
}

#Preview {
    TestView()
}
