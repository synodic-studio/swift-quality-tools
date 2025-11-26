# Identified But Not Implemented

**Sources**:
- Pre-Phase 4: SwiftSyntax rule ideas from `CustomRules/swiftlint-swiftsyntax-integration/SWIFTSYNTAX_RULES.md`
- Phase 4 Alpha: Preference discovery session (2025-11-15 to 2025-11-16)

**Full Analysis**: See `PreferenceDiscovery/archive/phase4-alpha/classification_analysis.md` for Phase 4 Alpha rationale

This document tracks all identified but unimplemented SwiftSyntax rules and skill frameworks.

---

## Pre-Phase 4 Identified Rules

**Source**: `CustomRules/swiftlint-swiftsyntax-integration/SWIFTSYNTAX_RULES.md` - "Future Enhancements" section

### SwiftSyntax Rules

#### 1. prefer_frame_over_spacer
**Priority**: Medium
**Difficulty**: Medium

**What**: Suggest using `.frame(maxHeight: .infinity, alignment: .top)` instead of `VStack { content; Spacer() }`

**Why**: More concise, declarative, and performant approach to alignment

**Example**:
```swift
// ❌ Avoid
VStack {
    Text("Header")
    Spacer()
}

// ✅ Prefer
Text("Header")
    .frame(maxHeight: .infinity, alignment: .top)
```

**Note**: This is a preference, not always wrong - VStack+Spacer is more explicit about layout intent

---

#### 2. frame_alignment_requires_dimensions
**Priority**: Low
**Difficulty**: Low

**What**: Warn when using `.frame(alignment: .top)` without specifying width or height

**Why**: Frame alignment has no effect without dimensions - likely a mistake

**Example**:
```swift
// ❌ Warning - alignment has no effect
Text("Hello")
    .frame(alignment: .top)

// ✅ Correct - alignment works with dimension
Text("Hello")
    .frame(maxHeight: .infinity, alignment: .top)
```

---

#### 3. multiline_arguments_threshold
**Priority**: Low
**Difficulty**: Medium

**What**: Functions with 4+ parameters should have each parameter on its own line

**Why**: Improves readability and maintainability

**Example**:
```swift
// ❌ Hard to read
func configure(name: String, age: Int, address: String, phone: String) { }

// ✅ Clear and scannable
func configure(
    name: String,
    age: Int,
    address: String,
    phone: String
) { }
```

**Note**: SwiftFormat may already handle this - verify before implementing

---

#### 3.5. single_modifier_per_line
**Priority**: Medium
**Difficulty**: Medium
**Status**: ✅ IMPLEMENTED (2025-11)

**What**: Each modifier should be on its own line - no multiple modifiers chained on same line, no modifier on same line as closing delimiter

**Why**: Improves readability - modifiers should be visually scannable

**Example**:
```swift
// ❌ Multiple modifiers on same line
Text("Hello").padding().background(.red)

// ❌ Modifier on same line as closing delimiter
SomeView(
    parameter: value
).padding()

// ✅ Each modifier on its own line
Text("Hello")
    .padding()
    .background(.red)

// ✅ Clear structure
SomeView(
    parameter: value
)
.padding()
```

**Implementation**: Added `ModifierFormattingRules.swift` with line-based pattern detection

---

#### 4. no_if_modifier
**Priority**: High
**Difficulty**: Low
**Status**: ✅ IMPLEMENTED (2025-11)

**What**: Detect custom `.if` modifier pattern and suggest standard SwiftUI patterns

**Why**: Custom `.if` modifier is an anti-pattern - SwiftUI has better native approaches

**Example**:
```swift
// ❌ Custom .if modifier (anti-pattern)
Text("Hello")
    .if(isRed) { $0.foregroundColor(.red) }

// ✅ Use standard SwiftUI conditional modifiers
Text("Hello")
    .foregroundColor(isRed ? .red : .primary)

// ✅ Or use @ViewBuilder for complex cases
@ViewBuilder
var text: some View {
    if isRed {
        Text("Hello").foregroundColor(.red)
    } else {
        Text("Hello")
    }
}
```

**Rationale**: The `.if` modifier pattern bypasses SwiftUI's view identity system and causes unnecessary re-renders.

---

#### 5. no_nested_ternary
**Priority**: High
**Difficulty**: Medium
**Status**: TODO (2025-11) - Build integration issues

**What**: Forbid nested ternary operators. The fix is to extract the inner ternary to a named variable with meaningful semantics.

**Why**: Nested ternaries hurt readability and make code harder to understand at a glance.

