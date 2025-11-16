# Preference Discovery - Clarification Questions

**Purpose**: Follow-up questions for preferences that need more context, examples, or research.

**Status**: 6 items deferred from initial preference discovery session

---

## A5: Property Wrapper Line Break Categories

### Your Original Response
"I feel like there's generally two kinds of categories of wrappers... MainActor belongs to a group that should be the line above the thing that it is modifying, while State is absolutely something that should be used in line"

### What We Need
Categorize ALL common property wrappers into these two groups.

### Category 1: Inline (Same Line as Declaration)
**Currently Identified**:
- `@State`
- `@Binding`
- `@Environment`
- `@EnvironmentObject`
- `@StateObject`
- `@ObservedObject`
- `@Published`

**Questions**:
1. What about `@AppStorage`?
2. What about `@SceneStorage`?
3. What about `@FetchRequest`?
4. What about `@SectionedFetchRequest`?
5. What about `@Namespace`?
6. What about `@GestureState`?
7. What about `@FocusState`?
8. What about `@AccessibilityFocusState`?

### Category 2: Preceding Line (Line Above Declaration)
**Currently Identified**:
- `@MainActor`

**Questions**:
1. What about `@available`?
2. What about `@objc`?
3. What about `@IBOutlet` / `@IBAction` (if you ever use UIKit)?
4. What about `@escaping` (function parameters)?
5. What about `@autoclosure`?
6. What about `@Sendable`?
7. What about `@unchecked`?

### Hypothesis to Test
**Category 1 (Inline)**: Property wrappers that manage state/data
**Category 2 (Preceding Line)**: Attributes that affect type system (concurrency, availability, compiler directives)

**Is this distinction correct?** If not, what's the actual rule?

I think that is a pretty decent beginning hypothesis but why don't you make me another doc here that shows every single one with both options And use realistic parameters where they apply 

---

## B6: VStack with Single-View Switch

### Your Original Response
"I wouldn't call this a complex switch statement in which case that would be fine. But if something really is a complex switch statement with complicated cases, then we want to move that to a computed property. I'll also say that this VStack is wrong because there is only ever going to be one view and the stack has no purpose"

### What We Need
Clarify the "pointless VStack" anti-pattern rule.

### Scenario 1: Switch Returns Single View
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

**Question**: Is this the anti-pattern you were calling out?

Your green check mark example here is ideal 

### Scenario 2: Conditional Returns Single View
```swift
❌ var body: some View {
    VStack {  // Pointless?
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

**Question**: Same rule applies to if/else?

Your green check mark option is the one I prefer here 

### Scenario 3: Optional View
```swift
❌ var body: some View {
    VStack {  // Pointless?
        if let data = viewModel.data {
            DataView(data: data)
        }
    }
}

