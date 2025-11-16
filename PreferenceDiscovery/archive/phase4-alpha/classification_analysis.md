# Preference Discovery Classification Analysis

**Analysis Date**: 2025-11-15
**Source**: preference_discovery_combined.md (User responses)
**Framework**: classify-swift-rule.md decision tree

---

## Summary Statistics

**Total Preferences Analyzed**: 52
**SwiftSyntax Rules (New)**: 3
**Skill Updates**: 20
**CLAUDE-SWIFT Updates**: 2
**Already Covered**: 12
**No Action Needed**: 9
**Deferred/Needs Clarification**: 6

---

## SwiftSyntax Rules (New Implementation Required)

### 1. ViewModifier Body Line Limit
**Source**: B3
**User Decision**: "Same rule as View. We might need to create a new rule for that now that you point it out"
**Confidence**: Strong (implied)

**Classification**: SwiftSyntax
- **Auto-fixable?** NO
- **AST-detectable?** YES
- **SwiftUI-specific?** YES

**Rationale**: Extend existing `skimmable_body` rule to also check ViewModifier body methods, not just View body properties.

**Implementation**:
- Modify existing `skimmable_body` rule
- Add detection for `ViewModifier` protocol conformance
- Apply same 15-line limit to `func body(content: Content) -> some View`

**Priority**: Medium
**Difficulty**: Low (extend existing rule)
**Value**: Medium (consistency across View and ViewModifier)

---

### 2. No Leading Underscore in Property Names
**Source**: C6
**User Decision**: "I think I'm ready to say never use underscores for property names"
**Confidence**: Strong (implied)

**Classification**: SwiftLint Standard (could be config-based)
- **Auto-fixable?** NO (rename refactoring)
- **AST-detectable?** YES (simple pattern match)
- **SwiftUI-specific?** NO

**Rationale**: Simple pattern detection, not SwiftUI-specific, can be SwiftLint Standard rule.

**Implementation**:
- Add SwiftLint rule: `identifier_name` with custom configuration
- Or create simple custom rule if not supported by standard rules
- Check all property/variable declarations for leading underscore

**Priority**: Low
**Difficulty**: Low
**Value**: Low (style consistency)

**Alternative**: Could just be Skill guidance since it's rare and easily caught in review.

---

### 3. Calculated Constants Must Reference Other Constants
**Source**: D4
**User Decision**: "Should be calculated from constants"
**Confidence**: Moderate (implied)

**Classification**: SwiftSyntax
- **Auto-fixable?** NO
- **AST-detectable?** YES (complex)
- **SwiftUI-specific?** NO

**Rationale**: Detect when a calculated constant uses literal values instead of referencing other constants.

**Implementation**:
- Detect Constants enum static let declarations
- Check if RHS contains arithmetic operations
- Verify operands reference other constants vs literals
- Flag: `static let thirdWidth: CGFloat = 375 / 3` (bad)
- Accept: `static let halfWidth = screenWidth / 2` (good)

**Priority**: Low
**Difficulty**: Medium (requires expression analysis)
**Value**: Low (code quality improvement)

**Alternative**: Skill guidance might be sufficient - this is fairly niche.

---

## Skill Updates (apple-platform-dev)

### Framework 1: Type Inference Guidelines
**Sources**: A4, D8
**User Decision**: "Always use inferred type unless you need to coerce it into something else (CGFloat from 1.0) or if you would need to use the type name without the inference (token = SpaceToken.x4 I would prefer to use explicit type so that after the equal sign it is just the static member)"

**Section**: Code Style Patterns
**Priority**: High
**Difficulty**: Low

**Content**:
```markdown
### Type Inference vs Explicit Types

**General Rule**: Prefer type inference in Swift.

**Use Explicit Types When**:
1. **Type Coercion Required**: `let padding: CGFloat = 16.0` (Double → CGFloat)
2. **Static Member Shorthand**: `let token: SpaceToken = .x4` (enables `.x4` syntax)

**Use Type Inference When**:
- Default case: `let name = "Hello"`, `let count = 0`
- Arrays/Collections: `let items: [String] = []` (preferred) over `let items = [String]()` or `let items = Array<String>()`

**Avoid**:
- Generic constructor syntax: ❌ `Array<String>()` ✅ `[String]()` or `[]`
```

