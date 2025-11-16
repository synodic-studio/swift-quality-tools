import SwiftUI

// MARK: - Preference Discovery File

//
// This file contains intentional variations of Swift/SwiftUI patterns
// to systematically discover unstated coding preferences.
//
// Purpose: Present edge cases and ambiguous scenarios to extract
// implicit preferences that can be codified into:
// - SwiftSyntax rules (mechanical enforcement)
// - apple-platform-dev skill guidance (workflow decisions)
// - CLAUDE-SWIFT.md reminders (critical patterns)
//
// Instructions:
// 1. Review each category of examples
// 2. For each variation, decide: Accept / Reject / Context-Dependent
// 3. Explain reasoning: "Why does this matter?"
// 4. Rate confidence: Strong / Moderate / Weak
//
// Categories:
// A. Property Wrapper Ordering
// B. View Body Edge Cases
// C. Naming Conventions
// D. Constants Patterns
// E. Architecture Boundaries
// F. Preview Patterns

// MARK: - A. Property Wrapper Ordering (8 variations)

// A1: Standard pattern (current accepted)
struct Example_A1_Standard: View {
    @State private var count = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text("Standard")
    }
}

// A2: Reversed order - private before wrapper
struct Example_A2_ReversedOrder: View {
    private @State private var count = 0
    private @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Reversed")
    }
}

// A3: Multiple wrappers - which order?
struct Example_A3_MultipleWrappers: View {
    @State @MainActor private var count = 0
    var body: some View {
        Text("Multiple wrappers")
    }
}

// A4: Explicit vs inferred type
struct Example_A4_ExplicitType: View {
    @State private var count: Int = 0 // Explicit
    @State private var name = "" // Inferred

    var body: some View {
        Text("Type annotation")
    }
}

// A5: Line breaks with many wrappers
struct Example_A5_LineBreaks: View {
    @State
    @MainActor private var
        count = 0

    var body: some View {
        Text("Line breaks")
    }
}

// A6: Grouped vs separated environment properties
struct Example_A6_Grouping: View {
    // Option 1: Grouped together
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: Settings

    var body: some View {
        Text("Grouping")
    }
}

// A7: Alphabetical ordering within category?
struct Example_A7_Alphabetical: View {
    var body: some View {
        Text("Alphabetical")
    }
}

// A8: Complex initialization
struct Example_A8_ComplexInit: View {
    @State private var items = [String]() // Empty literal
    var body: some View {
        Text("Complex init")
    }
}

// MARK: - B. View Body Edge Cases (10 variations)

// B1: Body at exactly 15 lines - acceptable?
struct Example_B1_Exactly15Lines: View {
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
        } // This makes 15 lines total
    }
}

// B2: Body at 16 lines - one line over limit
struct Example_B2_Exactly16Lines: View {
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
        } // 16 lines - extract?
    }
}

// B3: ViewModifier body - same 15-line rule?
struct Example_B3_ViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1),
            )
    } // ViewModifier: same rules as View?
}

// B4: Computed property returning single view - is this acceptable?
struct Example_B4_ComputedSingleView: View {
    var body: some View {
        content
    }

    private var content: some View {
        VStack {
            Text("Complex")
            Text("Content")
        }
    }
}

// B5: Computed property returning multiple views via Group
struct Example_B5_ComputedMultipleViews: View {
    var body: some View {
        VStack {
            headerViews
            footerViews
        }
    }

    @ViewBuilder private var headerViews: some View {
        Text("Header 1")
        Text("Header 2")
        Text("Header 3")
    }

    @ViewBuilder private var footerViews: some View {
        Text("Footer 1")
        Text("Footer 2")
    }
}

// B6: Body with complex conditional - acceptable pattern?
struct Example_B6_ComplexConditional: View {
    @State private var mode = 0

    var body: some View {
        VStack {
            switch mode {
            case 0:
                Text("Mode Zero")
            case 1:
                Text("Mode One")
            case 2:
                Text("Mode Two")
            default:
                Text("Unknown")
            }
        }
    } // Is switch in body acceptable?
}

