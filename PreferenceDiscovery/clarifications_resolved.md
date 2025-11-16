# Clarifications Resolved - Phase 4 Alpha Addendum

**Date**: 2025-11-15
**Source**: clarification_needed.md (User responses)
**Status**: 5 of 6 items clarified, 1 pending property wrapper examples

---

## B6: Pointless Container Anti-Pattern ✅ RESOLVED

### User Responses

**Scenario 1** (Switch): Green checkmark example is ideal - no VStack wrapper

**Scenario 2** (If/Else): Green checkmark preferred - no VStack wrapper

**Scenario 3** (Optional unwrapping):
> "When there is an if without an else, then really it is just one conditional view. In cases like that we should almost always hoist the if one level higher because we want to know about the visibility as soon as it's relevant and not open up a sub-view to find out that it might make itself invisible"

**Scenario 4** (With modifiers):
> "In this case you have made the VStack have purpose but it doesn't have any purpose that isn't also served by a Group so we should use a Group. We do have a lint rule that says no top-level Group but that does not apply if there are 1+ modifiers applied to the Group"

### Classification

**Implementation**: Skill update (already have `no_group_body` rule)
**Priority**: High (adds important nuance to existing guidance)
**Confidence**: Strong

### Skill Framework: Pointless Container Anti-Pattern

