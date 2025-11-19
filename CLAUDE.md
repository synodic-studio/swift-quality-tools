# CLAUDE.md

This file provides guidance to Claude Code when working with the swift-quality-tools project.

## Project Overview

Swift Quality Tools is a centralized Swift code quality tooling package with smart configuration discovery. It provides unified interfaces for SwiftFormat, SwiftLint, and custom SwiftSyntax-based rules.

## Custom SwiftLint Rule Identifiers

**All custom SwiftSyntax rules MUST have unique identifiers** for tracking and future line-level disabling.

### Current Rule Identifiers

- `skimmable_body`: SwiftUI View body line count limit (15 lines max)
- `no_group_body`: Prohibit Group without modifiers anywhere in SwiftUI code (use @ViewBuilder instead)
- `one_top_level_view`: Enforce single top-level view in View bodies (if/else counts as one statement)
- `no_if_modifier`: Detect custom `.if` modifier anti-pattern (use ternary or @ViewBuilder instead)
- `excessive_nesting`: AST-based nesting depth limit (3 levels max - allows modifier chains up to 16 spaces)
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
