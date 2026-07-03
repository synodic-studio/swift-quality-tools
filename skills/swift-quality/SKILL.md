---
name: swift-quality
description: Use this skill when writing or reviewing Swift/SwiftUI code for quality compliance. Provides the 15-line body rule, five refactoring strategies, view structure order, and guidance for fixing SwiftSyntax rule violations. Tightly coupled with swift-quality-tools custom linting rules.
---

# Swift Quality

## Overview

This skill provides procedural guidance for satisfying Swift code quality rules enforced by swift-quality-tools. The core workflow centers on the 15-line SwiftUI body rule and five refactoring strategies to maintain readable, scannable view code.

## Core Philosophy

When writing Swift and SwiftUI code, prioritize:

- **Skimmability First** - Structure should be clear at a glance
- **Code Clarity Over Cleverness** - Readable code beats clever code
- **YAGNI Enforcement** - Only implement what's explicitly requested

## Compiler Warnings - CRITICAL

**ALL compiler warnings must be taken seriously and fixed immediately.**

- Compiler warnings are NOT optional suggestions
- Warnings indicate real problems that will become errors in future Swift versions
- NEVER ignore warnings in build output
- ALWAYS fix warnings before considering a task complete
- Concurrency warnings especially critical - they indicate potential race conditions and crashes

**When running xcodebuild:**
1. Always check for warnings in the output
2. Fix all warnings before marking work complete
3. Pay special attention to:
   - Concurrency/actor isolation warnings
   - Sendable conformance warnings
   - MainActor isolation warnings
   - Deprecation warnings

## Swift Quality Tools - CRITICAL

**ALWAYS use the -smart versions of Swift quality tools:**
- ✅ `swiftformat-smart` - Auto-discovers project config
- ✅ `swiftlint-smart` - Auto-discovers project config
- ✅ `swiftlintcustom-smart` - Runs custom SwiftSyntax rules

**NEVER use bare commands:**
- ❌ `swiftformat` - Uses wrong/default config
- ❌ `swiftlint` - Uses SwiftLint defaults that conflict with SwiftFormat

**Why this matters:**
- Bare `swiftlint` uses default rules that **reject trailing commas**
- `swiftformat` is configured to **add trailing commas**
- This creates a conflict where tools fight each other
- The shared config (`shared-swiftlint.yml`) correctly disables `trailing_comma` rule
- Only `-smart` versions find and use the correct shared config

**The -smart tools automatically:**
1. Check for `--config` parameter (explicit override)
2. Look in current directory for config
3. Walk up directory tree to find config
4. Fall back to shared config in `~/Developer/swift-quality-tools/Configs/`
5. Error if no config found (fail fast)

### Batch Editing for Performance

**When fixing many lint violations across multiple files, use batch editing:**

Why batch editing is faster:
- Quality hooks run after **every** Edit tool use
- 50 individual edits = 50 hook runs (slow)
- 1 batch edit with 50 changes = 1 hook run (fast)

**Use batch editing when:**
- Fixing similar violations across multiple files (trailing whitespace, formatting, etc.)
- Making systematic changes (renaming, adding imports, removing code)
- Addressing lint violations from a quality check run
- Working with 5+ files that need similar changes

**When NOT to batch:**
- Different types of changes that need individual review
- Complex refactoring where you want to see intermediate results
- When edits might fail and you want to isolate issues

## Primary Workflow: The 15-Line Body Rule

### The Rule

All SwiftUI `body` properties must be **15 lines or fewer** to maintain skimmability.

**Additional Requirements:**
- Must have **exactly one top-level view** (never use `Group` as top-level)
- Structure must be immediately clear when scanning code
- Complex logic belongs in computed properties or handler functions, not inline

**Enforcement:**
- Automated via `skimmable_body` SwiftSyntax rule
- PostToolUse hook reports violations as errors after edits
- Use the five refactoring strategies below when violations occur

### Why This Matters

- Views become unreadable beyond this threshold
- Forces proper decomposition and component thinking
- Makes code reviews and debugging significantly easier
- Ensures view structure is apparent at a glance

### The Five Refactoring Strategies

Apply these strategies in order when body exceeds 15 lines:

