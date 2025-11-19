import SwiftUI

/// Test: Multiple ordering violations in one View
struct MultipleViolations: View {
    /// Violation 1: init before stored properties
    init() {}

    /// Violation 2: Stored property after init (should be before)
    @State private var count: Int = 0

    /// Violation 3: Environment property after stored property (should be before)
    @EnvironmentObject var appState: AppState

    var body: some View {
        Text("\(count)")
    }

    /// Violation 5: Another stored property after body
    let constant: String = "test"
}

class AppState: ObservableObject {}
