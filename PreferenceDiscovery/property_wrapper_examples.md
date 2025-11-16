# Property Wrapper Line Break Examples

**Purpose**: Show every common property wrapper with both inline and preceding-line formats using realistic parameters.

**Task**: Review each example and mark your preference: Inline or Preceding Line

---

## Category 1: SwiftUI Property Wrappers

### @State

```swift
// Inline
@State private var count = 0
@State private var isExpanded = false
@State private var selectedItem: Item?

// Preceding Line
@State
private var count = 0

@State
private var isExpanded = false

@State
private var selectedItem: Item?
```

**Preference**:

---

### @Binding

```swift
// Inline
@Binding var isPresented: Bool
@Binding var text: String
@Binding var selection: Int

// Preceding Line
@Binding
var isPresented: Bool

@Binding
var text: String

@Binding
var selection: Int
```

**Preference**:

---

### @StateObject

```swift
// Inline
@StateObject private var viewModel = DashboardViewModel()
@StateObject private var dataManager = DataManager()

// Preceding Line
@StateObject
private var viewModel = DashboardViewModel()

@StateObject
private var dataManager = DataManager()
```

**Preference**:

---

### @ObservedObject

```swift
// Inline
@ObservedObject var settings: Settings
@ObservedObject var networkMonitor: NetworkMonitor

// Preceding Line
@ObservedObject
var settings: Settings

@ObservedObject
var networkMonitor: NetworkMonitor
```

**Preference**:

---

### @Environment

```swift
// Inline
@Environment(\.dismiss) private var dismiss
@Environment(\.colorScheme) private var colorScheme
@Environment(\.managedObjectContext) private var viewContext

// Preceding Line
@Environment(\.dismiss)
private var dismiss

@Environment(\.colorScheme)
private var colorScheme

@Environment(\.managedObjectContext)
private var viewContext
```

**Preference**:

---

### @EnvironmentObject

```swift
// Inline
@EnvironmentObject private var settings: Settings
@EnvironmentObject private var authManager: AuthManager

// Preceding Line
@EnvironmentObject
private var settings: Settings

@EnvironmentObject
private var authManager: AuthManager
```

**Preference**:

---

### @AppStorage

```swift
// Inline
@AppStorage("isDarkMode") private var isDarkMode = false
@AppStorage("userName") private var userName = ""
@AppStorage("fontSize") private var fontSize: Double = 14.0

// Preceding Line
@AppStorage("isDarkMode")
private var isDarkMode = false

@AppStorage("userName")
private var userName = ""

@AppStorage("fontSize")
private var fontSize: Double = 14.0
```

**Preference**:

---

### @SceneStorage

```swift
// Inline
@SceneStorage("selectedTab") private var selectedTab = 0
@SceneStorage("scrollPosition") private var scrollPosition: Double = 0

// Preceding Line
@SceneStorage("selectedTab")
private var selectedTab = 0

@SceneStorage("scrollPosition")
private var scrollPosition: Double = 0
```

**Preference**:

---

### @FetchRequest

```swift
// Inline
@FetchRequest(sortDescriptors: [SortDescriptor(\.name)]) private var users: FetchedResults<User>
@FetchRequest(sortDescriptors: [], predicate: NSPredicate(format: "isComplete == false")) private var tasks: FetchedResults<Task>

// Preceding Line
@FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
private var users: FetchedResults<User>

@FetchRequest(
    sortDescriptors: [],
    predicate: NSPredicate(format: "isComplete == false")
)
private var tasks: FetchedResults<Task>
```

**Preference**:

---

### @SectionedFetchRequest

```swift
// Inline
@SectionedFetchRequest(sectionIdentifier: \.category, sortDescriptors: [SortDescriptor(\.name)]) private var groupedItems: SectionedFetchResults<String, Item>

// Preceding Line
@SectionedFetchRequest(
    sectionIdentifier: \.category,
    sortDescriptors: [SortDescriptor(\.name)]
)
private var groupedItems: SectionedFetchResults<String, Item>
```

**Preference**:

---

### @Namespace

```swift
// Inline
@Namespace private var animation
@Namespace private var heroEffect

// Preceding Line
@Namespace
private var animation

@Namespace
private var heroEffect
```

**Preference**:

---

### @GestureState

```swift
// Inline
@GestureState private var dragOffset = CGSize.zero
@GestureState private var isPressing = false

// Preceding Line
@GestureState
private var dragOffset = CGSize.zero

@GestureState
private var isPressing = false
```

**Preference**:

---

### @FocusState

```swift
// Inline
@FocusState private var isFocused: Bool
@FocusState private var focusedField: Field?

// Preceding Line
@FocusState
private var isFocused: Bool

@FocusState
private var focusedField: Field?
```