**Example**:
```swift
// Bad - nested ternary
let color = isError ? .red : isWarning ? .orange : .green

// Good - extract inner ternary to named variable
let nonErrorColor: Color = isWarning ? .orange : .green
let color = isError ? .red : nonErrorColor
```

**Implementation Notes**:
- Rule logic was implemented using TernaryExprSyntax visitor in CustomRulesVisitor.swift
- Build system issue: Swift Package Manager incremental build not detecting changes to CustomRulesVisitor.swift
- The visitor is compiled into the binary (verified via `nm` symbols) but not being invoked at runtime
- Needs investigation of Package.swift target configuration

---

#### 6. no_multiline_collapse
**Priority**: High
**Difficulty**: Medium
**Status**: TODO

**What**: Never collapse multi-line code into a single line to meet line limits. The fix is always to extract into a named subview/property.

**Why**: Collapsing multi-line code into a single line destroys readability. Line limits exist to encourage extraction, not compression.

**Example**:
```swift
// ORIGINAL - triggered skimmable_body warning
@ViewBuilder private var presetButtons: some View {
    if !config.presets.isEmpty {
        HStack {
            ForEach(config.presets.indices, id: \.self) { index in
                presetButton(at: index)
            }
        }
    }
}

// ❌ BAD "fix" - cramming code to reduce line count
@ViewBuilder private var presetButtons: some View {
    if !config.presets.isEmpty {
        HStack {
            ForEach(config.presets.indices, id: \.self) { presetButton(at: $0) }
        }
    }
}

// ✅ GOOD fix - extract complexity
@ViewBuilder private var presetButtons: some View {
    if !config.presets.isEmpty {
        presetButtonsRow
    }
}

private var presetButtonsRow: some View {
    HStack {
        ForEach(config.presets.indices, id: \.self) { index in
            presetButton(at: index)
        }
    }
}
```

**Detection Challenge**: Hard to detect programmatically - this is more of a code review principle. Could potentially detect:
- Lines significantly longer than surrounding code
- Closures with complex expressions crammed onto one line
- `{ $0.something }` patterns that could be expanded

**Note**: May be better as skill/guidance than automated rule

---

## Phase 4 Alpha - High Priority

### SwiftSyntax Rules

#### 1. ViewModifier Body Line Limit
**Source**: B3
**Type**: Extend existing `skimmable_body` rule
**Difficulty**: Low
**Status**: ✅ IMPLEMENTED (2025-11)

**What**: Apply same 15-line limit to `func body(content: Content) -> some View` in ViewModifier

**Why**: Consistency - View body is limited, ViewModifier body should be too

**Implementation**: Added `checkSkimmableViewModifierBody` to ViewBodyRules.swift

---

### Skill Framework Updates

#### 2. Type Inference Guidelines
**Source**: A4, D8
**Priority**: High
**Difficulty**: Low

**Rule**: Prefer type inference, use explicit types for:
1. Type coercion: `let padding: CGFloat = 16.0`
2. Static member shorthand: `let token: SpaceToken = .x4`

**User Quote**: "Always use inferred type unless you need to coerce it or enable static member syntax"

---

#### 3. Action Handler Naming
**Source**: C8
**Priority**: High
**Difficulty**: Medium

**Framework**: Two categories based on closure purpose
- **Direct actions** (`*Action` suffix): `Button("Save", action: saveAction)`
- **Event handlers** (`on*` prefix): `.sheet(...) { ... } onDismiss: { onSheetDismissed() }`

**Key Distinction**: `action: deleteAction` (closure IS the action) vs `onDismiss: onSheetDismissed` (responds AFTER event)

---

#### 4. Boolean Property Naming
**Source**: C3
**Priority**: High
**Difficulty**: Low

**Preferred**: `is` prefix (`isLoading`, `isEnabled`)
**Acceptable**: `has` prefix (`hasError`, `hasData`)
**Avoid**: `shows`, `displays` (sounds like action, not state)

**User Quote**: "A Boolean almost always has to have a verb as the first word"

---

#### 5. View Suffix Conventions
**Source**: C1
**Priority**: High
**Difficulty**: Low

**Standard Suffixes**:
- **View**: General SwiftUI components
- **Row**: List/ForEach items
- **Page**: Full-screen views

**User Quote**: "Just about everything should have a view suffix. Some other options are row or page."

---

## Medium Priority

### Skill Framework Updates

#### 6. Constants Enum Organization
**Source**: C5, D5, D6
**Priority**: Medium
**Difficulty**: Low

**Default**: Single flat `enum Constants`
**When to split**: If becomes large (subjective)
**Prefer**: Flat namespace over nested

**User Quote**: "Prefer Constants, flat namespace, can split if big"