---

### Framework 2: Property Wrapper Line Break Rules
**Source**: A5
**User Decision**: "I feel like there's generally two kinds of categories of wrappers... MainActor belongs to a group that should be the line above the thing that it is modifying, while State is absolutely something that should be used in line"

**Section**: Code Style Patterns
**Priority**: Medium
**Difficulty**: Medium (needs research/examples)

**Content**:
```markdown
### Property Wrapper Line Breaks

**Category 1: Inline Wrappers** (same line as declaration)
- `@State`, `@Binding`, `@Published`
- `@Environment`, `@EnvironmentObject`
- `@StateObject`, `@ObservedObject`

**Category 2: Preceding Line Wrappers**
- `@MainActor` (isolation/concurrency)
- [Need to research: other concurrency/availability attributes?]

**Pattern**:
```swift
// Inline wrappers
@State private var count = 0
@Environment(\.dismiss) private var dismiss

// Preceding line wrappers
@MainActor
private var isolatedProperty: String
```

**Note**: Needs further investigation to categorize all wrapper types.
```

---

### Framework 3: View Suffix Conventions
**Source**: C1
**User Decision**: "I think in general just about everything should have a view suffix. Some other options are a row suffix or a page suffix."

**Section**: Naming Conventions
**Priority**: High
**Difficulty**: Low

**Content**:
```markdown
### View Type Suffixes

**Standard Suffixes**:
- **View**: General SwiftUI view components
- **Row**: Items designed for List/ForEach contexts
- **Page**: Full-screen or near-full-screen views

**Examples**:
- `UserProfileView` - general component
- `UserProfileRow` - list item variant
- `DashboardPage` - full-screen view

**Preference**: Nearly always use a descriptive suffix.
```

---

### Framework 4: Boolean Property Naming
**Source**: C3
**User Decision**: "is prefix is ideal but has is also okay. Shows is not okay... a Boolean almost always has to have a verb as the first word"

**Section**: Naming Conventions
**Priority**: High
**Difficulty**: Low

**Content**:
```markdown
### Boolean Property Naming

**Preferred**: `is` prefix
```swift
@State private var isLoading = false
@State private var isEnabled = true
```

**Acceptable**: `has` prefix
```swift
@State private var hasError = false
@State private var hasData = false
```

**Avoid**: `shows`, `displays`, or action-oriented verbs
```swift
❌ @State private var showsDetail = false  // Sounds like action
✅ @State private var isDetailVisible = false  // State
```

**Rule**: Boolean must start with a verb indicating state, not action.
```

---

### Framework 5: Computed Property Naming
**Source**: C4
**User Decision**: "Option 1 is fine. Option 2 is never okay. Option 3 is good..."

**Section**: Naming Conventions
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### Computed Property Naming (Returning Views)

**Acceptable Patterns**:
1. **Noun form**: `private var header: some View`
2. **Descriptive**: `private var headerSection: some View`

**Avoid**:
- ❌ Verb form: `private var buildHeader: some View`

**Note**: If using descriptive names like "headerSection", prefer that the content actually uses that semantic structure (e.g., Section view for "section" suffix).

**Examples**:
```swift
✅ private var header: some View
✅ private var navigationBar: some View
✅ private var titleView: some View  // "view" suffix okay even if underlying is Text
❌ private var buildHeader: some View
❌ private var makeTitle: some View
```
```

---

### Framework 6: Action Handler Naming
**Source**: C8
**User Decision**: Complex two-part framework based on closure purpose

**Section**: Naming Conventions
**Priority**: High
**Difficulty**: Medium

**Content**:
```markdown
### Action Handler Naming

**Two Categories Based on Closure Purpose**:

#### Category 1: Direct Actions (`*Action` suffix)
Use when the closure **performs the action itself**.
```swift
// Button closure performs action
Button("Save", action: saveAction)
Button("Delete", action: deleteAction)

private func saveAction() {
    // Directly saves data
}
```