**Preference**:

---

### @AccessibilityFocusState

```swift
// Inline
@AccessibilityFocusState private var isAccessibilityFocused: Bool

// Preceding Line
@AccessibilityFocusState
private var isAccessibilityFocused: Bool
```

**Preference**:

---

## Category 2: Combine Property Wrappers

### @Published

```swift
// Inline (in ObservableObject)
@Published var items: [Item] = []
@Published var isLoading = false
@Published var errorMessage: String?

// Preceding Line
@Published
var items: [Item] = []

@Published
var isLoading = false

@Published
var errorMessage: String?
```

**Preference**:

---

## Category 3: Concurrency & Type System Attributes

### @MainActor

```swift
// Inline
@MainActor private var uiState = UIState()
@MainActor private func updateUI() { }

// Preceding Line
@MainActor
private var uiState = UIState()

@MainActor
private func updateUI() { }
```

**Preference**:

---

### @available

```swift
// Inline
@available(iOS 16, *) var modernFeature: String { "New" }
@available(macOS 13, *) func newAPI() { }

// Preceding Line
@available(iOS 16, *)
var modernFeature: String { "New" }

@available(macOS 13, *)
func newAPI() { }
```

**Preference**:

---

### @objc

```swift
// Inline (if using UIKit/AppKit interop)
@objc private func handleNotification(_ notification: Notification) { }
@objc dynamic var observableProperty = ""

// Preceding Line
@objc
private func handleNotification(_ notification: Notification) { }

@objc
dynamic var observableProperty = ""
```

**Preference**:

---

### @IBOutlet / @IBAction

```swift
// Inline (if using UIKit/AppKit)
@IBOutlet weak var titleLabel: UILabel!
@IBAction func buttonTapped(_ sender: UIButton) { }

// Preceding Line
@IBOutlet
weak var titleLabel: UILabel!

@IBAction
func buttonTapped(_ sender: UIButton) { }
```

**Preference**:

---

### @Sendable

```swift
// Inline (function types)
let handler: @Sendable (String) -> Void = { _ in }
var callback: @Sendable () async -> String

// Preceding Line
let handler: @Sendable
    (String) -> Void = { _ in }

var callback: @Sendable
    () async -> String
```

**Preference**:

---

### @escaping

```swift
// Inline (function parameters)
func performAsync(completion: @escaping (Result<String, Error>) -> Void) { }
func delayed(_ action: @escaping () -> Void) { }

// Note: @escaping is always inline with parameter, this is more about whether
// the parameter itself should break to a new line

// Same line
func performAsync(completion: @escaping (Result<String, Error>) -> Void) { }

// Parameter on new line
func performAsync(
    completion: @escaping (Result<String, Error>) -> Void
) { }
```

**Preference**: (Note: This is more about parameter formatting than @escaping itself)

---

### @autoclosure

```swift
// Inline (function parameters)
func assert(_ condition: @autoclosure () -> Bool, message: String) { }

// Parameter on new line
func assert(
    _ condition: @autoclosure () -> Bool,
    message: String
) { }
```

**Preference**: (Note: This is more about parameter formatting)

---

### @unchecked Sendable

```swift
// Inline
class LegacyClass: @unchecked Sendable {
    var unsafeState: String = ""
}

// Preceding Line
class LegacyClass: @unchecked
    Sendable {
    var unsafeState: String = ""
}
```

**Preference**:

---

## Category 4: Testing Attributes

### @Test (Swift Testing)

```swift
// Inline
@Test func additionWorks() { }
@Test("User creation succeeds") func userCreation() { }
@Test(.disabled("Known issue")) func flakyTest() { }

// Preceding Line
@Test
func additionWorks() { }

@Test("User creation succeeds")
func userCreation() { }

@Test(.disabled("Known issue"))
func flakyTest() { }
```

**Preference**:

---

### @Suite (Swift Testing)

```swift
// Inline
@Suite struct MathTests { }
@Suite("Network Operations") struct NetworkTests { }

// Preceding Line
@Suite
struct MathTests { }

@Suite("Network Operations")
struct NetworkTests { }
```

**Preference**:

---

## Summary Section

After reviewing all examples above, please summarize:

**Category 1 (Inline)** - Property wrappers that should stay on same line:
-

**Category 2 (Preceding Line)** - Attributes that should go on line above:
-

**Rule/Pattern**: What distinguishes Category 1 from Category 2?
-

---

## Notes

- Some attributes like @escaping and @autoclosure are part of parameter types, so their "line break" is more about parameter formatting than the attribute itself
- @Sendable when used with closures is part of the type signature
- Focus on the cases where you have a clear preference for property/method declarations