// B7: Single-line body with modifier chain
struct Example_B7_SingleLineChain: View {
    var body: some View {
        Text("Hello").padding().background(Color.blue).cornerRadius(8)
    } // Single line but long - acceptable?
}

// B8: Body with ForEach - counts toward line limit?
struct Example_B8_ForEach: View {
    let items = ["A", "B", "C"]

    var body: some View {
        VStack {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .padding()
                    .background(Color.gray)
            }
        }
    } // Does ForEach closure count?
}

// B9: Empty body - placeholder acceptable?
struct Example_B9_EmptyBody: View {
    var body: some View {
        EmptyView()
    }
}

// B10: Body with multiple trailing closures
struct Example_B10_MultipleTrailingClosures: View {
    var body: some View {
        VStack {
            Text("Hello")
        }
        .onAppear {
            print("Appeared")
        }
        .onChange(of: true) {
            print("Changed")
        }
        .task {
            print("Task")
        }
    } // Multiple trailing closures - extract?
}

// MARK: - C. Naming Conventions (10 variations)

// C1: View suffix - required or optional?
struct UserProfile: View { // No "View" suffix
    var body: some View {
        Text("UserProfile")
    }
}

struct UserProfileView: View { // With "View" suffix
    var body: some View {
        Text("UserProfileView")
    }
}

// C2: ViewModel naming
struct Example_C2_ViewModelNaming: View {
    var body: some View {
        Text("ViewModel naming")
    }
}

// C3: Boolean property naming
struct Example_C3_BooleanNaming: View {
    var body: some View {
        Text("Boolean naming")
    }
}

// C4: Computed property names - verb vs noun
struct Example_C4_ComputedNaming: View {
    var body: some View {
        Text("Computed naming")
    }

    /// Option 3: Descriptive
    private var headerSection: some View {
        Text("Header")
    }
}

// C5: Constants enum naming
struct Example_C5_ConstantsNaming: View {
    enum Constants { // "Constants"
        static let padding: CGFloat = 16
    }

    enum Metrics { // "Metrics"
        static let padding: CGFloat = 16
    }

    enum Layout { // "Layout"
        static let padding: CGFloat = 16
    }

    var body: some View {
        Text("Constants naming")
    }
}

// C6: Private property naming with underscore
struct Example_C6_UnderscoreNaming: View {
    var body: some View {
        Text("Underscore naming")
    }
}

/// Option 2: In first type's Constants enum
struct Example_C7_FileLevelConstants: View {
    enum Constants {
        static let padding: CGFloat = 16
    }

    var body: some View {
        Text("File-level constants")
    }
}

// C8: Action handler naming
struct Example_C8_ActionHandlerNaming: View {
    var body: some View {
        Button("Tap", action: handleTap) // handle*
        Button("Tap", action: onTap) // on*
        Button("Tap", action: didTapButton) // did*
        Button("Tap", action: buttonTapped) // *ed suffix
    }

    private func handleTap() {}
    private func onTap() {}
    private func didTapButton() {}
    private func buttonTapped() {}
}

// C9: Binding property naming
struct Example_C9_BindingNaming: View {
    @Binding var isPresented: Bool // Same as source
    @Binding var presented: Bool // Shortened
    @Binding var isPresentedBinding: Bool // Explicit "Binding" suffix

    var body: some View {
        Text("Binding naming")
    }
}

// C10: Preview naming
struct Example_C10_PreviewNaming: View {
    var body: some View {
        Text("Preview naming")
    }
}

#Preview("Default") { // Descriptive name
    Example_C10_PreviewNaming()
}

#Preview { // No name
    Example_C10_PreviewNaming()
}

#Preview("Example_C10_PreviewNaming") { // Type name
    Example_C10_PreviewNaming()
}

// MARK: - D. Constants Patterns (8 variations)

// D1: Constants enum placement - top or bottom of type?
struct Example_D1_ConstantsTop: View {
    enum Constants {
        static let padding: CGFloat = 16
    }

    @State private var count = 0