```markdown
### Avoiding Pointless Containers

**Anti-Pattern**: Wrapping conditionals that only return one view at a time.

**Why**: Adds unnecessary nesting without structural purpose.

#### Switch Statements

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

#### If/Else Statements

```swift
❌ var body: some View {
    VStack {  // Pointless - if/else only ever returns ONE view
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

#### Single-Branch Conditionals (if without else)

**Critical**: Hoist to visibility level

```swift
❌ var body: some View {
    VStack {
        header
        if let data = viewModel.data {
            DataView(data: data)
        }
        footer
    }
}

✅ var body: some View {
    VStack {
        header
        // BETTER: Conditional at higher level shows visibility immediately
    }
    if let data = viewModel.data {
        DataView(data: data)
    }
}

// OR: Keep in VStack if it's structural
✅ var body: some View {
    VStack {
        header
        if let data = viewModel.data {
            DataView(data: data)
        } // This is fine if data view is part of VStack structure
        footer
    }
}
```

**Rule**: If conditional controls visibility of entire view, hoist it to where visibility decision is relevant.

#### Containers with Modifiers

**If you need modifiers**: Use Group, not VStack

```swift
❌ var body: some View {
    VStack {  // VStack has no structural purpose here
        switch mode {
        case .light: Text("Light")
        case .dark: Text("Dark")
        }
    }
    .padding()  // Just for modifiers
}

✅ var body: some View {
    Group {  // Group is appropriate for modifier application
        switch mode {
        case .light: Text("Light")
        case .dark: Text("Dark")
        }
    }
    .padding()
}
```

**Note**: The `no_group_body` rule allows Group as top-level when it has modifiers.

**Summary**:
- Switch/If-Else returning single view → No container
- Need modifiers → Use Group
- Single-branch if controlling visibility → Consider hoisting
```

---

## E2: View Extraction Decision Framework ✅ RESOLVED

### User Responses

**Example 1** (Simple, once):
> "In this case yes I think that the computed property is a little bit better because it means that each view within the VStack in the body has similar importance in determining the structure of the view"

**Example 2** (Complex, once):
> "In this case the computed property is getting on the long side so it would at least make sense to try to pull out at least one subview from this computed property. And as long as the overall file size wasn't getting too big then that would be fine. But if the file is getting big then this would be a pretty good one to pull out and certainly if it were used twice then it would get pulled out. Or maybe another way to think about it is that it depends on how complex the rest of the file is. If this were the only computed property and we could just pull out one more computed property then that's great. But if there are possibilities of separating out dependencies or reducing arguments to one vs. the other then that starts pushing us toward separating to a brand new view"

**Example 3** (Simple, twice in same file):
> "I think the example you have here is ideal"

**Example 4** (Used in multiple files):
> "Yes this becomes its own new view Unless we expect that these styles are going to differ or just happen to be the same right now and we might also I want to consider as one last thing whether making this a new view will be as complicated as just using it in-place. Because for example I can see that with these status indicators if we had to provide a boolean, two colors, a width, and a height, then the function signature on that is more out of control than just duplicating this work. Again unless it is just critical that they match each other exactly But then I guess if they necessarily have to match each other exactly, then a lot of these values can be stored properties in the new view and then the function signature is really not all that big at all"

### Classification

**Implementation**: Skill update
**Priority**: High (frequently needed decision)
**Confidence**: Moderate (context-dependent)

### Skill Framework: View Extraction Decision Matrix

```markdown
### When to Extract to New View File

**No Single Rule**: Decision depends on multiple factors.

#### Decision Factors

**1. Reuse**:
- Once in same file → Computed property (default)
- Twice in same file → Computed property (still manageable)
- Across multiple files → Extract (usually)

**2. File Complexity**:
- Simple file (few computed properties) → Keep as computed property
- Complex file (many computed properties) → Consider extracting

**3. Dependency Separation**:
- Can reduce arguments/dependencies → Extract
- Simple, self-contained → Keep as computed property

**4. Parameter Overhead**:
- Few parameters (1-2) → Extract acceptable
- Many parameters (5+) → Reconsider, might be better duplicated
- Can use stored properties in new view → Extract becomes viable

#### Examples

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

**Reason**: Maintains visible structure in body, file not complex.

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

**When to Extract Complex**: If file is already large OR has many computed properties.

**Simple + Used Twice in Same File → Computed Property**
```swift
struct ProfilePage: View {
    var body: some View {
        VStack {
            userBadge  // DRY within file
            content
            userBadge
        }
    }

    private var userBadge: some View {
        HStack {
            Image(systemName: "person.circle")
            Text(userName)
        }
    }
}
```

**Reason**: Keeps related code together, no cross-file dependencies.

**Used Across Files → Extract (with caveats)**
```swift
// If simple with many parameters:
StatusIndicator(
    isOnline: isOnline,
    onlineColor: .green,
    offlineColor: .gray,
    size: 12
)
// Might be better duplicated - parameter overhead too high

// If can use stored properties:
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
// Now signature is simple: StatusIndicator(isOnline: true)
```

#### Decision Process

1. **Used once?** → Probably computed property
2. **Used across files?** → Probably extract
3. **File getting large?** → Consider extracting
4. **Can reduce dependencies?** → Lean toward extracting
5. **Would extraction create parameter hell?** → Maybe keep duplicated
6. **Can use stored properties to reduce parameters?** → Extract becomes better

**Remember**: Extraction has overhead. Justify it with reuse, clarity, or dependency separation.
```

---

## F3: Preview Dependencies Strategy ✅ PARTIALLY RESOLVED

### User Responses

**Scenario 1** (Simple Settings):
> "I think the preference is going to be to use the real settings type, and then we would just switch to mock if something about the setup actually ends up being pretty complicated or if some behavior within the real type has side effects that we need to prevent or control in some other way. But if there is something we need to control like user defaults or some time provider or something like that, then maybe we switch to a mock at that point."

> "Oh and here's one thing I'm remembering from way back: I actually think very much that if we do have a mock, it should probably be an extension on the original type as a static member. It might make sense to make mockable a protocol but that's something we can discuss or wait on. If that's a great idea and commonly done then let's just make that the norm now. As I think more about the mock-equal protocol, I think we run into issues because it would be easy if we could just say there has to be a computed property called mock, but what if there is a reason to have multiple different mocks or a function that creates mocks?"

**Scenario 2** (Network):
> "Show me more about what a mock stub protocol looks like. I have not done a lot of networking stuff, so I don't have a well-developed opinion here"

**Scenario 3** (Core Data/SwiftData):
> "We should be using SwiftData Instead of core data and you could look at my Point1K repo for examples of how I've utilized it in the past. I think it is a good reference for this question in the SwiftData sense"

**Scenario 4** (Authentication):
> "Oh I don't know, I haven't dealt much with this kind of stuff"

**General**:
> "Again I guess I just don't have a strong enough opinion yet except for where I might already have an example like with SwiftData"

### Classification

**Implementation**: Skill update (partial)
**Priority**: Medium
**Confidence**: Moderate (user still developing opinion)

### Skill Framework: Preview Dependencies (Partial)

```markdown
### Preview Dependencies Strategy

**General Principle**: Prefer real objects, use mocks when necessary.

#### When to Use Real Objects

- Simple initialization
- No complex side effects
- No external dependencies (network, files, etc.)

```swift
#Preview {
    ThemeToggleView()
        .environmentObject(Settings())  // Real object
}
```

#### When to Switch to Mocks

**Triggers**:
- Complex initialization
- Side effects need control (UserDefaults, time, network)
- Setup becomes too complicated

**Mock Pattern**: Static member extension on original type

```swift
extension Settings {
    static var preview: Settings {
        let settings = Settings()
        settings.isDarkMode = true
        return settings
    }

    static func previewWith(darkMode: Bool) -> Settings {
        let settings = Settings()
        settings.isDarkMode = darkMode
        return settings
    }
}

#Preview("Dark Mode") {
    ThemeToggleView()
        .environmentObject(.preview)
}
```

**Benefits**:
- Keeps mocks close to type
- Easy to discover
- Can have multiple factory methods
- No separate mock class needed

**Protocol-Based Mocks**: Deferred for future discussion.

#### SwiftData Previews

**Reference**: See Point1K repository for established patterns.

(TODO: Document SwiftData preview patterns after reviewing Point1K)

#### Network/Authentication Previews

**Status**: User developing opinion - revisit after more experience.

**Interim Approach**: Follow general principle (real when simple, mock when complex) and static member extension pattern.
```

**Follow-Up Needed**:
1. Review Point1K repo for SwiftData patterns
2. Develop network mock examples when needed
3. Develop authentication mock examples when needed

---

## E4: Extension Usage Guidelines ✅ RESOLVED

### User Responses

**Scenario 1** (Protocol conformance):
> "Even though I think sometimes it's okay to do it in-line, I guess we should just set the standard as having them all separated As you show in option B"

**Scenario 2** (Private methods):
> "I've seen some compelling cases for B but I'd like to stick with A until I have some exotic streak or wild hair"

**Scenario 3** (MARK vs extensions):
> "I think these are possibly separate. I think marks are good but not required and extensions can be helpful but don't need to be a first tool to reach for"

**Scenario 4** (Computed view properties):
> "In-line Option A"

**Scenario 5** (Type-specific extensions):
> "If it's a private extension and specialized then keep it as a private extension in the file. But if it's generic even if it is only used once, then make it its own extension file. I like having those things easily discoverable and I also think that it will help find things that are easily extractable into a tools framework or any other framework that I am running"

### Classification

**Implementation**: Skill update
**Priority**: Medium
**Confidence**: Strong

### Skill Framework: Extension Usage Guidelines

```markdown
### When to Use Extensions

**Protocol Conformance**: Always use extensions (standard)

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

extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name
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

**Exception**: Wait for "exotic streak" - defer to future.

**Computed View Properties**: Keep inline

```swift
struct ProfileView: View {
    var body: some View {
        VStack {
            headerSection  // Inline
            detailsSection
        }
    }

    private var headerSection: some View { ... }
    private var detailsSection: some View { ... }
}
```

**MARK Comments**: Separate concern from extensions

- MARK: Good but not required
- Extensions: Helpful but not first tool
- Can use both, neither, or one without the other

**Type Extensions (Foundation/SwiftUI)**:

**Private + Specialized → Keep in file**
```swift
// MessageView.swift
struct MessageView: View {
    var body: some View {
        Text(message.formatted)
    }
}

private extension String {
    var formatted: String {
        // Message-specific formatting
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

**Generic (even if used once) → Separate file**
```swift
// String+Formatting.swift
extension String {
    var trimmed: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
```

**Rationale**: Discoverability, extractability to tools framework.
```

---

## E9: Extension File Naming ✅ RESOLVED

### User Responses

**Scenario 1** (Protocol conformance):
> "Yes I think in general, if it's small, keep it in the same file. But in that case it also needs to be a somewhat expected extension. In the example you gave it seems pretty unique that we'd be adding codable to a view, so that might make sense to put in a separate extension. That also highlights the point that I think if the extension is to satisfy what I would call a 'distant' requirement, then it also makes sense in a sewparate extension there"
> "Basically yes" (separate for substantial)
> "I definitely prefer the Plus" (naming)
> "There can be a subdirectory from the root of the project For the widely used extensions But if it's a 'local extension,' then it can be in the same directory"

**Scenario 2** (Type extensions):
> "Option A is the default when there are a few extensions. But kind of like with our rule for enum Constants, everything should go in the enum Constants until that enum gets big and then it can make sense to make more focused constant enums by different names"

**Scenario 3** (View-specific):
> "I feel we've covered this in other questions. What makes this different? Unless I'm missing something, yes this is acceptable But also maybe why not just put that within the view struct in the first place instead of an extension?"

**Scenario 4** (Multiple extensions):
> "This is acceptable as long as it's not something like we have three extension files for three individual extensions that are each actually very small That would be annoying"

**Scenario 5** (Organization):
> "Option A is the first option but if there gets to be a lot of them then we will use option B. Of course this is subjective but maybe starting around 4 extensions it would start to be a consideration to make a new directory And then I think certainly at 6 to 8 we're going to need to move to extensions directory"

**Framework questions**:
> "I think I answered all of these inline? Did I miss anything?"

### Classification

**Implementation**: Skill update
**Priority**: Medium
**Confidence**: Strong

### Skill Framework: Extension File Naming

```markdown
### Extension File Naming Conventions

**Naming Pattern**: `TypeName+Feature.swift` (not `.Feature` or `TypeNameFeature`)

#### Same File vs Separate File

**Keep in Same File When**:
- Extension is small
- Extension is "expected" (common protocol)
- Not a "distant requirement"

**Separate File When**:
- Substantial protocol conformance
- "Distant requirement" (unusual for that type)
- Example: Adding Codable to View type (unusual)

```swift
// UserProfile.swift - small, expected
struct UserProfile: View {
    var body: some View { ... }
}

extension UserProfile: Identifiable {
    // Small, automatic - keep here
}

// UserProfile+Codable.swift - unusual for View
extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}
```

#### Naming Convention

**Default**: `Type+Extensions.swift` (like `enum Constants`)

**When Extensions Grow**: Split by feature (like splitting Constants)

```swift
// Start with:
String+Extensions.swift

// When it grows:
String+Validation.swift
String+Formatting.swift
String+Parsing.swift
```

**Avoid**: Many tiny extension files (3 files with 3 tiny extensions each)

#### Directory Organization

**Location Strategy**:

**Start**: Next to the type (Option A)
```
Models/
├── User.swift
├── User+Codable.swift
└── User+Validation.swift
```

**When Many** (4+ = consider, 6-8 = definitely):
```
Extensions/  // Centralized
├── User+Codable.swift
├── User+Validation.swift
├── Date+Formatting.swift
└── String+Validation.swift
```

**Widely Used vs Local**:
- **Widely used** (cross-project): `Extensions/` subdirectory
- **Local** (project-specific): Same directory as type

#### Type Extensions (Foundation/SwiftUI)

**Private + Specialized**: Keep in file with view
```swift
// MessageView.swift
private extension String {
    var formatted: String { ... }
}
```

**Generic (even if used once)**: Separate extension file
```swift
// String+Formatting.swift
extension String {
    var trimmed: String { ... }
}
```

**Rationale**: Discoverability for extraction to tools framework.

#### Summary

1. **Naming**: `Type+Feature.swift`
2. **Location**: Start next to type, move to Extensions/ at 4-6 extensions
3. **Splitting**: Like Constants - start combined, split when grows
4. **Generic extensions**: Always separate file for discoverability
5. **Private extensions**: Keep with using file if specialized
```

---

## A5: Property Wrapper Line Breaks ⏸️ PENDING

**Status**: Created `property_wrapper_examples.md` for user review

**Action Required**: User to review all wrapper examples and mark preferences

**Next Steps**:
1. User completes property_wrapper_examples.md
2. Extract pattern/rule from preferences
3. Update Skill or create lint rule if mechanically enforceable

---

## Summary of Clarifications

### Resolved (5)
1. ✅ **B6**: Pointless container anti-pattern → Skill update (high priority)
2. ✅ **E2**: View extraction decision matrix → Skill update (high priority)
3. ✅ **F3**: Preview dependencies → Skill update (partial, user developing opinion)
4. ✅ **E4**: Extension usage → Skill update (medium priority)
5. ✅ **E9**: Extension file naming → Skill update (medium priority)

### Pending (1)
6. ⏸️ **A5**: Property wrapper line breaks → Awaiting user completion of examples

### Follow-Up Research Needed
- Review Point1K repo for SwiftData preview patterns
- Develop network mock protocol examples (when user needs them)
- Develop authentication mock examples (when user needs them)

---

## Implementation Priority (Updated)

### Immediate (High Priority)
1. **B6 Framework** - Pointless container anti-pattern (strong preference, frequent issue)
2. **E2 Framework** - View extraction decision matrix (frequent decision point)
3. **E4 Framework** - Extension usage guidelines (clear standard established)
4. **E9 Framework** - Extension file naming (clear standard established)

### Short-Term (Medium Priority)
5. **F3 Framework** - Preview dependencies (partial, document established patterns)
6. **A5 Framework** - Property wrapper line breaks (pending user examples)

### Research Tasks
- Extract SwiftData patterns from Point1K
- Create network mock protocol examples (future)
- Create authentication mock examples (future)
