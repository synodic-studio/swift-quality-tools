# Swift Preference Discovery - Combined Review Document

**Session Date**: [Date]
**Reviewer**: Bryan Costanza
**Duration**: 90-120 minutes

## Instructions

For each code example, dictate your responses to these prompts:

1. **Decision**: Say "Accept" or "Reject" or "Context"
2. **Reasoning**: Explain why this matters (1-2 sentences)
3. **Confidence**: Say "Strong" or "Moderate" or "Weak"
4. **Implementation**: Say "SwiftSyntax" or "Skill" or "CLAUDE-SWIFT" or "None"

---

## A. Property Wrapper Ordering

### A1: Standard Pattern

```swift
struct Example_A1_Standard: View {
    @State private var count = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Text("Standard")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### A2: Reversed Order (private before wrapper)

```swift
struct Example_A2_ReversedOrder: View {
    private @State var count = 0
    private @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Reversed")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### A3: Multiple Wrappers - Which Order?

```swift
struct Example_A3_MultipleWrappers: View {
    @State @MainActor private var count = 0
    // vs
    @MainActor @State private var count2 = 0

    var body: some View {
        Text("Multiple wrappers")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### A4: Explicit vs Inferred Type

```swift
struct Example_A4_ExplicitType: View {
    @State private var count: Int = 0  // Explicit
    @State private var name = ""        // Inferred

