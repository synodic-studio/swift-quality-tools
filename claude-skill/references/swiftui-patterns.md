# SwiftUI Patterns

Comprehensive SwiftUI patterns with detailed examples and usage guidance.

## View Structure Enforcement

### Required Property Order

All SwiftUI views must follow this exact order:

1. **Embedded types first** - Enums, structs, classes defined within the view
2. **Environment properties grouped** - `@Environment`, `@EnvironmentObject`, `@AppStorage`, `@SceneStorage`
3. **Other properties** - `@State`, `@Binding`, stored properties, `let`/`var` declarations
4. **init (if present)** - Must immediately precede body
5. **body property** - Main view definition
6. **Computed properties and methods** - All helper views and functions below body

### Example

```swift
struct ProfileView: View {
    // 1. Embedded types
    enum ProfileMode {
        case view, edit
    }

    // 2. Environment properties
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager
    @AppStorage("showDetails") private var showDetails = true

    // 3. Other properties
    @State private var mode: ProfileMode = .view
    @Binding var user: User
    let isAdmin: Bool

    // 4. init (if present)
    init(user: Binding<User>, isAdmin: Bool = false) {
        _user = user
        self.isAdmin = isAdmin
    }

    // 5. body property
    var body: some View {
        VStack {
            headerSection
            profileContent
        }
    }

    // 6. Computed properties and methods
    private var headerSection: some View {
        Text(user.name)
    }

    private var profileContent: some View {
        Text("Profile content")
    }
}
```

## Layout Modifiers

### Overlay and Background

**Always use modifiers, not ZStack:**

```swift
// ✅ Correct: Use .overlay() modifier
Image("profile")
    .overlay(alignment: .bottomTrailing) {
        Badge(count: 5)
    }

// ❌ Wrong: Don't use ZStack for overlays
ZStack {
    Image("profile")
    Badge(count: 5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
}

// ✅ Correct: Use .background() modifier
Text("Hello")
    .background(Color.blue)

// ❌ Wrong: Don't use ZStack for backgrounds
ZStack {
    Color.blue
    Text("Hello")
}
```

### Frame Alignment Pattern

**Prefer frame alignment over Spacer:**

```swift
// ✅ Correct: Use frame with alignment
Text("Aligned Left")
    .frame(maxWidth: .infinity, alignment: .leading)

// ❌ Wrong: Don't use Spacer for alignment
HStack {
    Text("Aligned Left")
    Spacer()
}

// ✅ Correct: Use frame with alignment for vertical
Text("Top Aligned")
    .frame(maxHeight: .infinity, alignment: .top)

// ❌ Wrong: Don't use Spacer for vertical alignment
VStack {
    Text("Top Aligned")
    Spacer()
}
```

**Important**: When using `.frame(alignment:)`, always include width/height parameters or alignment has no effect.

```swift
// ✅ Correct: Includes maxWidth parameter
.frame(maxWidth: .infinity, alignment: .leading)

// ❌ Wrong: No width parameter, alignment ignored
.frame(alignment: .leading)
```

## onChange Patterns

### Simple Function Reference

When calling a simple function without arguments:

```swift
// ✅ Correct: Direct function reference
.onChange(of: selectedTab, handleTabChange)

private func handleTabChange() {
    // React to tab change
}
```

### Zero-Parameter Closure

When accessing the watched property directly:

```swift
// ✅ Correct: Zero-parameter closure with direct access
.onChange(of: manager.data) {
    guard let data = manager.data else { return }
    processData(data)
}
```

### What to Avoid

```swift
// ❌ Avoid: Complex parameter patterns when simpler alternatives exist
.onChange(of: value) { oldValue, newValue in
    process(newValue)
}

// ✅ Better: Use simpler pattern
.onChange(of: value) {
    process(value)
}
```

## Constants vs Magic Numbers

**Always use meaningful constants:**