✅ var body: some View {
    if let data = viewModel.data {
        DataView(data: data)
    }
}
```

**Question**: Same rule for optional unwrapping?

When there is an if without an else, then really it is just one conditional view. In cases like that we should almost always hoist the if one level higher because we want to know about the visibility as soon as it's relevant and not open up a sub-view to find out that it might make itself invisible 

### Scenario 4: What About Modifiers?
```swift
var body: some View {
    VStack {
        switch mode {
        case .light: Text("Light")
        case .dark: Text("Dark")
        }
    }
    .padding()  // NOW the VStack has purpose?
}
```

**Question**: If the VStack has modifiers, is it acceptable? Or should modifiers go on the switch itself?

### Proposed Rule
**Anti-Pattern**: Using a container (VStack/HStack/ZStack/Group) that only ever contains exactly one view.

**Is this the complete rule?**

In this case you have made the VStack have purpose but it doesn't have any purpose that isn't also served by a Group so we should use a Group. We do have a lint rule that says no top-level Group but that does not apply if there are 1+ modifiers applied to the Group 

---

## E2: When to Create New View Type vs Computed Property

### Your Original Response
"Creating a new view file has its own bit of overhead so it really needs to provide some level of simplification. And in the example you've given this is already extremely simple so we should not be putting it into a new view."

### What We Need
Concrete guidelines for the extraction decision.

### Example 1: Simple but Used Once
```swift
struct DashboardPage: View {
    var body: some View {
        VStack {
            header
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

**Scenario**: 3-line header, used once, very simple.

**Questions**:
1. Keep as computed property? ✓ In this case yes I think that the computed property is a little bit better because it means that each view within the VStack in the body has similar importance in determining the structure of the view 
2. Or extract to HeaderView file? ✗
3. Line count threshold for extraction?

### Example 2: Complex but Used Once
```swift
private var statisticsSection: some View {
    VStack(spacing: 12) {
        ForEach(statistics) { stat in
            HStack {
                VStack(alignment: .leading) {
                    Text(stat.title)
                        .font(.headline)
                    Text(stat.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(stat.value)
                    .font(.title)
                    .bold()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
```

**Scenario**: 20+ lines, used once, moderately complex.

**Questions**:

1. Keep as computed property? (Still within parent body limit)
2. Extract to StatisticsSectionView? (More isolated but overhead)
3. What tips the balance?

In this case the computed property is getting on the long side so it would at least make sense to try to pull out at least one subview from this computed property. And as long as the overall file size wasn't getting too big then that would be fine. But if the file is getting big then this would be a pretty good one to pull out and certainly if it were used twice then it would get pulled out. Or maybe another way to think about it is that it depends on how complex the rest of the file is. If this were the only computed property and we could just pull out one more computed property then that's great. But if there are possibilities of separating out dependencies or reducing arguments to one vs. the other then that starts pushing us toward separating to a brand new view 

### Example 3: Simple but Used Twice
```swift
struct ProfilePage: View {
    var body: some View {
        VStack {
            userBadge  // Used here
            content
            userBadge  // And here
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

**Scenario**: 3 lines, used twice in same file.

**Questions**:
1. Keep as computed property? (DRY within file)I think the example you have here is ideal 
2. Extract to UserBadgeView? (Reusable across files)
3. Does "used twice in same file" differ from "used in two different files"?

### Example 4: Used in Multiple Files
```swift
// UserProfilePage.swift
private var statusIndicator: some View {
    Circle()
        .fill(isOnline ? Color.green : Color.gray)
        .frame(width: 12, height: 12)
}

// DashboardPage.swift
private var statusIndicator: some View {
    Circle()
        .fill(isOnline ? Color.green : Color.gray)
        .frame(width: 12, height: 12)
}
```

**Scenario**: Duplicated computed property across files.

**Questions**:
1. This MUST be extracted to StatusIndicatorView, right? Yes this becomes its own new view Unless we expect that these styles are going to differ or just happen to be the same right now and we might also I want to consider as one last thing whether making this a new view will be as complicated as just using it in-place. Because for example I can see that with these status indicators if we had to provide a boolean, two colors, a width, and a height, then the function signature on that is more out of control than just duplicating this work. Again unless it is just critical that they match each other exactly But then I guess if they necessarily have to match each other exactly, then a lot of these values can be stored properties in the new view and then the function signature is really not all that big at all 
2. Even though it's only 2-3 lines?

### Decision Framework Questions

**Reuse Threshold**:
- Used once in same file → Computed property?
- Used 2+ times in same file → ?
- Used in 2+ different files → Extract to new View?

**Complexity Threshold**:
- Simple (< 5 lines) → ?
- Medium (5-15 lines) → ?
- Complex (15+ lines) → ?

**Combined Rules**:
- Simple + Once → Definitely computed property
- Simple + Multiple files → Extract?
- Complex + Once → ???
- Complex + Multiple files → Definitely extract

**What's the decision matrix?**

---

## F3: Preview with Dependencies - Mock or Real?

### Your Original Response
"Oh crap, yeah I don't know. I get really annoyed with mock objects at work but I also know that using the real objects can be really annoying too. I guess I'm not sure here. Maybe you could generate some more examples"

### What We Need
Examples of different scenarios to help you decide.

### Scenario 1: Simple Dependency (Settings)
```swift
struct ThemeToggleView: View {
    @EnvironmentObject var settings: Settings

    var body: some View {
        Toggle("Dark Mode", isOn: $settings.isDarkMode)
    }
}

// Option A: Real object
#Preview {
    ThemeToggleView()
        .environmentObject(Settings())
}

// Option B: Mock object
class MockSettings: Settings {
    override init() {
        super.init()
        isDarkMode = true  // Preset state
    }
}

#Preview("Dark Mode") {
    ThemeToggleView()
        .environmentObject(MockSettings())
}
```

**Questions**:
1. For simple objects like Settings, prefer real or mock?
2. Does it matter if Settings() has complex initialization?
3. If Settings loads from UserDefaults, does that change the answer?

I think the preference is going to be to use the real settings type, and then we would just switch to mock if something about the setup actually ends up being pretty complicated or if some behavior within the real type has side effects that we need to prevent or control in some other way. But if there is something we need to control like user defaults or some time provider or something like that, then maybe we switch to a mock at that point.

Oh and here's one thing I'm remembering from way back: I actually think very much that if we do have a mock, it should probably be an extension on the original type as a static member. It might make sense to make mockable a protocol but that's something we can discuss or wait on. If that's a great idea and commonly done then let's just make that the norm now. As I think more about the mock-equal protocol, I think we run into issues because it would be easy if we could just say there has to be a computed property called mock, but what if there is a reason to have multiple different mocks or a function that creates mocks? 

### Scenario 2: Network-Dependent Object
```swift
struct UserListView: View {
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        List(userManager.users) { user in
            Text(user.name)
        }
    }
}