#### Category 2: Event Handlers (`on*` prefix)
Use when the closure **responds to something that already happened**.
```swift
// Sheet dismissal already happened, this responds
.sheet(isPresented: $showSheet) {
    ContentView()
} onDismiss: {
    onSheetDismissed()
}

// Task already failed, this handles it
.task {
    try await fetchData()
} onFailure: { error in
    onTaskFailed(error)
}
```

**Key Distinction**:
- `action: deleteAction` → closure IS the delete action
- `onDismiss: onSheetDismissed` → closure responds AFTER dismiss

**Avoid**:
- `handle*` prefix (ambiguous)
- `did*` prefix (past tense suggests callback, use `on*` instead)
- `*ed` suffix (passive voice)
```

---

### Framework 7: Constants Enum Organization
**Source**: C5, D5, D6
**User Decisions**: Prefer Constants, flat namespace, can split if big

**Section**: Code Organization
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### Constants Enum Organization

**Default Pattern**: Single flat `Constants` enum
```swift
enum Constants {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 8
    static let primaryColor = Color.blue
    static let title = "Welcome"
}
```

**When to Split**: If Constants enum becomes large (subjective)
```swift
enum Constants {
    static let padding: CGFloat = 16
}

enum Metrics {
    static let spacing: CGFloat = 8
}

enum Colors {
    static let primary = Color.blue
}
```

**Prefer**: Flat namespace over nested
```swift
✅ enum Constants {
    static let padding: CGFloat = 16
    static let cornerRadius: CGFloat = 8
}

❌ enum Constants {
    enum Spacing {
        static let padding: CGFloat = 16
    }
    enum Corners {
        static let radius: CGFloat = 8
    }
}
```

**Rationale**: Easy to add constants without restructuring.
```

---

### Framework 8: Common Value Extraction Threshold
**Source**: D3
**User Decision**: "Once it's twice, I'm definitely pretty interested in extracting it. But this needs to be weighed against how much we are really cleaning up."

**Section**: Refactoring Patterns
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### When to Extract Repeated Values

**General Guideline**: Balance repetition count with extraction benefit.

**Extract When**:
- Same value used 2+ times AND provides meaningful cleanup
- Single modifier used 3+ times
- Multiple modifiers (5+) used 2+ times

**Examples**:

**Worth Extracting** (5 modifiers × 2 uses = good cleanup):
```swift
// Before
Text("A").padding(8).font(.title).foregroundColor(.blue).bold().italic()
Text("B").padding(8).font(.title).foregroundColor(.blue).bold().italic()

// After
extension View {
    func styledText() -> some View {
        padding(8).font(.title).foregroundColor(.blue).bold().italic()
    }
}
```

**Maybe Not Worth Extracting** (1 modifier × 3 uses = minimal cleanup):
```swift
// Questionable value
Text("A").padding(8)
Text("B").padding(8)
Text("C").padding(8)
```

**Decision Framework**: Would extraction meaningfully reduce cognitive load?
```

---

### Framework 9: Complex Switch in Body
**Source**: B6
**User Decision**: "I wouldn't call this a complex switch statement in which case that would be fine. But if something really is a complex switch statement with complicated cases, then we want to move that to a computed property."

**Section**: View Body Patterns
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### Switch Statements in View Body

**Simple Switch**: Acceptable in body
```swift
var body: some View {
    switch mode {
    case .light: LightTheme()
    case .dark: DarkTheme()
    }
}
```

**Complex Switch**: Extract to computed property
```swift
// When cases are complex
var body: some View {
    modeView
}

