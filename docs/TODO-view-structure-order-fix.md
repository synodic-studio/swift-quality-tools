# TODO: Fix view_structure_order Rule

## Status
**DISABLED** - Rule disabled in `CustomRulesVisitor.swift:34` until fixed

## Problem Summary
The `view_structure_order` rule incorrectly categorizes computed properties as "other properties" instead of "computed/methods", causing false violations when computed properties appear before the `body` property.

## Root Cause
In `ViewStructureRules.swift`, the categorization logic has a bug:

**Lines 31-52**: First pass categorizes ALL variable declarations
- If it's `body` → categorized as `.body`
- If it has environment attributes → categorized as `.environmentProperty`
- **Otherwise → categorized as `.otherProperty`** ← BUG

**Lines 60-64**: Second pass tries to recategorize computed properties
- Checks if variable has `accessorBlock` (indicating it's computed)
- Should categorize as `.computedOrMethod`
- **BUT this check never executes because the variable was already categorized as `.otherProperty` in the first pass**

## Expected vs Actual Behavior

### Expected Order
```swift
struct MyView: View {
    // 1. Embedded types
    private struct HelperType { }

    // 2. Environment properties
    @EnvironmentObject var appState: AppState
    @SceneStorage("key") var value: String

    // 3. Other properties (stored)
    @State private var count: Int = 0
    private let constant: String = "test"

    // 4. init (optional)
    init() { }

    // 5. body (REQUIRED)
    var body: some View {
        Text("Hello")
    }

    // 6. Computed properties and methods (after body)
    private var computed: String {  // ← Should be allowed here
        "value"
    }

    private func method() {  // ← Should be allowed here
        print("test")
    }
}
```

### Current Bug - False Violations

#### Example 1: GravityWell/CameraControl/CameraSettingControl.swift
```swift
struct CameraSettingControl<T>: View where T: Codable {
    @ObservedObject var settingsManager: CameraSettingsManager
    let controlType: ASIControlType
    @State private var currentValue: T
    private let valueKey: String

    init(...) { ... }

    private var config: ControlConfig {  // ← COMPUTED PROPERTY (has getter)
        CameraSettingsConfig.forControl(controlType)
    }

    var body: some View { ... }  // ← Rule complains: "config should come after body"
}
```

**Issue**: `config` is a **computed property** (has a getter, no stored value). It should be allowed to appear EITHER before or after body, but rule treats it as a stored property that must come before body.

#### Example 2: GravityWell/ContentView.swift
```swift
struct ContentView: View {
    @SceneStorage("showStartupMessage") private var showStartupMessage = true
    @EnvironmentObject private var appState: AppState
    @State private var keyEventMonitor: Any?

    var body: some View { ... }

    // Rule reports this violation (WRONG):
    // "@SceneStorage should come before later members"

    // But the code is already correct! @SceneStorage IS before body.
    // The bug is that the rule sees @State AFTER @SceneStorage
    // and incorrectly thinks that's a violation.
}
```

**Issue**: The rule gets confused about environment property ordering. @SceneStorage, @EnvironmentObject, and @State are all appearing in the correct section (before body), but the rule is too strict about their internal ordering.

#### Example 3: GravityWellUI/Primitives/GrayscaleStrategySection.swift
```swift
public struct GrayscaleStrategySection<Strategy>: View {
    public let grayscaleImage: NSImage?
    public let engineError: String?
    @Binding public var strategy: Strategy

    public init(...) { ... }

    public var body: some View {
        VStack {
            headerSection  // ← References computed property
            grayscaleImageView
            strategyPicker
        }
    }

    // These are all computed properties, should be allowed after body
    private var availableStrategies: [Strategy] {  // ← FALSE VIOLATION
        Array(Strategy.allCases)
    }

    @ViewBuilder private var grayscaleImageView: some View {  // ← FALSE VIOLATION
        if let grayscaleImage {
            processedImageView(grayscaleImage)
        } else {
            grayscalePlaceholder
        }
    }

    private var headerSection: some View {  // ← FALSE VIOLATION
        VStack {
            Text("Grayscale Conversion")
        }
    }
}
```

**Issue**: ALL of these are computed properties (they have getters/bodies). The rule incorrectly categorizes them as "other properties" and complains they should come before `body`.

## The Fix

### Option 1: Check for Computed Properties First (Recommended)
Modify `ViewStructureRules.swift` around line 31-52 to detect computed properties BEFORE categorizing as `.otherProperty`:

```swift
if let varDecl = member.decl.as(VariableDeclSyntax.self) {
    // Check if it's body
    if let binding = varDecl.bindings.first,
       let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
       identifier.identifier.text == "body"
    {
        memberCategories.append((.body, "body property"))
        continue
    }

    // ✅ CHECK FOR COMPUTED PROPERTY FIRST
    if let binding = varDecl.bindings.first,
       binding.accessorBlock != nil  // Has getter/setter block = computed
    {
        memberCategories.append((.computedOrMethod, memberDesc.prefix(50).description))
        continue  // ← Skip to next member
    }

    // Check for environment properties
    let hasEnvironmentAttribute = varDecl.attributes.contains { attr in
        let attrName = attr.as(AttributeSyntax.self)?.attributeName.description ?? ""
        return ["Environment", "EnvironmentObject", "AppStorage", "SceneStorage"]
            .contains(attrName)
    }

    if hasEnvironmentAttribute {
        memberCategories.append((.environmentProperty, memberDesc.prefix(50).description))
    } else {
        // Now this only catches true stored properties
        memberCategories.append((.otherProperty, memberDesc.prefix(50).description))
    }
}
```

### Option 2: Relax the Rule
Allow computed properties and methods to appear ANYWHERE (before or after body), since they're just helper code and don't affect the View's state/initialization:

```swift
let categoryOrder: [MemberCategory] = [
    .embeddedType,
    .environmentProperty,
    .otherProperty,
    .initializer,
    .body,
    // Don't enforce order for .computedOrMethod at all
]

// Skip computed/method from ordering checks
for (category, description) in memberCategories {
    if category == .computedOrMethod {
        continue  // Allow anywhere
    }

    guard let currentIndex = categoryOrder.firstIndex(of: category) else { continue }
    // ... rest of logic
}
```

### Option 3: Distinguish Stored vs Computed More Clearly
Update the expected order to be more explicit:

```swift
// Expected order:
// 1. Embedded types (enum, struct, class, protocol, actor)
// 2. Environment properties (@Environment, @EnvironmentObject, @AppStorage, @SceneStorage)
// 3. STORED properties (@State, @Binding, let, var with initial value)
// 4. init (must immediately precede body)
// 5. body property
// 6. COMPUTED properties (var with getter) and methods
```

## Testing the Fix

Once fixed, verify these files no longer show violations:

```bash
# Should show 0 violations after fix
/Users/bryancostanza/Developer/swift-quality-tools/.build/debug/test-custom-rule \
  GravityWell/CameraControl/CameraSettingControl.swift

/Users/bryancostanza/Developer/swift-quality-tools/.build/debug/test-custom-rule \
  GravityWell/ContentView.swift

/Users/bryancostanza/Developer/swift-quality-tools/.build/debug/test-custom-rule \
  GravityWellUI/Sources/GravityWellUI/Primitives/GrayscaleStrategySection.swift
```

## Files Affected
**51 files** had false violations before the rule was disabled:
- See `/tmp/lint_output.txt` for full list
- Or run: `grep "view_structure_order" /tmp/lint_output.txt | wc -l`

## Re-enabling the Rule
After fixing, re-enable in `CustomRulesVisitor.swift`:

```swift
if conformsToView {
    currentStructDecl = node
    isInSwiftUIView = true

    // Rule: view_structure_order
    ViewStructureRules.checkViewStructureOrder(node, violations: &violations)  // ← Uncomment
}
```

Then rebuild:
```bash
cd /Users/bryancostanza/Developer/swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration/rule-engine
swift build
```

## References
- Rule source: `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules/ViewStructureRules.swift`
- Visitor integration: `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules/CustomRulesVisitor.swift:32`
- Related discussion: Conversation session 2025-11-16 (view_structure_order debugging)