    var body: some View {
        Text("Type annotation")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### A5: Line Breaks with Many Wrappers

```swift
struct Example_A5_LineBreaks: View {
    @State
    @MainActor
    private var
        count = 0

    var body: some View {
        Text("Line breaks")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### A6: Grouped vs Separated Environment Properties

```swift
struct Example_A6_Grouping: View {
    // Option 1: Grouped together
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: Settings

    // Option 2: Separated by blank lines
    @Environment(\.dismiss) private var dismiss2

    @Environment(\.colorScheme) private var colorScheme2

    @EnvironmentObject private var settings2: Settings

    var body: some View {
        Text("Grouping")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### A7: Alphabetical Ordering Within Category

```swift
struct Example_A7_Alphabetical: View {
    // Option 1: Declaration order
    @State private var zebra = ""
    @State private var apple = 0
    @State private var middle = false

    // Option 2: Alphabetical
    @State private var apple2 = 0
    @State private var middle2 = false
    @State private var zebra2 = ""

    var body: some View {
        Text("Alphabetical")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### A8: Complex Initialization

```swift
struct Example_A8_ComplexInit: View {
    @State private var items = [String]()  // Empty literal
    @State private var items2: [String] = []  // Type annotation
    @State private var items3 = Array<String>()  // Constructor

    var body: some View {
        Text("Complex init")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

## B. View Body Edge Cases

### B1: Body at Exactly 15 Lines

```swift
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
        }  // This makes 15 lines total
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B2: Body at 16 Lines (One Over Limit)

```swift
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
        }  // 16 lines - extract?
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B3: ViewModifier Body - Same 15-Line Rule?

```swift
struct Example_B3_ViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .shadow(radius: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }  // ViewModifier: same rules as View?
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B4: Computed Property Returning Single View (Wrapper Pattern)

```swift
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B5: Computed Property Returning Multiple Views via ViewBuilder

```swift
struct Example_B5_ComputedMultipleViews: View {
    var body: some View {
        VStack {
            headerViews
            footerViews
        }
    }

    @ViewBuilder
    private var headerViews: some View {
        Text("Header 1")
        Text("Header 2")
        Text("Header 3")
    }

    @ViewBuilder
    private var footerViews: some View {
        Text("Footer 1")
        Text("Footer 2")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B6: Body with Complex Switch Statement

```swift
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
    }  // Is switch in body acceptable?
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B7: Single-Line Body with Long Modifier Chain

```swift
struct Example_B7_SingleLineChain: View {
    var body: some View {
        Text("Hello").padding().background(Color.blue).cornerRadius(8)
    }  // Single line but long - acceptable?
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B8: Body with ForEach - Counts Toward Line Limit?

```swift
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
    }  // Does ForEach closure count?
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B9: Empty Body with EmptyView

```swift
struct Example_B9_EmptyBody: View {
    var body: some View {
        EmptyView()
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### B10: Body with Multiple Trailing Closures

```swift
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
    }  // Multiple trailing closures - extract?
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

## C. Naming Conventions

### C1: View Suffix - Required or Optional?

```swift
struct UserProfile: View {  // No "View" suffix
    var body: some View {
        Text("UserProfile")
    }
}

struct UserProfileView: View {  // With "View" suffix
    var body: some View {
        Text("UserProfileView")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C2: ViewModel Naming

```swift
struct Example_C2_ViewModelNaming: View {
    @StateObject private var viewModel = MyViewModel()  // "viewModel"
    @StateObject private var model = MyViewModel()      // "model"
    @StateObject private var vm = MyViewModel()         // "vm"

    var body: some View {
        Text("ViewModel naming")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C3: Boolean Property Naming

```swift
struct Example_C3_BooleanNaming: View {
    @State private var isLoading = false    // "is" prefix
    @State private var loading = false      // No prefix
    @State private var hasError = false     // "has" prefix
    @State private var showsDetail = false  // "shows" prefix

    var body: some View {
        Text("Boolean naming")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C4: Computed Property Names (noun / verb / descriptive)

```swift
struct Example_C4_ComputedNaming: View {
    var body: some View {
        Text("Computed naming")
    }

    // Option 1: Noun form
    private var header: some View {
        Text("Header")
    }

    // Option 2: Verb form
    private var buildHeader: some View {
        Text("Header")
    }

    // Option 3: Descriptive
    private var headerSection: some View {
        Text("Header")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C5: Constants Enum Naming

```swift
struct Example_C5_ConstantsNaming: View {
    enum Constants {  // "Constants"
        static let padding: CGFloat = 16
    }

    enum Metrics {  // "Metrics"
        static let padding: CGFloat = 16
    }

    enum Layout {  // "Layout"
        static let padding: CGFloat = 16
    }

    var body: some View {
        Text("Constants naming")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C6: Private Property Naming with Underscore

```swift
struct Example_C6_UnderscoreNaming: View {
    @State private var _internalState = 0  // Leading underscore
    @State private var internalState = 0   // No underscore

    var body: some View {
        Text("Underscore naming")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C7: File-Level Constants - Where to Define?

```swift
// Option 1: Top of file before types
private let globalPadding: CGFloat = 16

// Option 2: In first type's Constants enum
struct Example_C7_FileLevelConstants: View {
    enum Constants {
        static let padding: CGFloat = 16
    }

    var body: some View {
        Text("File-level constants")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C8: Action Handler Naming

```swift
struct Example_C8_ActionHandlerNaming: View {
    var body: some View {
        Button("Tap", action: handleTap)      // handle*
        Button("Tap", action: onTap)          // on*
        Button("Tap", action: didTapButton)   // did*
        Button("Tap", action: buttonTapped)   // *ed suffix
    }

    private func handleTap() {}
    private func onTap() {}
    private func didTapButton() {}
    private func buttonTapped() {}
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C9: Binding Property Naming

```swift
struct Example_C9_BindingNaming: View {
    @Binding var isPresented: Bool     // Same as source
    @Binding var presented: Bool       // Shortened
    @Binding var isPresentedBinding: Bool  // Explicit "Binding" suffix

    var body: some View {
        Text("Binding naming")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### C10: Preview Naming

```swift
struct Example_C10_PreviewNaming: View {
    var body: some View {
        Text("Preview naming")
    }
}

#Preview("Default") {  // Descriptive name
    Example_C10_PreviewNaming()
}

#Preview {  // No name
    Example_C10_PreviewNaming()
}

#Preview("Example_C10_PreviewNaming") {  // Type name
    Example_C10_PreviewNaming()
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

## D. Constants Patterns

### D1: Constants Enum Placement (top or bottom of type)

```swift
// Option 1: Top
struct Example_D1_ConstantsTop: View {
    enum Constants {
        static let padding: CGFloat = 16
    }

    @State private var count = 0

    var body: some View {
        Text("Constants at top")
    }
}

// Option 2: Bottom
struct Example_D1_ConstantsBottom: View {
    @State private var count = 0

    var body: some View {
        Text("Constants at bottom")
    }

    enum Constants {
        static let padding: CGFloat = 16
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### D2: Small Magic Numbers - Acceptable Threshold?

```swift
struct Example_D2_SmallNumbers: View {
    var body: some View {
        Text("Hello")
            .padding(1)      // Is 1 acceptable?
            .padding(2)      // Is 2 acceptable?
            .padding(3)      // Is 3 acceptable?
            .padding(5)      // Is 5 acceptable?
            .padding(10)     // Is 10 acceptable?
            .padding(16)     // Clearly needs constant
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### D3: Common Values - Extract or Inline? (2x / 3x repetition)

```swift
struct Example_D3_CommonValues: View {
    var body: some View {
        VStack {
            Text("A").padding(8)
            Text("B").padding(8)  // Same value twice - extract?
            Text("C").padding(8)  // Three times - definitely extract?
        }
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### D4: Calculated Constants - Formula in Definition?

```swift
struct Example_D4_CalculatedConstants: View {
    enum Constants {
        static let screenWidth: CGFloat = 375
        static let halfWidth = screenWidth / 2  // Calculated from constant
        static let thirdWidth: CGFloat = 375 / 3  // Inline calculation
    }

    var body: some View {
        Text("Calculated constants")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### D5: Constants Scope (flat or nested namespaces)

```swift
struct Example_D5_ConstantsScope: View {
    // Option 1: Flat namespace
    enum Constants {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 2
    }

    // Option 2: Nested namespaces
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### D6: Color Constants - Where to Define?

```swift
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### D7: String Constants - Extract or Inline?

```swift
struct Example_D7_StringConstants: View {
    enum Strings {
        static let title = "Hello World"
        static let subtitle = "Welcome"
    }

    var body: some View {
        VStack {
            Text(Strings.title)    // Extracted
            Text("Goodbye World")  // Inline - acceptable?
        }
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### D8: Numeric Types for Constants

```swift
struct Example_D8_NumericTypes: View {
    enum Constants {
        static let paddingCGFloat: CGFloat = 16.0
        static let paddingDouble: Double = 16.0
        static let paddingInt: Int = 16
        static let paddingInferred = 16.0  // Type inference
    }

    var body: some View {
        Text("Numeric types")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

## E. Architecture Boundaries

### E1: When to Extract Computed Property vs Keep Inline?

```swift
struct Example_E1_ExtractionThreshold: View {
    // Option 1: Inline (3 lines)
    var body: some View {
        VStack {
            Text("Title")
            Text("Subtitle")
            Text("Detail")
        }
    }

    // Option 2: Extracted
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E2: When to Create New View Type vs Computed Property?

```swift
// Option 1: Computed property (used once)
struct Example_E2_NewViewThreshold: View {
    var body: some View {
        VStack {
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

// Option 2: Separate View
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E3: One Type Per File - Strictly Enforced?

```swift
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E4: Extension Usage - When to Use?

```swift
// Option 1: Extension
struct Example_E4_Extensions: View {
    var body: some View {
        Text("Extensions")
    }
}

extension Example_E4_Extensions {
    private func helperMethod() {
        print("Helper")
    }
}

// Option 2: Keep in main type
struct Example_E4_NoExtensions: View {
    var body: some View {
        Text("No extensions")
    }

    private func helperMethod() {
        print("Helper")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E6: Manager vs ViewModel vs Controller Naming

```swift
class UserDataManager: ObservableObject {
    @Published var name = ""
}

class UserDataViewModel: ObservableObject {
    @Published var name = ""
}

class UserDataController: ObservableObject {
    @Published var name = ""
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E7: Protocol Conformance - Extension or Inline?

```swift
// Option 1: Inline
struct Example_E7_ProtocolConformance: View, Identifiable {
    let id = UUID()

    var body: some View {
        Text("Inline conformance")
    }
}

// Option 2: Extension
struct Example_E7_ExtensionConformance: View {
    var body: some View {
        Text("Extension conformance")
    }
}

extension Example_E7_ExtensionConformance: Identifiable {
    var id: UUID { UUID() }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E8: Nested Types - When Acceptable?

```swift
struct Example_E8_NestedTypes: View {
    enum Mode {
        case light, dark
    }

    struct Configuration {
        let mode: Mode
    }

    var body: some View {
        Text("Nested types")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E9: File Naming - Match Type Name or Descriptive?

```swift
// File: "Example_E9_FileNaming.swift" (matches type)
// vs
// File: "UserProfileScreen.swift" (descriptive)
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### E10: Initializer Placement - Before Body (Required by Linter)

```swift
struct Example_E10_InitPlacement: View {
    @State private var count: Int

    // Before body (as required by linter)
    init(count: Int) {
        _count = State(initialValue: count)
    }

    var body: some View {
        Text("Init placement")
    }
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

## F. Preview Patterns

### F1: One Comprehensive Preview vs Multiple Focused Previews

```swift
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### F2: Preview Content - Minimal or Realistic?

```swift
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
        items: ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    )
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### F3: Preview with Dependencies - Mock or Real?

```swift
struct Example_F3_PreviewDependencies: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        Text("Preview dependencies")
    }
}

#Preview("With Dependencies") {
    Example_F3_PreviewDependencies()
        .environmentObject(Settings())  // Real object
}
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### F4: Preview Placement - Immediately After Type or End of File?

(See examples above for both patterns)

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### F5: Preview for ViewModifier - Required?

```swift
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
```

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

### F6: Preview in Separate File - Acceptable?

(File organization question)
File: Example_F6_Preview.swift (separate file) vs inline in same file

**Decision**:

**Reasoning**:

**Confidence**:

**Implementation**:

---

## Session Summary

**Total Decisions**: 52 edge cases

**Strong Preferences**:

**Moderate Preferences**:

**Weak Preferences**:

**Context-Dependent**:

---

## Codification Plan

**SwiftSyntax Rules** (new rules to implement):

**Skill Updates** (sections to add):

**CLAUDE-SWIFT Updates** (reminders to add):

**No Action** (cases to document for observation):

---

## Follow-Up Actions

1. Implement high-priority SwiftSyntax rules
2. Update apple-platform-dev skill with decision frameworks
3. Add critical anti-patterns to CLAUDE-SWIFT.md
4. Create test suite from discovered patterns
5. Document uncertain cases for future observation

---

## Additional Notes

(Add any insights, patterns, or observations from the session)
