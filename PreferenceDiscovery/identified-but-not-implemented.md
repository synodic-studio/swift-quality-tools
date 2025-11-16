# Identified But Not Implemented

**Source**: Phase 4 Alpha preference discovery session (2025-11-15 to 2025-11-16)
**Full Analysis**: See `archive/phase4-alpha/classification_analysis.md` for complete rationale

This document tracks preferences identified during systematic edge case review but not yet implemented in SwiftSyntax rules or apple-platform-dev skill.

---

## High Priority

### SwiftSyntax Rules

#### 1. ViewModifier Body Line Limit
**Source**: B3
**Type**: Extend existing `skimmable_body` rule
**Difficulty**: Low

**What**: Apply same 15-line limit to `func body(content: Content) -> some View` in ViewModifier

**Why**: Consistency - View body is limited, ViewModifier body should be too

**Implementation**: Modify `skimmable_body` to detect ViewModifier protocol conformance

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