#### 1. Computed Properties
Extract complex view sections:
```swift
private var headerSection: some View {
    VStack {
        Text("Title")
        Text("Subtitle")
    }
}

// In body:
var body: some View {
    VStack {
        headerSection
        contentView
    }
}
```

#### 2. Handler Functions
Extract closure logic to named functions:
```swift
private func handleSubmit() {
    // Complex submission logic
}

// In body:
Button("Submit", action: handleSubmit)
```

#### 3. Component Extraction
Extract complex parts to separate View structs when justified.

**No Single Rule**: Decision depends on multiple factors.

**Decision Factors:**
1. **Reuse**: Once in file → Computed property; Across files → Extract
2. **File Complexity**: Simple file → Keep; Complex file → Consider extracting
3. **Dependency Separation**: Can reduce arguments → Extract
4. **Parameter Overhead**: Many parameters (5+) → Might be better duplicated

**Simple + Once → Computed Property**
```swift
struct DashboardPage: View {
    var body: some View {
        VStack {
            header  // Shows structural importance
            content
            footer
        }
    }

    private var header: some View {
        VStack {
            Text("Dashboard")
            Text("Welcome back!")
            Image(systemName: "person.circle")
        }
    }
}
```
Reason: Maintains visible structure in body, file not complex.

**Complex + Once → Try Subview Extraction First**
```swift
private var statisticsSection: some View {  // 20+ lines
    VStack(spacing: 12) {
        ForEach(statistics) { stat in
            statisticRow(stat)  // Extract this first
        }
    }
}

private func statisticRow(_ stat: Statistic) -> some View {
    // Extracted complex row logic
}
```
When to extract complex: If file already large OR has many computed properties.

**Used Across Files → Extract (with caveats)**
```swift
struct StatusIndicator: View {
    let isOnline: Bool
    private let onlineColor: Color = .green
    private let offlineColor: Color = .gray
    private let size: CGFloat = 12

    var body: some View {
        Circle()
            .fill(isOnline ? onlineColor : offlineColor)
            .frame(width: size, height: size)
    }
}
// Simple signature: StatusIndicator(isOnline: true)
```
Use stored properties to reduce parameter overhead.

**Decision Process:**
1. Used once? → Probably computed property
2. Used across files? → Probably extract
3. File getting large? → Consider extracting
4. Can reduce dependencies? → Lean toward extracting
5. Would extraction create parameter hell? → Maybe keep duplicated
6. Can use stored properties to reduce parameters? → Extract becomes better

Remember: Extraction has overhead. Justify it with reuse, clarity, or dependency separation.

#### 4. Avoid Pointless Containers
Remove containers that add no structural value:

**Anti-Pattern**: Wrapping conditionals that only return one view at a time

**Switch Statements**
```swift
❌ var body: some View {
    VStack {  // Pointless - switch only ever returns ONE view
        switch mode {
        case .light: Text("Light")
        case .dark: Text("Dark")
        }
    }
}

✅ var body: some View {
    switch mode {
    case .light: Text("Light")
    case .dark: Text("Dark")
    }
}
```

**If/Else Statements**
```swift
❌ var body: some View {
    VStack {  // Pointless - if/else only returns ONE view
        if isLoading {
            ProgressView()
        } else {
            ContentView()
        }
    }
}

✅ var body: some View {
    if isLoading {
        ProgressView()
    } else {
        ContentView()
    }
}
```

**Single-Branch Conditionals**
When conditional controls visibility of entire view, hoist it to where visibility is relevant:
```swift
❌ var body: some View {
    VStack {
        header
        if let data = viewModel.data {
            DataView(data: data)  // Hidden in subview
        }
        footer
    }
}

✅ var body: some View {
    if let data = viewModel.data {  // Visibility immediately clear
        VStack {
            header
            DataView(data: data)
            footer
        }
    }
}
```

**Exception**: Keep conditional in container if it's part of the structural layout:
```swift
✅ var body: some View {
    VStack {
        header
        if let data = viewModel.data {
            DataView(data: data)  // Part of VStack structure
        }
        footer  // Footer always shows
    }
}
```

