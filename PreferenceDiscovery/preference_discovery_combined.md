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

**Decision**:You should already know the answer to this based on existing documents we worked on 

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

**Decision**:I'm not even sure if that's allowed but the wrapper definitely goes first 

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

**Decision**:This isn't a real example because View is already main aactor 

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

**Decision**:Always use the inferred type unless you need to coerce it into something else (cgfloat from 1.0) or if you would need to use the type name without the inference (token = SpaceToken.x4 I would prefer to use explicit type so that after the equal sign it is just the static member)

**Reasoning**:General Swift style guide preferences:

- Use type inference for the first part of my decision
- For the second part of the decision it was somewhat arbitrary but I need to pick one way and I do really like the way that Swift lets you skip the type and just use the period for the membership

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

**Decision**:I feel like there's generally two kinds of categories of rappers and I don't know exactly which ones belong to which but MainActor belongs to a group that I believe should be the line above the thing that it is modifying, while State is absolutely something that should be used in line 

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

**Decision**:Definitely grooped

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

**Decision**:Absolutely declaration order 

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

**Decision**:Always type annotation Because empty literal is OK but not preferred and using something like Array and specifying the generic type instead of using the syntactic sugar is a pretty strong no-no 

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

**Decision**:It's okay to go right up to the limit and I will provide feedback if it needs to be broken up in a different way

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

**Decision**:You must split it up unless it would be a destructive or confusing act. If you do think it's a destructive or confusing act then confer with me and I will give you permission to use the SwiftLint ignore or tell you how to approach the refactor 

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

**Decision**:Same rule as View. We might need to create a new rule for that now that you point it out 

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

**Decision**:You already know the answer to this. This is verboten horrible 

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

**Decision**:This is acceptable but not ideal. I think ViewBuilder is best used when there are two different possible types being returned. I think ViewBuilder is best for these multiple views when you're creating something like a container view 

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

**Decision**:I wouldn't call this a complex switch statement in which case that would be fine. But if something really is a complex switch statement with complicated cases, then we want to move that to a computed property. I'll also say that this VStack is wrong because there is only ever going to be one view and the stack has no purpose 

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

**Decision**:When I code by hand, I think there are occasionally good exceptions for allowing modifier on the same line, but I'm going to say that in general this is verboten and they must always be on a new line. I think we already have a lint rule for this though 

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

**Decision**:I don't know what there is really to ask here. A line is a line. Done 

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

**Decision**:If you do this, I will throw my laptop out the window And then jump out after it 

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

**Decision**:It's fine if we're under the body line limit. Times like this are a good time to use the perform argument when it is a closure. That takes no arguments Which isn't what you've presented here but it's an adjacent strategy 

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

**Decision**:I'm not super hardcore about this but I think in general just about everything should have a view suffix. Some other options are a row suffix or a page suffix. A row is something that would be used in something like a list, whereas a page is something that takes up the entire screen or nearly the entire screen but is treated as a very large unit 

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

**Decision**:I've never had a strong opinion on this but I guess we should just pick something and stick with it Let's go with ViewModel I guess 

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

**Decision**: is prefix is ideal but has is alo okay. Shows is not okay.

**Reasoning**:I feel somewhat strongly that a Boolean almost always has to have a verb as the first word. But a verb like shows seems more like an action instead of a state 

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

**Decision**:Option 1 is fine. Option 2 is never okay. Option 3 is good and in this specific example. Though if it says "header section," I think I pretty much want it to be an actual section view. So use some other suffix if it's something else. Even something like title view is okay even if the underlying type is text For example 

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

**Decision**:I prefer the constants option almost always but if it starts getting big then I will break it out into other enums. The ones you have here are decent examples 

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

**Decision**:I think I'm ready to say "never use underscores" for property names 

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

**Decision**:There might be some cases where a global variable makes sense but you need to ask the president (me) first. I would need a more specific example if you think this is still relevant. Especially because I strictly enforce the one declaration per file rule 

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

**Decision**:I have a very strong opinion on some of this. I think a closure that directly does a needed thing should have an action suffix, but if it's something that happens as a result of something else, then the "on" prefix makes sense. The two examples that I draw this reasoning off of are:

1. For something like button the closure argument is action so I like to use the terminology xxAction when I am passing a closure that serves a role like that.
2. But then for something like Sheet there is an onDismiss closure and that isn't the closure that dismisses the sheet. It is the closure that gets run once the sheet is closed. 

Ask me follow-up questions on this if we need to continue to separate this out 

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