private var modeView: some View {
    switch mode {
    case .light(let intensity):
        LightTheme(intensity: intensity)
            .customModifiers()
    case .dark(let theme):
        DarkTheme(theme: theme)
            .moreCustomModifiers()
    }
}
```

**Also Note**: Unnecessary container detection
```swift
❌ var body: some View {
    VStack {  // Pointless - switch only returns one view
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
```

---

### Framework 10: ViewBuilder Usage Guidelines
**Source**: B5
**User Decision**: "This is acceptable but not ideal. I think ViewBuilder is best used when there are two different possible types being returned."

**Section**: View Patterns
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### ViewBuilder Usage Guidelines

**Best Use**: Conditional type returns
```swift
@ViewBuilder
private var content: some View {
    if isLoading {
        ProgressView()  // Type 1
    } else {
        ContentView()   // Type 2
    }
}
```

**Acceptable but Not Ideal**: Multiple views of same structure
```swift
// Works but consider alternatives
@ViewBuilder
private var headerViews: some View {
    Text("Header 1")
    Text("Header 2")
    Text("Header 3")
}
```

**Better Alternative**: Use container or rethink structure
```swift
private var headerViews: some View {
    VStack {
        Text("Header 1")
        Text("Header 2")
        Text("Header 3")
    }
}
```

**Primary Purpose**: Type flexibility, not view grouping.
```

---

### Framework 11: Preview Organization
**Source**: F1
**User Decision**: "Very much option one unless the view is a page itself. In which case multiple previews"

**Section**: Preview Patterns
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### Preview Organization

**Components/Rows/Views**: Single comprehensive preview
```swift
#Preview("All States") {
    VStack {
        UserRowView(state: .loading)
        UserRowView(state: .loaded)
        UserRowView(state: .error)
    }
}
```

**Pages (Full-Screen Views)**: Multiple focused previews
```swift
#Preview("Loading State") {
    DashboardPage(state: .loading)
}

#Preview("Loaded State") {
    DashboardPage(state: .loaded)
}

#Preview("Error State") {
    DashboardPage(state: .error)
}
```

**Rationale**: Small components benefit from side-by-side comparison; full pages need individual focus.
```

---

### Framework 12: Preview Content Strategy
**Source**: F2
**User Decision**: "Slight preference for minimal even though I think in the long run we will be doing a lot of maximal things."

**Section**: Preview Patterns
**Priority**: Low
**Difficulty**: Low

**Content**:
```markdown
### Preview Content Strategy

**Current Preference**: Minimal data
```swift
#Preview {
    UserProfileView(title: "Test", items: [])
}
```

**Future Direction**: More realistic data (snapshot/UI testing)
```swift
#Preview {
    UserProfileView(
        title: "User Dashboard",
        items: ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
    )
}
```

**Guidance**: Start minimal, expand when testing specific layouts/behaviors.
```

---

### Framework 13: Manager/ViewModel/Controller Naming
**Source**: E6
**User Decision**: "ViewModel has a one-to-one relationship with a ViewType. I tend to use the word manager... controller sounds like UIKit world"

**Section**: Architecture Patterns
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### ObservableObject Naming Conventions

**ViewModel**: One-to-one relationship with specific View
```swift
struct UserProfileView: View {
    @StateObject private var viewModel = UserProfileViewModel()
}

class UserProfileViewModel: ObservableObject {
    // Specific to UserProfileView
}
```

**Manager**: Shared service, not tied to specific view
```swift
class DataManager: ObservableObject {
    // Shared across multiple views
}

class NetworkManager: ObservableObject {
    // Application-wide service
}
```

**Avoid**: "Controller" (UIKit terminology)
```

---

### Framework 14: Protocol Conformance Placement
**Source**: E7
**User Decision**: "I'm somewhat split on this... sometimes extension is most pure... but sometimes just seems like overkill. So this is kind of a 50/50 depends"

**Section**: Code Organization
**Priority**: Low
**Difficulty**: Low

**Content**:
```markdown
### Protocol Conformance Placement

**Context-Dependent**: Choose based on complexity and clarity.

**Inline** (simpler, direct):
```swift
struct UserProfile: View, Identifiable {
    let id = UUID()
    var body: some View { ... }
}
```

**Extension** (more organized, separates concerns):
```swift
struct UserProfile: View {
    var body: some View { ... }
}

extension UserProfile: Identifiable {
    var id: UUID { UUID() }
}
```

**Guideline**: Use extension when conformance adds significant implementation; inline for trivial cases.
```

---

### Framework 15: Nested Types Guidelines
**Source**: E8
**User Decision**: "Discouraged but sometimes makes sense. Especially if it is very tightly coupled to this type and isn't used anywhere else."

**Section**: Code Organization
**Priority**: Low
**Difficulty**: Low

**Content**:
```markdown
### Nested Types

**General Preference**: Avoid nesting types.

**Acceptable When**:
- Very tightly coupled to parent type
- Not used anywhere else
- Adds meaningful namespace/context

**Example**:
```swift
struct UserProfile: View {
    enum Mode {  // Only used by UserProfile
        case view, edit
    }

    @State private var mode: Mode = .view
    var body: some View { ... }
}
```

**Prefer Separate Files** when type might be reused or is substantial.
```

---

### Framework 16: File Naming Convention
**Source**: E9
**User Decision**: "Matches type name absolutely."

**Section**: Code Organization
**Priority**: High
**Difficulty**: Low

**Content**:
```markdown
### File Naming Convention

**Rule**: File name must match primary type name exactly.

**Examples**:
- `UserProfileView.swift` contains `struct UserProfileView`
- `DataManager.swift` contains `class DataManager`

**Not**:
- ❌ `UserProfileScreen.swift` for `struct UserProfileView`
- ❌ `user-profile.swift` for `struct UserProfileView`

**Note**: Extensions have different rules (needs clarification).
```

---

### Framework 17: Preview Naming Convention
**Source**: C10
**User Decision**: "If there's just one preview, I really don't care... prefer descriptive names if we are going to name the preview, but probably don't use a name at all if there is only one preview"

**Section**: Preview Patterns
**Priority**: Low
**Difficulty**: Low

**Content**:
```markdown
### Preview Naming

**Single Preview**: Omit name
```swift
#Preview {
    UserProfileView()
}
```

**Multiple Previews**: Use descriptive names
```swift
#Preview("Loading State") {
    DashboardPage(state: .loading)
}