**Need Modifiers?** Use Group, not VStack/HStack:
```swift
❌ var body: some View {
    VStack {  // VStack has no structural purpose
        switch mode {
        case .light: Text("Light")
        case .dark: Text("Dark")
        }
    }
    .padding()
}

✅ var body: some View {
    Group {  // Group appropriate for modifier application
        switch mode {
        case .light: Text("Light")
        case .dark: Text("Dark")
        }
    }
    .padding()
}
```

Note: `no_group_body` rule allows Group as top-level when it has modifiers.

#### 5. Modifier Chains
Group related modifiers into computed properties:
```swift
private var cardStyle: some View {
    self
        .padding()
        .background(Color.white)
        .cornerRadius(8)
}
```

## View Structure Order

Enforce this order for all SwiftUI view properties:

1. Embedded types (enums, structs, classes)
2. Environment properties (`@Environment`, `@EnvironmentObject`, `@AppStorage`, `@SceneStorage`)
3. Other properties (`@State`, `@Binding`, `let`, `var`)
4. `init` (if present) - must immediately precede body
5. `body` property
6. Computed properties and methods

**Enforcement:** Automated via `view_structure_order` SwiftSyntax rule

## Property Wrapper Line Break Formatting

### Inline vs Preceding Line

Property wrappers and attributes fall into two categories based on formatting:

**Category 1 - Inline (Same Line):**
State/data management + short attributes stay on same line as declaration
```swift
@State private var count = 0
@Binding var isPresented: Bool
@StateObject private var viewModel = MyViewModel()
@ObservedObject var settings: Settings
@Environment(\.dismiss) private var dismiss
@EnvironmentObject private var authManager: AuthManager
@Published var items: [Item] = []
@Namespace private var animation
@GestureState private var dragOffset = CGSize.zero
@FocusState private var isFocused: Bool
@AccessibilityFocusState private var isAccessibilityFocused: Bool
func customContainer(@ViewBuilder content: () -> some View) -> some View  // Parameter types
@Sendable (String) -> Void  // Type signatures
@unchecked Sendable
@IBOutlet weak var titleLabel: UILabel!  // Legacy UIKit
@IBAction func buttonTapped(_ sender: UIButton) { }
```

**Category 2 - Preceding Line (with Blank Line Above):**
Type system attributes + storage + complex/long wrappers go on line before declaration
```swift
@available(iOS 16, *)
var modernFeature: String { "New" }

@objc
private func handleNotification(_ notification: Notification) { }

@Test
func additionWorks() { }

@Suite
struct MathTests { }

@MainActor  // On type/function declarations (inline on properties)
private func updateUI() { }

@ViewBuilder  // On computed properties (inline on parameter types)
private var headerSection: some View {
    Text("Header")
    Text("Subtitle")
}

@AppStorage("isDarkMode")
private var isDarkMode = false

@SceneStorage("selectedTab")
private var selectedTab = 0

@FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
private var users: FetchedResults<User>

@SectionedFetchRequest(
    sectionIdentifier: \.category,
    sortDescriptors: [SortDescriptor(\.name)]
)
private var groupedItems: SectionedFetchResults<String, Item>
```

**Blank Line Rule:**
Preceding-line wrappers must have a blank line above them, **except if it's the first line in the type declaration**.

```swift
struct MyView: View {
    @available(iOS 16, *)  // First line - no blank line needed
    var modernFeature: String { "New" }

    @State private var count = 0

    @AppStorage("userName")  // Not first line - needs blank line
    private var userName = ""

    var body: some View { ... }
}
```