---

#### 7. Common Value Extraction Threshold
**Source**: D3
**Priority**: Medium
**Difficulty**: Low

**Guideline**: Extract when 2+ uses AND provides meaningful cleanup

**Examples**:
- Single modifier 3+ times → extract
- Multiple modifiers (5+) 2+ times → extract

**User Quote**: "Once it's twice, I'm definitely interested. But needs to be weighed against how much we're really cleaning up."

---

#### 8. Computed Property Naming (Views)
**Source**: C4
**Priority**: Medium
**Difficulty**: Low

**Acceptable**:
- Noun form: `private var header: some View`
- Descriptive: `private var headerSection: some View`

**Avoid**: Verb form (`buildHeader`, `makeTitle`)

---

#### 9. Manager/ViewModel Naming
**Source**: C9
**Priority**: Medium (now covered by CLAUDE-SWIFT)
**Status**: ✅ IMPLEMENTED in CLAUDE-SWIFT.md (2025-11-16)

---

#### 10. Preview Organization
**Source**: F1, F2
**Priority**: Medium
**Difficulty**: Low

**Multiple vs Single**: Context-dependent
- Multiple for different data states/permutations
- Single if variations aren't revealing

**Minimal vs Realistic**: Start minimal, add realism as needed

---

## Low Priority

### SwiftSyntax Rules

#### 11. No Leading Underscores in Properties
**Source**: C6
**Type**: SwiftLint standard rule
**Difficulty**: Low
**Value**: Low (style consistency)

**What**: Flag properties starting with `_`

**User Quote**: "I think I'm ready to say never use underscores for property names"

**Note**: Rare issue, might be better as Skill guidance

---

#### 12. Calculated Constants Must Reference Constants
**Source**: D4
**Type**: SwiftSyntax custom rule
**Difficulty**: Medium
**Value**: Low (niche case)

**What**: Detect when calculated constant uses literals instead of other constants

**Bad**: `static let thirdWidth: CGFloat = 375 / 3`
**Good**: `static let thirdWidth = screenWidth / 3`

**Note**: Fairly niche, Skill guidance might be sufficient

---

### Skill Framework Updates

#### 13. Protocol Conformance Placement
**Source**: E5, E6
**Priority**: Low
**Difficulty**: Low

**Guideline**: Context-dependent
- Main file if tightly coupled
- Extension if logically separate
- Separate file if widely used or complex

---

#### 14. Nested Types Guidelines
**Source**: E7, E8
**Priority**: Low
**Difficulty**: Low

**When to nest**: Scoped enums, small helper types
**When to extract**: Types used beyond parent, complex types

---

#### 15. Preview Content Strategy
**Source**: F3
**Priority**: Low
**Status**: User still developing opinion

**Partial Guidance**: Prefer real objects over mocks when simple

---

#### 16. Preview Naming
**Source**: C10
**Priority**: Low
**Difficulty**: Low

**Options**: Descriptive (`DetailPreview`) vs `#Preview` macro with descriptions

---

#### 17. Binding Naming
**Source**: C11
**Priority**: Low
**Difficulty**: Low

**Guideline**: Match underlying property name (consistency over prefixes)

---

## Already Implemented

### CLAUDE-SWIFT.md Updates
✅ **EmptyView Anti-Pattern** (2025-11-16) - High Priority
✅ **ViewModel Naming Standard** (2025-11-16) - Medium Priority

### Skill Frameworks
✅ **Property Wrapper Line Breaks** (A5, 2025-11-16)
✅ **Pointless Container Anti-Pattern** (B6, 2025-11-15)
✅ **View Extraction Decision Matrix** (E2, 2025-11-15)
✅ **Extension Usage Guidelines** (E4, 2025-11-15)
✅ **Extension File Naming** (E9, 2025-11-15)

---

## Implementation Notes

**SwiftSyntax Rules**:
- Require Swift 6.0 development
- Must integrate with existing swift-quality-tools
- Need comprehensive test cases

**Skill Updates**:
- Add to apple-platform-dev skill under appropriate sections
- Provide examples and rationale
- Link to related rules where applicable

**Next Session (Q1 2025)**:
- Review usage of implemented frameworks
- Refine based on real-world friction
- Add new categories if patterns emerge (SwiftData, Concurrency, Testing)

---

## Reference

**Full Session Archive**: `archive/phase4-alpha/`
- `classification_analysis.md` - Complete analysis with rationale
- `clarifications_resolved.md` - User responses and frameworks
- `preference_discovery_combined.md` - All 52 user responses
- `property_wrapper_examples.md` - Wrapper categorization details