```swift
// ❌ Wrong: Magic numbers
VStack(spacing: 16) {
    Rectangle()
        .frame(height: 44)
        .cornerRadius(8)
}

// ✅ Correct: Named constants
private enum Layout {
    static let spacing: CGFloat = 16
    static let buttonHeight: CGFloat = 44
    static let cornerRadius: CGFloat = 8
}

VStack(spacing: Layout.spacing) {
    Rectangle()
        .frame(height: Layout.buttonHeight)
        .cornerRadius(Layout.cornerRadius)
}
```

## Control Flow: Never Use .if Modifier

**NEVER create or use an `.if` modifier:**

```swift
// ❌ NEVER do this:
someView
    .if(condition) { view in
        view.padding()
    }

// ✅ Instead, use standard Swift control flow:
if condition {
    someView.padding()
} else {
    someView
}

// ✅ Or use non-optional types with defaults:
someView
    .opacity(isVisible ? 1.0 : 0.0)
```

The `.if` modifier is an anti-pattern that obscures control flow and creates unnecessary complexity.

## View Modifiers and Method Chaining

### Multi-Line Arguments

Functions with 4+ arguments should span multiple lines:

```swift
// ✅ Correct: Each argument on its own line
Button(
    "Submit",
    systemImage: "checkmark",
    role: .primary,
    action: handleSubmit
)

// ❌ Wrong: Too many arguments on one line
Button("Submit", systemImage: "checkmark", role: .primary, action: handleSubmit)
```

### Method Chaining with Delimiters

Don't chain methods on the same line as closing delimiters when delimiter is on its own line:

```swift
// ✅ Correct: Method chain starts on new line
Text("Hello")
    .font(.title)
    .foregroundColor(.blue)

// ❌ Wrong: Method chain on same line as closing brace
VStack {
    Text("Content")
}.padding()

// ✅ Correct: Method chain on new line
VStack {
    Text("Content")
}
.padding()
```

## Naming and Self-Documentation

### Clear Meaningful Names

Code should explain what it does without comments:

```swift
// ✅ Correct: Clear, descriptive names
private func calculateMonthlyPayment(principal: Double, rate: Double, years: Int) -> Double {
    let monthlyRate = rate / 12
    let numberOfPayments = years * 12
    return principal * (monthlyRate * pow(1 + monthlyRate, Double(numberOfPayments)))
        / (pow(1 + monthlyRate, Double(numberOfPayments)) - 1)
}

// ❌ Wrong: Abbreviations and unclear names
private func calcPmt(p: Double, r: Double, y: Int) -> Double {
    let mr = r / 12
    let n = y * 12
    return p * (mr * pow(1 + mr, Double(n))) / (pow(1 + mr, Double(n)) - 1)
}
```

### Comments

**Comments should only exist if meant to stay:**

```swift
// ✅ Correct: Documentation comment
/// Calculates the monthly mortgage payment.
/// - Parameters:
///   - principal: The loan amount
///   - rate: Annual interest rate (as decimal, e.g., 0.05 for 5%)
///   - years: Loan term in years
/// - Returns: Monthly payment amount
func calculateMonthlyPayment(principal: Double, rate: Double, years: Int) -> Double {
    // Implementation
}

// ❌ Wrong: Temporary TODO comments
func processData() {
    // TODO: implement this
    // FIXME: this is broken
}
```

**Prefer in-code documentation (`///`) over separate `.md` files** for API documentation.

## SwiftUI Preview Patterns

### Basic Preview

```swift
#Preview {
    ProfileView(
        user: .constant(User.sample),
        isAdmin: true
    )
}
```

### Preview with Environment

```swift
#Preview {
    ProfileView(user: .constant(User.sample))
        .environmentObject(AuthManager())
}
```

### Multiple Preview Configurations

```swift
#Preview("Light Mode") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    ContentView()
        .environment(\.dynamicTypeSize, .xxxLarge)
}
```