**Enforcement:** Manual via code review (SwiftFormat doesn't enforce this pattern yet)

## When You See a Violation

SwiftSyntax custom rules enforce architecture and code quality patterns. When the PostToolUse hook reports a violation:

1. **Read the violation message** for the rule identifier
2. **Apply the appropriate fix** based on the rule:

   - **`skimmable_body`** - Body exceeds 15 lines
     - Apply the Five Refactoring Strategies (computed properties, handlers, components, etc.)

   - **`no_group_body`** - Top-level Group without modifiers
     - Replace `Group` with proper container (`VStack`, `HStack`, `ZStack`)
     - Or add view modifiers to the `Group`

   - **`one_top_level_view`** - Multiple sibling views at top level
     - Wrap views in a container (`VStack`, `HStack`, `ZStack`)

   - **`excessive_nesting`** - More than 4 indentation levels
     - Extract nested logic to separate functions/properties
     - Use guard statements for early returns

   - **`view_structure_order`** - Properties out of order
     - Reorder according to the View Structure Order above

   - **`no_wrapper_body`** - Pointless wrapper property
     - Merge wrapper logic directly into `body`
     - Or extract meaningful sections that `body` composes

   - **`blank_line_import_separation`** - Missing blank line
     - Add blank line between regular imports and `@testable` imports

   - **`preview_required`** - Missing #Preview
     - Add at least one `#Preview` showing typical usage

   - **`no_if_modifier`** - Custom .if modifier anti-pattern
     - Use ternary operator or @ViewBuilder instead

   - **`no_if_without_else`** - if-without-else in @ViewBuilder
     - Hoist visibility decision to parent view

   - **`stack_minimum_children`** - Stack with single child
     - Remove unnecessary VStack/HStack/ZStack wrapper

   - **`onchange_ignored_old_value`** - Unused old value in onChange
     - Use 0-parameter onChange closure

   - **`single_modifier_per_line`** - Multiple modifiers on one line
     - Split each modifier to its own line

   - **`prefer_swift_testing`** - XCTest usage detected
     - Replace `import XCTest` with `import Testing`
     - Migrate XCTAssert* calls to Swift Testing equivalents
     - See `references/testing.md` for migration patterns

3. **Verify the fix** by checking hook output after next edit

## File Organization & Extension Patterns

### When to Use Extensions

**Protocol Conformance**: Always use extensions
```swift
struct UserProfile: View {
    var body: some View { ... }
}

extension UserProfile: Identifiable {
    // Already has id, automatic conformance
}

extension UserProfile: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
```

**Private Methods**: Keep inline (default)
```swift
struct ContentView: View {
    var body: some View { ... }

    // Keep methods in main type
    private func loadData() { ... }
    private func saveData() { ... }
}
```

**Computed View Properties**: Keep inline
```swift
struct ProfileView: View {
    var body: some View {
        VStack {
            headerSection
            detailsSection
        }
    }

    private var headerSection: some View { ... }
    private var detailsSection: some View { ... }
}
```

**Type Extensions (Foundation/SwiftUI)**:
- **Private + Specialized** → Keep in file with view
- **Generic (even if used once)** → Separate file for discoverability

```swift
// MessageView.swift
private extension String {
    var formatted: String { ... }  // Specialized, keep here
}

// String+Formatting.swift
extension String {
    var trimmed: String { ... }  // Generic, separate file
}
```

### Extension File Naming

**Naming Pattern**: `TypeName+Feature.swift` (prefer `+` over `.` or concatenation)

**Same File vs Separate**:
- **Keep in Same File**: Small, expected, not "distant requirement"
- **Separate File**: Substantial, unusual for that type

```swift
// UserProfile.swift - small, expected
extension UserProfile: Identifiable {
    // Keep here
}

// UserProfile+Codable.swift - unusual for View
extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey { ... }
}
```

**Directory Organization**:
- **Start**: Next to the type
- **When Many** (4+ = consider, 6-8 = definitely): Move to Extensions/ directory

## Quick Reference: Key Patterns

### Layout Modifiers
- **Overlay/Background**: Use `.overlay()` and `.background()` modifiers, not `ZStack`
- **Frame Alignment**: Prefer `.frame(maxWidth: .infinity, alignment: .leading)` over `HStack + Spacer`
- **Never `.if` Modifier**: Use standard Swift control flow instead

### Optional Handling
```swift
// Prefer:
if let foo {
    // use foo
}

// Over:
if let foo = foo {
    // use foo
}
```

## Swift Code Style Rules

### EmptyView Anti-Pattern - CRITICAL

**NEVER use `EmptyView` as a placeholder or default view.**

This anti-pattern appears when developers use `EmptyView` in switch statements, ternary operators, or conditional returns:

```swift
// ❌ NEVER DO THIS
var body: some View {
    switch viewModel.state {
    case .loading:
        ProgressView()
    case .loaded:
        ContentView()
    default:
        EmptyView()  // WRONG - pointless container
    }
}
```

**Why this is wrong:**
- SwiftUI views support `if/else` and optional views natively
- `EmptyView` creates unnecessary view hierarchy
- Reduces code clarity and intent
- Usually indicates missing business logic

**Correct alternatives:**

```swift
// ✅ Use optional view
var body: some View {
    if viewModel.hasData {
        ContentView(data: viewModel.data)
    }
}

// ✅ Use if/else for clear alternatives
var body: some View {
    if viewModel.isLoading {
        ProgressView()
    } else {
        ContentView()
    }
}

// ✅ Handle all meaningful states
var body: some View {
    switch viewModel.state {
    case .loading:
        ProgressView()
    case .loaded(let data):
        ContentView(data: data)
    case .error(let message):
        ErrorView(message: message)
    // No default with EmptyView needed
    }
}
```

**The only valid use of `EmptyView`** is when you need a concrete type that conforms to `View` for generic constraints, which is extremely rare in application code.

### ViewModel Naming Standard

**Always use `viewModel` for view model properties, never `model` or `vm`.**

```swift
// ✅ Correct
@StateObject private var viewModel = MyViewModel()

// ❌ Wrong
@StateObject private var model = MyViewModel()  // Ambiguous
@StateObject private var vm = MyViewModel()     // Abbreviated
```

**Rationale:**
- `model` is ambiguous (data model vs view model?)
- `vm` is unclear to readers unfamiliar with the abbreviation
- `viewModel` is explicit, searchable, and conventional
- Consistency across codebase aids navigation and comprehension

### Constants and Magic Numbers

**Always use `enum Constants` at the top of the type declaration** instead of magic numbers:
```swift
struct MyView: View {
    enum Constants {
        static let maxRetries = 3
        static let timeout: TimeInterval = 30.0
        static let cornerRadius: CGFloat = 12.0
    }

    var body: some View {
        // Use Constants.cornerRadius instead of literal 12.0
    }
}
```

This pattern:
- Eliminates magic numbers (SwiftLint violation)
- Makes values easy to find and change
- Self-documents the meaning of each value
- Groups related constants logically

### Testing Framework

- Always use Swift Testing (`import Testing`)
- Never use `XCTest`
- Reference: https://developer.apple.com/documentation/testing/migratingfromxctest

## Development Tools

### Periphery - Unused Code Detection

**Installation**: Download latest version directly from GitHub releases when Homebrew is behind
```bash
# Check version
periphery version

# Manual install latest
curl -LO https://github.com/peripheryapp/periphery/releases/download/3.2.0/periphery-3.2.0.zip
unzip periphery-3.2.0.zip
mv periphery /opt/homebrew/bin/periphery
```

**Key Discovery**: Periphery 3.2.0+ supports newer Xcode formats (Xcode 26 Beta) that v2.21.2 doesn't

**Usage**: Use `periphery scan` (auto-detection) for better cross-package analysis

**Configuration Template**:
```yaml
project: ProjectName.xcodeproj
schemes:
  - MainScheme
retain_public: true
retain_objc_accessible: true
retain_assign_only_properties: true
retain_unused_protocol_func_params: true
format: xcode
```

**Best Practices**:
- Run `periphery scan` first to verify project detection works
- Fix imports first (safest), then unused code
- Build frequently during cleanup to catch breaking changes
- SwiftFormat automatically fixes whitespace issues after deletions

### XcodeGen (Future Consideration)

Consider adopting XcodeGen for managing Xcode project files:
- Eliminates .xcodeproj merge conflicts
- Human-readable YAML configuration
- Easier project restructuring
- Consistent project generation

## When to Use This Skill

Activate this skill when:
- Writing or modifying SwiftUI views
- Receiving rule violation messages from PostToolUse hook
- Refactoring views to improve skimmability
- Reviewing Swift code for quality compliance

## Resources

### references/

- **`quality-philosophy.md`** - Why metrics matter, when to apply formatting, naming and commenting guidelines
- **`swiftui-patterns.md`** - Comprehensive SwiftUI patterns with examples (onChange, view structure enforcement, modifier usage)
- **`testing.md`** - Swift Testing standards, best practices, migration from XCTest, and known issues

Load these references when detailed information is needed.