// Option A: Real object (empty state)
#Preview("Empty State") {
    UserListView()
        .environmentObject(UserManager())  // Empty, no network call
}

// Option B: Mock with data
class MockUserManager: UserManager {
    override init() {
        super.init()
        users = [
            User(name: "Alice"),
            User(name: "Bob"),
            User(name: "Carol")
        ]
    }
}

#Preview("With Users") {
    UserListView()
        .environmentObject(MockUserManager())
}

// Option C: Real object with test data injection
#Preview("With Users") {
    let manager = UserManager()
    manager.loadTestData()  // Method that bypasses network
    return UserListView()
        .environmentObject(manager)
}
```

**Questions**:
1. Which pattern do you prefer?
2. If UserManager has a `loadTestData()` method, is that better than mocking?
3. Or should we create a proper mock/stub protocol? Show me more about what a mock stub protocol looks like. I have not done a lot of networking stuff, so I don't have a well-developed opinion here 

### Scenario 3: Core Data Dependencies
```swift
struct TaskListView: View {
    @FetchRequest(sortDescriptors: []) var tasks: FetchedResults<Task>

    var body: some View {
        List(tasks) { task in
            Text(task.title)
        }
    }
}

// Option A: Preview with real Core Data stack
#Preview {
    TaskListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// Option B: Preview with in-memory store + sample data
#Preview {
    let context = PersistenceController.inMemory.container.viewContext

    // Create sample data
    let task1 = Task(context: context)
    task1.title = "Sample Task 1"

    let task2 = Task(context: context)
    task2.title = "Sample Task 2"

    return TaskListView()
        .environment(\.managedObjectContext, context)
}
```

**Questions**:
1. Which approach for Core Data previews?
2. Should sample data creation live in preview, or in a helper?
3. Is in-memory store + sample data considered "real" or "mock"?

We should be using SwiftData Instead of core data and you could look at my Point1K repo for examples of how I've utilized it in the past. I think it is a good reference for this question in the SwiftData sense 

### Scenario 4: Authentication State
```swift
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isAuthenticated {
            Text("Welcome, \(authManager.currentUser.name)")
        } else {
            Text("Please log in")
        }
    }
}

// How to preview both states?

// Option A: Two real objects, different states
#Preview("Logged In") {
    let auth = AuthManager()
    auth.mockLogin(user: User(name: "Test User"))
    return ProfileView()
        .environmentObject(auth)
}

#Preview("Logged Out") {
    ProfileView()
        .environmentObject(AuthManager())
}

// Option B: Mock object with presets
class MockAuthManager: AuthManager {
    init(isAuthenticated: Bool) {
        super.init()
        self.isAuthenticated = isAuthenticated
        if isAuthenticated {
            currentUser = User(name: "Test User")
        }
    }
}

#Preview("Logged In") {
    ProfileView()
        .environmentObject(MockAuthManager(isAuthenticated: true))
}
```

**Questions**:
1. If the real object has a `mockLogin()` method, is that acceptable?
2. Or is that mixing concerns (production code with test helpers)?
3. Should mocks always be separate classes?

Oh I don't know, I haven't dealt much with this kind of stuff 

### Framework to Develop

**Simple Dependencies** (Settings, Preferences):
- Strategy: ?

**Network Dependencies** (API managers, data fetchers):
- Strategy: ?

**Persistence Dependencies** (Core Data, SwiftData):
- Strategy: ?

**Authentication/State Dependencies**:
- Strategy: ?

**General Questions**:
1. Should all dependencies have preview helpers (testData/mockLogin)?
2. Or should we create protocol-based mocks?
3. Or inline preview setup every time?
4. Does the answer change based on dependency complexity?

Again I guess I just don't have a strong enough opinion yet except for where I might already have an example like with SwiftData 

---

## E4: Extension Usage - When to Use?

### Your Original Response
"This seems like a pretty dumb example and it should be kept in the main type. If you want to ask a more interesting version of that, come back to me"

### What We Need
Better examples of extension usage scenarios.

### Scenario 1: Protocol Conformance Organization
```swift
// Option A: Everything inline
struct UserProfile: View, Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String

    var body: some View { ... }

    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Codable
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}