    var body: some View {
        Text("Constants at top")
    }
}

struct Example_D1_ConstantsBottom: View {
    @State private var count = 0

    var body: some View {
        Text("Constants at bottom")
    }

    enum Constants {
        static let padding: CGFloat = 16
    }
}

// D2: Small magic numbers - acceptable threshold?
struct Example_D2_SmallNumbers: View {
    var body: some View {
        Text("Hello")
            .padding(1) // Is 1 acceptable?
            .padding(2) // Is 2 acceptable?
            .padding(3) // Is 3 acceptable?
            .padding(5) // Is 5 acceptable?
            .padding(10) // Is 10 acceptable?
            .padding(16) // Clearly needs constant
    }
}

// D3: Common values - extract or inline?
struct Example_D3_CommonValues: View {
    var body: some View {
        VStack {
            Text("A").padding(8)
            Text("B").padding(8) // Same value twice - extract?
            Text("C").padding(8) // Three times - definitely extract?
        }
    }
}

// D4: Calculated constants - where to put formula?
struct Example_D4_CalculatedConstants: View {
    enum Constants {
        static let screenWidth: CGFloat = 375
        static let halfWidth = screenWidth / 2 // Calculated from constant
        static let thirdWidth: CGFloat = 375 / 3 // Inline calculation
    }

    var body: some View {
        Text("Calculated constants")
    }
}

// D5: Constants scope - nested or flat?
struct Example_D5_ConstantsScope: View {
    /// Option 1: Flat namespace
    enum Constants {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 2
    }

    /// Option 2: Nested namespaces
    enum Metrics {
        enum Spacing {
            static let padding: CGFloat = 16
        }

        enum Corners {
            static let radius: CGFloat = 8
        }

        enum Shadows {
            static let radius: CGFloat = 2
        }
    }

    var body: some View {
        Text("Constants scope")
    }
}

// D6: Color constants - where to define?
struct Example_D6_ColorConstants: View {
    enum Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
    }

    var body: some View {
        Text("Color constants")
            .foregroundColor(Colors.primary)
    }
}

// D7: String constants - extract or inline?
struct Example_D7_StringConstants: View {
    enum Strings {
        static let title = "Hello World"
        static let subtitle = "Welcome"
    }

    var body: some View {
        VStack {
            Text(Strings.title) // Extracted
            Text("Goodbye World") // Inline - acceptable?
        }
    }
}

// D8: CGFloat vs Double vs Int for constants
struct Example_D8_NumericTypes: View {
    enum Constants {
        static let paddingCGFloat: CGFloat = 16.0
        static let paddingDouble: Double = 16.0
        static let paddingInt: Int = 16
        static let paddingInferred = 16.0 // Type inference
    }

    var body: some View {
        Text("Numeric types")
    }
}

// MARK: - E. Architecture Boundaries (10 variations)

// E1: When to extract computed property vs keep inline?
struct Example_E1_ExtractionThreshold: View {
    var body: some View {
        // Option 1: Inline (3 lines)
        VStack {
            Text("Title")
            Text("Subtitle")
            Text("Detail")
        }
    }

    /// Option 2: Extracted
    var body2: some View {
        headerSection
    }

    private var headerSection: some View {
        VStack {
            Text("Title")
            Text("Subtitle")
            Text("Detail")
        }
    }
}

// E2: When to create new View type vs computed property?
struct Example_E2_NewViewThreshold: View {
    var body: some View {
        VStack {
            // Used once - keep as computed property?
            complexSection
        }
    }

    private var complexSection: some View {
        VStack {
            Text("Line 1")
            Text("Line 2")
            Text("Line 3")
            Text("Line 4")
            Text("Line 5")
        }
    }
}

/// Should this be extracted to separate View?
struct ComplexSectionView: View {
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

// E3: File organization - one type per file strictly?
struct SmallHelper {
    let value: Int
}

struct Example_E3_MultipleTypes: View {
    let helper = SmallHelper(value: 10)