**Decision**: Putting the type name in the variable name is I think very bad practice and should only be used when we really need to keep the original variable as it is but we need it to exist in another type too. Then we might suffix the name with the type name or in this case the wrapper name. I realize this goes against our practice for putting "view" in the name of some views, but there I think it is slightly different because we could just as well have a button or a page and those all conform to view as well. But we're treating them a little bit differently and we want the names to be descriptive. So we use the suffix to be descriptive of the kind of content in that view struct, not that it is a view struct 

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

**Decision**:If there's just one preview, I really don't care. I also think that all previews should be combined into one preview that displays all the options. So for example in this case, I would rather have one preview macro that shows each of the three versions of this view. Unless the view that we are putting in the preview is intended to be a whole page, in which case we would use multiple preview macros.

But to get back to your original question, I prefer descriptive names if we are going to name the preview, but probably don't use a name at all if there is only one preview 

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

**Decision**:You already know the answer to this. They go first 

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

**Decision**:I'm going to say a magic number is a magic number and we have a lint rule for that. The rule is to put it in enum constants Well I guess actually that hint is in the SwiftLint custom command but still 

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

**Decision**:I think sometimes it's a matter of degree. Once it's twice, I'm definitely pretty interested in extracting it. But this needs to be weighed against how much we are really cleaning up. A single modifier used three times is still not very much but five modifiers used twice probably makes sense to pull it out 

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

**Decision**:Should be calculated from constants 

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

**Decision**:9 times out of 10 I'm looking for totally flat 

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

**Decision**:Do you mean between a colors enum and a constants enum? If the constants enum is not too big, then just put them there but if it starts getting split up, then a name like colors is totally fine. My thinking here is that I want it to be fast and easy to just add other constants to the constants enum without having to rename it 

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

**Decision**:Pretty much want to extract it into a constants enum 

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

**Decision**:I discussed this earlier but in general in Swift the preferences for type inference. In the example you have here, only the CG float one is an appropriate use of explicit type because 16.0 would otherwise be double type 

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

**Decision**:You know damn well that option two is unacceptable. If the question is supposed to be more nuanced than that, then you'll need to ask it again 

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

**Decision**:Creating a new view file has its own bit of overhead so it really needs to provide some level of simplification. And in the example you've given this is already extremely simple so we should not be putting it into a new view. But I do see that you called it complexSection so there might be more to it that you're implying isn't evident and you might need to ask me again 

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

**Decision**:Yes we already have rules for this. I hate having more than one declaration per file 

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

**Decision**:This seems like a pretty dumb example and it should be kept in the main type. If you want to ask a more interesting version of that, come back to me 

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

**Decision**:Well I think a ViewModel has a one-to-one relationship with a ViewType. I tend to use the word manager but I don't know if there might be some other preference, or norm, or style guidelines for using manager versus controller or something. I guess maybe I'd lean a little bit more toward manager just because when I hear controller I'm thinking it sounds like UI kit world 

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

**Decision**:I feel like I'm somewhat split on this. Sometimes it really makes sense to put it in an extension and I think in the most pure rules that putting it in an extension is the most correct. But sometimes it really just seems like overkill. So this is kind of a 50/50 depends 

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

**Decision**:Discouraged but sometimes makes sense. Especially if it is very tightly coupled to this type and isn't used anywhere else. This might have to be more of a vibe thing and we can just say probably preference for not nesting the types but it's an option 

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

**Decision**:Matches type name absolutely. Things change a little bit though for extensions But you should ask me some well-generated questions directly for that if there aren't any lower in this document 

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

**Decision**:Yes duh why are you asking I guess?

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

**Decision**:Very much option one unless the view is a page itself In which case multiple previews 

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

**Decision**:Slight preference for minimal even though I think in the long run we will be doing a lot of maximal things. But I think that that might be more like snapshot testing or UI testing or something like that 

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

**Decision**:Oh crap, yeah I don't know. I get really annoyed with mock objects at work but I also know that using the real objects can be really annoying too. I guess I'm not sure here. Maybe you could generate some more examples 

**Reasoning**:

**Confidence**:

**Implementation**:

---

### F4: Preview Placement - Immediately After Type or End of File?

(See examples above for both patterns)

**Decision**:Well since we only have one type declaration per file, these seem to be about the same thing. But I can say that absolutely the preview should be the very last thing whatsoever 

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

**Decision**:Yes I thought we already created a rule for this 

**Reasoning**:

**Confidence**:

**Implementation**:

---

### F6: Preview in Separate File - Acceptable?

(File organization question)
File: Example_F6_Preview.swift (separate file) vs inline in same file

**Decision**:I once did have a preview that got really big and so it made sense to put it in another file. If I'm not mistaken though I think it was because there was a lot of setup to make it work and so it might have just been that in the separate file we made the preview view but we still used that preview view in the base views preview macro 

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