// Option B: Extensions for each protocol
struct UserProfile: View {
    let id = UUID()
    var name: String
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

**Question**: Protocol conformance - inline or extensions?

Even though I think sometimes it's okay to do it in-line, I guess we should just set the standard as having them all separated As you show in option B, 

### Scenario 2: Grouping Private Methods
```swift
// Option A: All in main type
struct ContentView: View {
    var body: some View { ... }

    private func loadData() { ... }
    private func saveData() { ... }
    private func validateInput() -> Bool { ... }
    private func formatOutput() -> String { ... }
}

// Option B: Extensions for method groups
struct ContentView: View {
    var body: some View { ... }
}

extension ContentView {
    // Data operations
    private func loadData() { ... }
    private func saveData() { ... }
}

extension ContentView {
    // Validation & formatting
    private func validateInput() -> Bool { ... }
    private func formatOutput() -> String { ... }
}
```

**Question**: Private method organization - inline or grouped extensions?

I've seen some compelling cases for B but I'd like to stick with A until I have some exotic streak or wild hair 

### Scenario 3: MARK Comments vs Extensions
```swift
// Option A: MARK comments
struct DashboardView: View {
    var body: some View { ... }

    // MARK: - Data Loading
    private func loadData() { ... }
    private func refreshData() { ... }

    // MARK: - User Actions
    private func handleTap() { ... }
    private func handleSwipe() { ... }

    // MARK: - Formatting
    private func formatDate() -> String { ... }
    private func formatNumber() -> String { ... }
}

// Option B: Extensions replace MARK comments
struct DashboardView: View {
    var body: some View { ... }
}

// MARK: - Data Loading
extension DashboardView {
    private func loadData() { ... }
    private func refreshData() { ... }
}

// MARK: - User Actions
extension DashboardView {
    private func handleTap() { ... }
    private func handleSwipe() { ... }
}
```

**Question**: Are extensions + MARK better than just MARK? Or overkill?

I think these are possibly separate. I think marks are good but not required and extensions can be helpful but don't need to be a first tool to reach for 

### Scenario 4: Computed Properties Organization
```swift
// Option A: Inline
struct ProfileView: View {
    var body: some View {
        VStack {
            headerSection
            detailsSection
            actionsSection
        }
    }

    private var headerSection: some View { ... }
    private var detailsSection: some View { ... }
    private var actionsSection: some View { ... }
}

// Option B: Extension for view properties
struct ProfileView: View {
    var body: some View {
        VStack {
            headerSection
            detailsSection
            actionsSection
        }
    }
}

extension ProfileView {
    private var headerSection: some View { ... }
    private var detailsSection: some View { ... }
    private var actionsSection: some View { ... }
}
```

**Question**: Should computed view properties go in extensions?

In-line Option A 

### Scenario 5: Type-Specific Extensions
```swift
// String utilities specific to this view
struct MessageView: View {
    let message: String

    var body: some View {
        Text(message.formatted)
    }
}

extension String {
    var formatted: String {
        // Message-specific formatting
        self.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n\n", with: "\n")
    }
}
```

**Question**: Type extensions in same file as the view - acceptable or separate file?

If it's a private extension and specialized then keep it as a private extension in the file. But if it's generic even if it is only used once, then make it its own extension file. I like having those things easily discoverable and I also think that it will help find things that are easily extractable into a tools framework or any other framework that I am running 

### What's the Rule?

**When to use extensions**:
- ?

**When to keep inline**:
- ?

**MARK comments vs extensions**:
- ?

**File organization**:
- Single file with extensions?
- Separate extension files?

---

## E9: Extension File Naming Conventions

### Your Original Response
"Matches type name absolutely... Things change a little bit though for extensions. But you should ask me some well-generated questions directly for that if there aren't any lower in this document"

### What We Need
Extension file naming guidelines.

### Scenario 1: Protocol Conformance Extensions
```swift
// File: UserProfile.swift
struct UserProfile: View {
    var body: some View { ... }
}

// Where does this extension live?
extension UserProfile: Codable {
    enum CodingKeys: String, CodingKey { ... }
}

// Option A: Same file (UserProfile.swift)
// Option B: UserProfile+Codable.swift
// Option C: UserProfile.Codable.swift
// Option D: Extensions/UserProfile+Codable.swift
```

**Questions**:
1. Keep in same file if extension is small?Yes I think in general, if it's small, keep it in the same file. But in that case it also needs to be a somewhat expected extension. In the example you gave it seems pretty unique that we'd be adding codable to a view, so that might make sense to put in a separate extension. That also highlights the point that I think if the extension is to satisfy what I would call a "distant" requirement, then it also makes sense in a sewparate extension there 
2. Separate file for substantial protocol conformance? Basically yes 
3. What naming pattern: `+Protocol` or `.Protocol`? I definitely prefer the Plus 
4. Subdirectory for extensions? There can be a subdirectory from the root of the project For the widely used extensions But if it's a "local extension," then it can be in the same directory 

### Scenario 2: Type Extensions (Foundation/SwiftUI)
```swift
// Date formatting utilities used across project
extension Date {
    func formatted(style: DateStyle) -> String { ... }
    var isToday: Bool { ... }
    var isYesterday: Bool { ... }
}

// File name options:
// A: Date+Extensions.swift
// B: Date+Formatting.swift
// C: DateExtensions.swift
// D: Extensions/Date.swift
```

**Questions**:
1. General extensions: `Type+Extensions.swift`?
2. Specific extensions: `Type+Feature.swift`?
3. Subdirectory or root level?

Option A is the default when there are a few extensions. But kind of like with our rule for enum Constants, everything should go in the enum Constants until that enum gets big and then it can make sense to make more focused constant enums by different names 

### Scenario 3: View-Specific Extensions in Same File
```swift
// File: DashboardView.swift
struct DashboardView: View {
    var body: some View { ... }
}

extension DashboardView {
    private func helperMethod() { ... }
}

// Is this acceptable or should it be:
// File: DashboardView+Helpers.swift?
```

**Question**: When does an extension warrant a separate file?

I feel we've covered this in other questions. What makes this different? Unless I'm missing something, yes this is acceptable But also maybe why not just put that within the view struct in the first place instead of an extension? 

### Scenario 4: Multiple Extensions for Same Type
```swift
// Project has multiple extensions for String:

// String+Validation.swift
extension String {
    var isValidEmail: Bool { ... }
    var isValidURL: Bool { ... }
}

// String+Formatting.swift
extension String {
    func truncated(length: Int) -> String { ... }
    var capitalizingFirstLetter: String { ... }
}

// String+Parsing.swift
extension String {
    func parseJSON<T: Decodable>() -> T? { ... }
}
```

**Question**: Multiple extension files per type - acceptable pattern?

This is acceptable as long as it's not something like we have three extension files for three individual extensions that are each actually very small That would be annoying 

### Scenario 5: Extension Organization
```
Project/
├── Models/
│   ├── User.swift
│   ├── User+Codable.swift  // Option A: Next to type
│   └── User+Validation.swift
├── Extensions/  // Option B: Dedicated directory
│   ├── User+Codable.swift
│   ├── User+Validation.swift
│   ├── Date+Formatting.swift
│   └── String+Validation.swift
├── Views/
│   └── ProfileView.swift
```

**Questions**:
1. Extensions next to the type they extend?
2. Or centralized Extensions/ directory?
3. Mix of both (protocol conformance with type, utilities in Extensions/)?

Option A is the first option but if there gets to be a lot of them then we will use option B. Of course this is subjective but maybe starting around 4 extensions it would start to be a consideration to make a new directory And then I think certainly at 6 to 8 we're going to need to move to extensions directory 

### Framework Questions

**Naming Convention**:
- `TypeName+Feature.swift`?
- `TypeName.Feature.swift`?
- `TypeNameFeature.swift`?

**Location**:

- Same directory as type?
- Extensions/ subdirectory?
- Context-dependent?

**Separation Threshold**:
- Lines of code?
- Conceptual separation?
- Always separate or always inline?

**Multiple Extensions**:
- One file per logical grouping?
- All extensions in one file?
- Context-dependent?

I think I answered all of these inline? Did I miss anything? 

---

## Next Steps

1. **Review these questions** and provide answers via dictation or written responses
2. **I'll update classification_analysis.md** with your clarifications
3. **Codify into Skill frameworks** where appropriate
4. **Create new SwiftSyntax rules** if patterns are mechanically enforceable

---

## Notes

Some of these might not have clear-cut answers and may remain "context-dependent" - that's fine! The goal is to document your thinking process so future decisions are easier and more consistent.
