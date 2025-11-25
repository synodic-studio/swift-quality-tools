# CLAUDE.md

This file provides guidance to Claude Code when working with the swift-quality-tools project.

## Project Overview

Swift Quality Tools is a centralized Swift code quality tooling package with smart configuration discovery. It provides unified interfaces for SwiftFormat, SwiftLint, and custom SwiftSyntax-based rules.

## CRITICAL: Release Mode Required

**ALWAYS build in release mode when making changes to swift-quality-tools:**

```bash
swift build -c release
cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine && swift build -c release
```

**Why:** Xcode build phases in other projects (gravity-well, etc.) reference `.build/release/` binaries. Building in debug mode leaves those binaries stale, causing Xcode to show outdated lint results or no warnings at all.

**Workflow:**
1. Make changes to source code
2. Build in **release** mode (both main package and rule engine)
3. Test with `swiftlintcustom-smart` to verify changes work
4. Commit changes

**Never** return control to the user after modifying swift-quality-tools without building in release mode.

## CRITICAL: Warning Handling Philosophy

**Every warning MUST be addressed - either fixed properly OR exempted with a suppression directive.**

### What "Addressed" Means

1. **Fix it properly** - Make a change that genuinely improves the code
2. **Exempt it explicitly** - Add a `// swiftlintcustom:disable:next rule_id` directive with clear justification

### What Is NOT Acceptable

- **Ignoring warnings** - "These warnings were there before" is NOT an excuse
- **Dismissing warnings** - "The warnings aren't important" is NOT acceptable
- **Committing with warnings** - Every commit should have zero unaddressed warnings
- **Making code worse to silence warnings** - A "fix" that degrades code quality is not a fix

### The Quality Judgment

Before "fixing" a warning, evaluate: **Does this change improve the code or make it worse?**

**Example of a BAD "fix"** (making code worse to silence a warning):
```swift
// Original - clean, readable
@ViewBuilder private var presetButtons: some View {
    if !config.presets.isEmpty {
        HStack {
            ForEach(config.presets.indices, id: \.self) { index in
                presetButton(at: index)
            }
        }
    }
}

// BAD "fix" - cramming code to reduce line count
@ViewBuilder private var presetButtons: some View {
    if !config.presets.isEmpty {
        HStack {
            ForEach(config.presets.indices, id: \.self) { presetButton(at: $0) }
    }
}
```

The "fix" removed readability for no real benefit. This is worse than the original.

**Correct approach**: Either:
1. Refactor genuinely (extract subviews, simplify logic)
2. Add suppression directive if the code is correct as-is

### Decision Framework

```
Warning appears
    │
    ▼
Can I fix it in a way that genuinely improves the code?
    │
    ├── YES → Make the improvement
    │
    └── NO → Is the current code correct/intentional?
                │
                ├── YES → Add suppression directive with justification
                │
                └── NO → The code has a real problem - fix it properly
```

### Suppression Format

```swift
// swiftlintcustom:disable:next rule_id
// Reason: [explain why this is intentional/correct]
```

## Custom SwiftLint Rule Identifiers

**All custom SwiftSyntax rules MUST have unique identifiers** for tracking and future line-level disabling.

### Current Rule Identifiers

- `skimmable_body`: SwiftUI View/ViewModifier body line count limit (15 lines max)
- `no_group_body`: Prohibit Group without modifiers anywhere in SwiftUI code (use @ViewBuilder instead)
- `one_top_level_view`: Enforce single top-level view in View bodies (if/else counts as one statement)
- `no_if_modifier`: Detect custom `.if` modifier anti-pattern (use ternary or @ViewBuilder instead)
- `excessive_nesting`: AST-based nesting depth limit (max depth 3, triggers at depth 4+, tracks both closures and code blocks)
- `stack_minimum_children`: VStack/HStack/ZStack must have at least 2 children (ForEach allowed; if/else allowed if any branch has 2+ views)
- `onchange_ignored_old_value`: Use 0-parameter onChange when old value is ignored (cleaner than 2-param with `_`)
- `constants_enum_usage`: Detect magic numbers, suggest Constants enum (DISABLED - too noisy)

### Violation Format

All violations follow this format:
```
⚠️ [rule_identifier] Violation description
```

Examples:
```
⚠️ [excessive_nesting] Line 42 has excessive nesting (level 4, maximum: 3) - refactor code to reduce nesting depth
⚠️ [onchange_ignored_old_value] Use 0-parameter onChange when old value is ignored - replace '{ _, newValue in ...' with '{ ... }' and reference the observed value directly
```

### Adding New Rules

When adding a new custom rule:

1. **Choose identifier**: Use descriptive snake_case (e.g., `enforce_final_classes`)
2. **Document here**: Add to the list above with description
3. **Update README**: Add to Custom Rules section in README.md
4. **Use consistent format**: All violations must use `⚠️ [identifier] message` format
5. **Update rule engine docs**: Add to class documentation in test-custom-rule.swift

### Future: Line-Level Disabling

The rule identifiers enable future support for line-level disabling:
```swift
// swiftlint:disable:next excessive_nesting
func deeplyNested() {
    // Complex but necessary nesting...
}
```

Currently not implemented, but identifiers are in place for when we add this feature.

## Development

### Building

```bash
# Build all tools
./Scripts/build-all.sh

# Or manually
swift build -c release
cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine && swift build
```

### Testing Custom Rules

```bash
# Test on a specific file
swiftlintcustom-smart path/to/File.swift

# Test on a directory
swiftlintcustom-smart path/to/directory
```

### Modifying Custom Rules

Custom rules are in:
```
CustomRules/swiftlint-swiftsyntax-integration/rule-engine/test-custom-rule.swift
```

After modifying:
1. Rebuild the rule engine: `cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine && swift build`
2. Test on sample code
3. Update documentation in this file and README.md
4. Commit with clear rule identifier in message

## Architecture

- **Main tools**: `swiftformat-smart`, `swiftlint-smart`, `swiftlintcustom-smart`
- **Config discovery**: Automatic discovery with fallback to shared configs
- **Custom rules**: SwiftSyntax-based, separate rule engine in CustomRules/
- **Shared configs**: Configs/ directory contains shared SwiftFormat and SwiftLint configurations