    var body: some View {
        Text("Multiple types")
    }
}

// Two types in one file - acceptable for small helpers?

// E4: Extension usage - when to use?
struct Example_E4_Extensions: View {
    var body: some View {
        Text("Extensions")
    }
}

/// Option 1: Methods in main type
extension Example_E4_Extensions {
    private func helperMethod() {
        print("Helper")
    }
}

/// Option 2: Keep in main type
struct Example_E4_NoExtensions: View {
    var body: some View {
        Text("No extensions")
    }

    private func helperMethod() {
        print("Helper")
    }
}

// E5: Preview placement - in same file or separate?
// (Covered in F6)

// E6: Manager vs ViewModel vs Controller naming
class UserDataManager: ObservableObject {
    @Published var name = ""
}

class UserDataViewModel: ObservableObject {
    @Published var name = ""
}

class UserDataController: ObservableObject {
    @Published var name = ""
}

// E7: Protocol conformance - extension or inline?
struct Example_E7_ProtocolConformance: View, Identifiable {
    let id = UUID()

    var body: some View {
        Text("Inline conformance")
    }
}

struct Example_E7_ExtensionConformance: View {
    var body: some View {
        Text("Extension conformance")
    }
}

extension Example_E7_ExtensionConformance: Identifiable {
    var id: UUID { UUID() }
}

// E8: Nested types - when acceptable?
struct Example_E8_NestedTypes: View {
    enum Mode {
        case light
        case dark
    }

    struct Configuration {
        let mode: Mode
    }

    var body: some View {
        Text("Nested types")
    }
}

// E9: File naming - match type name or descriptive?
// File: "Example_E9_FileNaming.swift" (matches type)
// vs
// File: "UserProfileScreen.swift" (descriptive)

// E10: Initializer placement - before body or after properties?
struct Example_E10_InitPlacement: View {
    @State private var count: Int

    /// Option 1: Before body (as required by linter)
    init(count: Int) {
        _count = State(initialValue: count)
    }

    var body: some View {
        Text("Init placement")
    }
}

// MARK: - F. Preview Patterns (6 variations)

// F1: One comprehensive preview vs multiple focused previews?
struct Example_F1_PreviewCount: View {
    @State private var mode = 0

    var body: some View {
        Text("Preview count")
    }
}

// Option 1: Single comprehensive preview
#Preview("All States") {
    VStack {
        Example_F1_PreviewCount(mode: 0)
        Example_F1_PreviewCount(mode: 1)
        Example_F1_PreviewCount(mode: 2)
    }
}

// Option 2: Multiple focused previews
#Preview("Mode 0") {
    Example_F1_PreviewCount(mode: 0)
}

#Preview("Mode 1") {
    Example_F1_PreviewCount(mode: 1)
}

#Preview("Mode 2") {
    Example_F1_PreviewCount(mode: 2)
}

// F2: Preview content - minimal or realistic?
struct Example_F2_PreviewContent: View {
    let title: String
    let items: [String]

    var body: some View {
        Text("Preview content")
    }
}

// Option 1: Minimal
#Preview("Minimal") {
    Example_F2_PreviewContent(title: "Test", items: [])
}

// Option 2: Realistic
#Preview("Realistic") {
    Example_F2_PreviewContent(
        title: "User Dashboard",
        items: ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"],
    )
}

// F3: Preview with dependencies - mock or real?
struct Example_F3_PreviewDependencies: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        Text("Preview dependencies")
    }
}

#Preview("With Dependencies") {
    Example_F3_PreviewDependencies()
        .environmentObject(Settings()) // Real object
}

// F4: Preview placement - immediately after type or at end of file?
// (See examples above for both patterns)

// F5: Preview for ViewModifier - required?
struct ExampleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.gray)
    }
}

#Preview("Modifier") {
    Text("Hello")
        .modifier(ExampleModifier())
}

// F6: Preview in separate file - acceptable?
// File: Example_F6_Preview.swift (separate file)
// vs
// Inline in same file

// MARK: - Supporting Types

class Settings: ObservableObject {
    @Published var theme = "light"
}

class MyViewModel: ObservableObject {
    @Published var data = ""
}
