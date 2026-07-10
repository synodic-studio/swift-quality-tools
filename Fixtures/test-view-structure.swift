import SwiftUI

/// Test 1: Computed property before body (SHOULD violate - computed must be after body)
struct TestComputedBeforeBody: View {
    @State private var count: Int = 0

    private var config: String {
        "computed value"
    }

    var body: some View {
        Text(config)
    }
}

/// Test 2: Computed property after body (should NOT violate)
struct TestComputedAfterBody: View {
    @State private var count: Int = 0

    var body: some View {
        Text(computed)
    }

    private var computed: String {
        "value"
    }
}

/// Test 3: ViewBuilder computed property (should NOT violate)
struct TestViewBuilderComputed: View {
    var body: some View {
        VStack {
            headerSection
        }
    }

    @ViewBuilder private var headerSection: some View {
        Text("Header")
        Text("Subtitle")
    }
}

/// Test 4: Multiple computed properties (should NOT violate)
struct TestMultipleComputed: View {
    let grayscaleImage: Int?
    @Binding var strategy: String

    var body: some View {
        VStack {
            header
            content
        }
    }

    @ViewBuilder private var content: some View {
        if let grayscaleImage {
            Text("\(grayscaleImage)")
        }
    }

    private var header: some View {
        Text("Header")
    }
}

/// Test 5: Stored property after body (SHOULD violate)
struct TestStoredAfterBody: View {
    var body: some View {
        Text("Hello")
    }

    /// This SHOULD violate - stored property after body
    @State private var count: Int = 0
}

/// Test 6: Correct order (should NOT violate) - stored → body → computed
struct TestCorrectOrder: View {
    @State private var count: Int = 0

    var body: some View {
        Text("Hello")
    }

    private var computed: String {
        "value"
    }
}

class AppState: ObservableObject {}
