# SwiftSyntax-Based Custom Rules

This document describes the SwiftSyntax-based custom rules that provide precise AST-based analysis for Swift code quality enforcement.

## Available Rules

**Module Organization**: Rules are organized into logical modules for maintainability:
- **ViewBodyRules**: Body-specific patterns (skimmable_body, no_group_body, one_top_level_view)
- **ViewStructureRules**: View organization (view_structure_order, no_wrapper_body)
- **CodeQualityRules**: General code quality (constants_enum_usage, excessive_nesting)
- **ImportRules**: Import organization (blank_line_import_separation)
- **PreviewRules**: Preview requirements (preview_required)

---

### `skimmable_body`
**Description**: SwiftUI View `body` properties should be 15 lines or fewer to remain skimmable.

**Severity**: Warning

**What it checks**: Line count within View body properties

**Example Violation**:
```swift
var body: some View {
    // ... 20 lines of code ...
}
```

**How to fix**: Extract complex sections into computed properties or separate view components.

---

### `no_group_body`
**Description**: SwiftUI View body should not have `Group` as the top-level view (unless it has view modifiers).

**Severity**: Warning

**What it checks**: Whether body returns a bare `Group` without modifiers

**Example Violation**:
```swift
var body: some View {
    Group {
        Text("Hello")
        Text("World")
    }
}
```

**How to fix**: Replace `Group` with proper container (`VStack`, `HStack`) or add view modifiers to the `Group`.

---

### `one_top_level_view`
**Description**: SwiftUI View body must have exactly one top-level view.

**Severity**: Warning

**What it checks**: Multiple sibling views at the top level of body

**Example Violation**:
```swift
var body: some View {
    Text("First")
    Text("Second")  // Multiple top-level views
}
```

**How to fix**: Wrap multiple views in a container (`VStack`, `HStack`, `ZStack`).

---

### `excessive_nesting`
**Description**: Code should not exceed 4 levels of indentation depth.

**Severity**: Warning

**What it checks**: Indentation depth in functions, initializers, and closures

**Example Violation**:
```swift
func example() {
    if condition {
        for item in items {
            switch item {
                case .foo:
                    if nested {  // 5th level - too deep!
                        // ...
                    }
            }
        }
    }
}
```

**How to fix**: Extract nested logic into separate functions or use guard statements for early returns.

---

### `view_structure_order`
**Description**: Enforce correct member ordering in SwiftUI Views.

**Severity**: Warning

**Expected Order**:
1. Embedded types (enum, struct, class, protocol, actor)
2. Environment properties (@Environment, @EnvironmentObject, @AppStorage, @SceneStorage)
3. Other properties (@State, @Binding, let, var)
4. init (must immediately precede body if present)
5. body property
6. Computed properties and methods

**Example Violation**:
```swift
struct MyView: View {
    @State private var count = 0
    @Environment(\.dismiss) var dismiss  // ❌ Should come before @State

    var body: some View { ... }
}
```

**How to fix**: Reorder members according to the expected structure.

---

### `no_wrapper_body`
**Description**: Detect pointless wrapper body properties.

**Severity**: Warning

**What it checks**: Whether body just returns another property without adding value

**Example Violation**:
```swift
var body: some View {
    mainContent  // ❌ Pointless wrapper
}

private var mainContent: some View {
    VStack { ... }
}
```

**How to fix**: Either:
- Merge `mainContent` logic directly into `body`
- Or extract meaningful sections (headerView, contentView) that body composes

**Valid Pattern**:
```swift
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}
```

---

### `constants_enum_usage`
**Description**: Detect magic numbers and suggest using an `enum Constants` pattern.

**Severity**: Warning

**What it checks**: Numeric literals (except 0, 1, 2, 0.0, 1.0, 0.5) in SwiftUI Views

**Example Violation**:
```swift
.padding(16)  // ❌ Magic number
.cornerRadius(12.0)  // ❌ Magic number
```

**How to fix**: Use `enum Constants` pattern:
```swift
struct MyView: View {
    enum Constants {
        static let padding: CGFloat = 16
        static let cornerRadius: CGFloat = 12.0
    }

    var body: some View {
        content
            .padding(Constants.padding)
            .cornerRadius(Constants.cornerRadius)
    }
}
```

---

### `blank_line_import_separation`
**Description**: Enforce blank line between regular imports and @testable imports.

**Severity**: Warning

**What it checks**: Spacing between import groups

**Example Violation**:
```swift
import Foundation
import SwiftUI
@testable import MyPackage  // ❌ No blank line
```

**How to fix**: Add blank line:
```swift
import Foundation
import SwiftUI

@testable import MyPackage  // ✅ Blank line present
```

---

### `preview_required`
**Description**: Every file with View/ViewModifier must have at least one #Preview.

**Severity**: Warning

**What it checks**: Presence of #Preview or @Preview in files declaring Views or ViewModifiers

**Example Violation**:
```swift
struct MyView: View {
    var body: some View {
        Text("Hello")
    }
}
// ❌ No #Preview
```

**How to fix**: Add at least one preview:
```swift
struct MyView: View {
    var body: some View {
        Text("Hello")
    }
}

#Preview {
    MyView()
}
```

**Rationale**:
- Previews accelerate development workflow
- Enable visual verification without running the app
- Document expected appearance
- Facilitate design system consistency
- Essential for SwiftUI development best practices

---

## Usage

### Via swiftlintcustom-smart
The smart tool automatically discovers and runs these rules:
```bash
swiftlintcustom-smart path/to/File.swift
```

### Via Hook Integration
PostToolUse hook runs these rules automatically after Swift file edits.

### Direct Testing
```bash
cd swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration/rule-engine
swift build
.build/debug/test-custom-rule path/to/File.swift
```

## Implementation Details

**Technology**: SwiftSyntax library for precise AST parsing
**Performance**: ~1 second per file after initial build
**Accuracy**: 100% - no false positives from regex backtracking

## Benefits

1. **Performance**: No regex catastrophic backtracking
2. **Accuracy**: Proper Swift syntax parsing via AST
3. **Maintainability**: Clear Swift code instead of complex regex
4. **Extensibility**: Easy to add sophisticated rules
5. **Context-Aware**: Can detect patterns impossible with regex

## Rule Identifier Reference

For use in documentation, skill files, and error messages:

- `skimmable_body` - Body line count (15 max)
- `no_group_body` - No top-level Group
- `one_top_level_view` - Exactly one top-level view
- `excessive_nesting` - Max 4 indentation levels
- `view_structure_order` - Member ordering
- `no_wrapper_body` - No pointless wrappers
- `constants_enum_usage` - No magic numbers
- `blank_line_import_separation` - Import group spacing
- `preview_required` - Every View/ViewModifier must have #Preview

## Future Enhancements

Potential additional rules:
- `prefer_frame_over_spacer` - Frame with alignment over VStack+Spacer
- `frame_alignment_requires_dimensions` - Frame alignment needs width/height
- `multiline_arguments_threshold` - Functions with 4+ args on multiple lines
- `no_if_modifier` - Detect custom .if modifier usage