#Preview("Loaded State") {
    DashboardPage(state: .loaded)
}
```

**Avoid**: Using type name as preview name
```swift
❌ #Preview("UserProfileView") {
    UserProfileView()
}
```
```

---

### Framework 18: String Constants Extraction
**Source**: D7
**User Decision**: "Pretty much want to extract it into a constants enum"

**Section**: Constants Patterns
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### String Constants

**General Rule**: Extract strings to Constants enum.

```swift
enum Constants {
    static let title = "Hello World"
    static let subtitle = "Welcome"
}

var body: some View {
    VStack {
        Text(Constants.title)
        Text(Constants.subtitle)
    }
}
```

**Rationale**: Consistency, localization preparation, typo prevention.
```

---

### Framework 19: New View Extraction Threshold
**Source**: E2
**User Decision**: "Creating a new view file has its own bit of overhead so it really needs to provide some level of simplification."

**Section**: Refactoring Patterns
**Priority**: Medium
**Difficulty**: Medium

**Content**:
```markdown
### When to Extract to New View File

**Consider Extracting When**:
- View is reused in multiple places
- View is complex enough to benefit from isolation
- Extraction provides meaningful simplification
- View represents a distinct conceptual component

**Don't Extract When**:
- Used only once
- Very simple (5-10 lines)
- Creates more overhead than benefit

**Decision Process**:
1. Is it reused? → Extract
2. Is it complex AND self-contained? → Extract
3. Would extraction improve clarity? → Extract
4. Otherwise → Keep as computed property

**Note**: "Complex" is subjective - use judgment based on cognitive load reduction.
```

---

### Framework 20: Binding Property Naming
**Source**: C9
**User Decision**: Long explanation about avoiding type names in variable names

**Section**: Naming Conventions
**Priority**: Medium
**Difficulty**: Low

**Content**:
```markdown
### Binding Property Naming

**General Rule**: Don't put type/wrapper names in variable names.

**Avoid**:
```swift
❌ @Binding var isPresentedBinding: Bool  // Redundant "Binding"
```

**Prefer**:
```swift
✅ @Binding var isPresented: Bool  // Type name omitted
✅ @Binding var presented: Bool     // Shortened acceptable
```

**Exception**: When you must keep both the source and wrapped version
```swift
@State private var isPresented = false
@Binding var isPresentedBinding: Bool  // Disambiguates from @State version
```

**Note on "View" Suffix**: Different reasoning - "View" describes content type (Button, Page, Row), not that it conforms to View protocol.
```

---

## CLAUDE-SWIFT.md Updates (Critical Reminders)

### 1. EmptyView Anti-Pattern
**Source**: B9
**User Decision**: "If you do this, I will throw my laptop out the window"
**Confidence**: Very Strong

**Section**: SwiftUI Body
**Priority**: High
**Difficulty**: Low

**Content**:
```markdown
### NEVER Use EmptyView Placeholder

**Forbidden Pattern**:
```swift
❌ struct PlaceholderView: View {
    var body: some View {
        EmptyView()
    }
}
```

**Why**: Creating a View type just to return EmptyView serves no purpose and adds pointless boilerplate.

**If you need a placeholder**: Use conditional rendering or remove the view entirely.
```

---

### 2. ViewModel Property Naming Standard
**Source**: C2
**User Decision**: "Let's go with viewModel I guess"
**Confidence**: Moderate (picked for consistency)

**Section**: Naming Conventions
**Priority**: Low
**Difficulty**: Low

**Content**:
```markdown
### ViewModel Property Naming

**Standard**: Use `viewModel` for consistency.

```swift
@StateObject private var viewModel = MyViewModel()
```

**Avoid**: `model`, `vm` (ambiguous or too abbreviated)
```

---

## Already Covered (No Changes Needed)

1. **A1**: Standard property wrapper order - SwiftFormat handles this
2. **B2**: 16-line body rejection - `skimmable_body` rule exists
3. **B4**: Wrapper pattern rejection - `no_wrapper_body` rule exists
4. **B7**: Single-line modifier chains - SwiftFormat handles
5. **D1**: Constants at top - `view_structure_order` rule
6. **D2**: Magic number detection - Existing lint rule + hint
7. **D7**: String constant extraction - Covered by existing guidance
8. **E1**: Wrapper pattern (option 2) - Duplicate of B4
9. **E3**: One type per file - Existing SwiftLint rule
10. **E10**: Init before body - `view_structure_order` rule
11. **F5**: Preview for ViewModifier - `preview_required` rule exists
12. **C7**: File-level constants - One declaration per file rule covers

---

## No Action Needed (Clarifications/Non-Rules)

1. **A3**: Not a real example (View already @MainActor)
2. **A6**: Grouped properties - preference clear, no enforcement needed
3. **A7**: Declaration order over alphabetical - anti-rule (don't alphabetize)
4. **B1**: 15 lines exactly acceptable - within existing rule
5. **B8**: "Line is a line" - clarification, no special handling
6. **E4**: Extension usage - needs better example
7. **F4**: Preview at end of file - obvious, no enforcement needed
8. **F6**: Preview in separate file context - rare edge case
9. **A1**: "You should already know" - existing coverage confirmed

---

## Deferred (Need Clarification/More Examples)

### ✅ Resolved (See clarifications_resolved.md)
1. **A5**: Property wrapper line break categories - ✅ IMPLEMENTED in apple-platform-dev skill (2025-11-16)
2. **B6**: Pointless container anti-pattern - ✅ IMPLEMENTED in apple-platform-dev skill (2025-11-15)
3. **E2**: View extraction decision matrix - ✅ IMPLEMENTED in apple-platform-dev skill (2025-11-15)
4. **F3**: Preview dependencies strategy - Partially documented (user still developing opinion)
5. **E4**: Extension usage guidelines - ✅ IMPLEMENTED in apple-platform-dev skill (2025-11-15)
6. **E9**: Extension file naming conventions - ✅ IMPLEMENTED in apple-platform-dev skill (2025-11-15)

---

## Implementation Status Updates

### 2025-11-16: A5 Property Wrapper Line Breaks

**apple-platform-dev skill** updated with property wrapper formatting framework:

**A5 - Property Wrapper Line Break Formatting**
- Location: New section "Property Wrapper Line Break Formatting" after View Structure Order
- Covers: Inline vs preceding line categorization for all property wrappers/attributes
- Categories:
  - **Inline**: State/data wrappers (@State, @Binding, @Environment, etc.), type signatures (@Sendable)
  - **Preceding Line**: Type system (@available, @objc), testing (@Test, @Suite), storage (@AppStorage, @SceneStorage), complex/long (@FetchRequest)
- Blank line rule: Preceding-line wrappers need blank line above (except first line in type)
- Rationale: Length matters - @Environment (short keypaths) vs @AppStorage (string keys + types + defaults)

**Key Insight**: Original hypothesis "state vs type system" was correct but refined with **length/complexity override** - long wrappers move to preceding line regardless of semantic category.

**User Preferences Captured**:
- property_wrapper_examples.md: 20+ wrappers reviewed with rationale
- Refinements: @Environment inline, @AppStorage/@SceneStorage preceding (length-based)
- @MainActor context-dependent: preceding on declarations, inline on properties

**Enforcement**: Manual via code review (SwiftFormat doesn't support this pattern yet)

### 2025-11-15: B6, E2, E4, E9 Frameworks

**apple-platform-dev skill** updated with 4 new frameworks:

1. **B6 - Pointless Container Anti-Pattern** (High Priority)
   - Location: Strategy #4 "Avoid Pointless Containers"
   - Covers: Switch statements, if/else, single-branch conditionals, Group usage
   - Addresses: Unnecessary VStack/HStack wrappers around single-view returns

2. **E2 - View Extraction Decision Matrix** (High Priority)
   - Location: Strategy #3 "Component Extraction"
   - Covers: When to use computed properties vs extracted views
   - Decision factors: Reuse, file complexity, dependency separation, parameter overhead

3. **E4 - Extension Usage Guidelines** (Medium Priority)
   - Location: New "File Organization & Extension Patterns" section
   - Covers: Protocol conformance, private methods, computed properties, type extensions
   - Guidance: When to keep inline vs separate, MARK comments

4. **E9 - Extension File Naming** (Medium Priority)
   - Location: New "File Organization & Extension Patterns" section
   - Covers: Naming patterns (Type+Feature.swift), directory organization, splitting strategy
   - Guidance: Same file vs separate, widely used vs local

**Files Modified**:
- `/Users/bryancostanza/.claude/skills/apple-platform-dev/SKILL.md`

**Documentation**:
- `clarifications_resolved.md` - Full frameworks with user responses
- `property_wrapper_examples.md` - Pending user completion (A5)

---

## Implementation Priority Ranking

### High Priority (Implement Soon)
1. **ViewModifier body line limit** (SwiftSyntax) - Consistency with View
2. **Type inference framework** (Skill) - Frequently applicable
3. **Action handler naming** (Skill) - Complex but frequently used
4. **Boolean naming** (Skill) - Very common pattern
5. **View suffix conventions** (Skill) - Fundamental naming
6. **EmptyView anti-pattern** (CLAUDE-SWIFT) - Strong user reaction

### Medium Priority (Next Phase)
7. **Constants organization** (Skill) - Common pattern
8. **Common value extraction** (Skill) - Refactoring guidance
9. **Computed property naming** (Skill) - Frequent usage
10. **Manager/ViewModel naming** (Skill) - Architecture clarity
11. **Preview organization** (Skill) - Testing workflow
12. **New view extraction threshold** (Skill) - Needs refinement
13. **Property wrapper line breaks** (Skill) - Needs research first

### Low Priority (As Needed)
14. **No leading underscores** (SwiftLint) - Rare issue
15. **Calculated constants** (SwiftSyntax) - Niche case
16. **Protocol conformance placement** (Skill) - Context-dependent
17. **Nested types guidelines** (Skill) - Edge case
18. **Preview content strategy** (Skill) - Future evolution
19. **Preview naming** (Skill) - Minor detail
20. **Binding naming** (Skill) - Edge case

---

## Next Steps

1. **Implement High-Priority SwiftSyntax Rule**: ViewModifier body line limit
2. **Draft Skill Updates**: Start with type inference, action naming, boolean naming
3. **Add CLAUDE-SWIFT Reminders**: EmptyView anti-pattern, viewModel naming
4. **Create Clarification Questions**: For deferred items (A5, F3, E4, etc.)
5. **Test New Rules**: On gravity-well project
6. **Update Documentation**: Ensure consistency across all guidance sources

---

## Research Needed

1. **Property Wrapper Categories**: Identify which wrappers should have preceding line breaks
2. **Extension File Naming**: Understand conventions for extension files vs primary type files
3. **Mock vs Real Dependencies**: Create compelling examples for preview dependency patterns
