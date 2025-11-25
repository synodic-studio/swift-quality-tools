# SwiftLintCustom Directive Support

## Overview

The custom SwiftLint rules now support suppression directives using the `swiftlintcustom:` prefix. This allows you to selectively disable custom rules for specific lines without interfering with standard SwiftLint directives.

## Supported Directives

### ✅ Implemented

#### `swiftlintcustom:disable:next rule_name`
Disables the specified custom rule for the **next line** only.

```swift
// swiftlintcustom:disable:next excessive_nesting
var computed: String {
    if true {
        if true {
            if true {
                if true {  // This violation is suppressed
                    return "deep"
                }
            }
        }
    }
    return ""
}
```

**Note:** The directive applies to the immediately following line. In the example above, the violation occurs on the 4th `if true {` statement, NOT on the `var computed` line. To suppress violations within a function/property body, you may need to use multiple `disable:next` directives or consider restructuring the code.

#### `swiftlintcustom:disable:this rule_name`
Disables the specified custom rule for the **current line** (inline directive).

```swift
func deeplyNested() { // swiftlintcustom:disable:this excessive_nesting
    if true {
        if true {
            if true {
                if true {  // This violation is suppressed
                    print("deep")
                }
            }
        }
    }
}
```

#### Multiple Rules
You can suppress multiple custom rules in a single directive:

```swift
// swiftlintcustom:disable:next excessive_nesting skimmable_body
var body: some View {
    // Complex but necessary implementation
}
```

### ❌ Not Yet Implemented

#### File-Level Directives
File-level `swiftlintcustom:disable` and `swiftlintcustom:enable` directives are not yet supported.

```swift
// ❌ This doesn't work yet
// swiftlintcustom:disable excessive_nesting

func deeplyNested1() {
    // ...deep nesting...
}

func deeplyNested2() {
    // ...deep nesting...
}

// swiftlintcustom:enable excessive_nesting
```

**Workaround:** Use line-specific directives for each violation, or consider refactoring to comply with the rule.

**Tracking:** This feature is planned for a future update and requires range-tracking implementation.

## Available Rule Identifiers

All custom rules can be suppressed using their identifier:

- `skimmable_body` - View body line count limit (max 15 lines)
- `no_group_body` - Prohibit Group without modifiers
- `one_top_level_view` - Enforce single top-level view in View bodies
- `no_if_modifier` - Detect custom .if modifier anti-pattern
- `excessive_nesting` - AST-based nesting depth limit (max 3 levels)
- `view_structure_order` - Enforce View property ordering
- `no_wrapper_body` - Detect pointless wrapper body properties
- `blank_line_import_separation` - Enforce blank line between regular and @testable imports
- `preview_required` - Every file with View/ViewModifier must have at least one #Preview
- `stack_minimum_children` - Stacks must have at least 2 children
- `prefer_zero_param_onchange` - Use 0-param onChange when old value is ignored

## Usage Examples

### Suppress Single Violation

```swift
// swiftlintcustom:disable:next skimmable_body
var body: some View {
    VStack {
        // More than 15 lines but necessary for this specific view
        Text("Line 1")
        Text("Line 2")
        // ... many more lines ...
    }
}
```

### Suppress Multiple Rules

```swift
// swiftlintcustom:disable:next excessive_nesting skimmable_body view_structure_order
var complexBody: some View {
    // Complex implementation that intentionally violates multiple rules
}
```

### Inline Suppression

```swift
Group { /* content */ } // swiftlintcustom:disable:this no_group_body
```

## Implementation Details

### Architecture

- **DirectiveParser**: Scans source code for SwiftLint directives in comments
- **CustomRulesVisitor**: Filters violations based on parsed directives
- **Violation Filtering**: Occurs in `getViolations()` method after all rules have run

### Parsing Logic

1. Source code is scanned line-by-line during visitor initialization
2. Directives are extracted from comments starting with `//`
3. Rule names are extracted and mapped to line numbers
4. During violation reporting, each violation is checked against suppression rules
5. Suppressed violations are filtered out before returning to the user

### Limitations

1. **File-level directives not supported** - Only line-specific (`:next` and `:this`) work
2. **Directive must be on its own line or inline** - Cannot be mixed with code on same line (except `:this`)
3. **Case-sensitive rule names** - Must match exact rule identifier
4. **No wildcard support** - Cannot disable all rules with `swiftlint:disable all`

## Testing

Comprehensive tests are located in `Tests/SharedUtilitiesTests/DirectiveParserTests.swift`.

To test directive support:

```bash
# Create a test Swift file with directives
echo '// swiftlintcustom:disable:next excessive_nesting
func test() {
    if true { if true { if true { if true { print("deep") } } } }
}' > test.swift

# Run custom linter
swiftlintcustom-smart test.swift

# Should show NO violations (all suppressed)
```

## Future Enhancements

### Planned

1. **File-level directive support** - Implement range tracking for `swiftlintcustom:disable` / `swiftlintcustom:enable`
2. **Disable all rules** - Support `swiftlintcustom:disable all` syntax
3. **Configuration file integration** - Allow disabling rules globally in config files
4. **Better error messages** - Warn about unknown rule identifiers in directives

### Under Consideration

1. **Region-based suppression** - Suppress rules for specific code regions
2. **Automatic suppression suggestions** - IDE integration to suggest directives for violations
3. **Directive validation** - Warn about unused or ineffective directives

## Using with Standard SwiftLint

Custom rules use the `swiftlintcustom:` prefix to avoid conflicts with standard SwiftLint:

1. **Use `swiftlint:` for standard rules** - e.g., `// swiftlint:disable:next line_length`
2. **Use `swiftlintcustom:` for custom rules** - e.g., `// swiftlintcustom:disable:next excessive_nesting`
3. **No conflicts** - Standard SwiftLint won't complain about custom rule names
4. **Clean separation** - Makes it clear which linter each directive targets

## Troubleshooting

### Directive Not Working?

1. **Check rule identifier** - Ensure exact match with rule ID (case-sensitive)
2. **Check directive syntax** - Must start with `//` and have correct format
3. **Check line placement** - `:next` affects next line, `:this` affects current line
4. **Check for file-level directive** - Not yet supported, use line-specific instead

### Common Mistakes

```swift
// ❌ Wrong: File-level not supported
// swiftlintcustom:disable excessive_nesting
func deep() { ... }

// ✅ Correct: Use line-specific
// swiftlintcustom:disable:next excessive_nesting
func deep() { ... }

// ❌ Wrong: Using swiftlint prefix for custom rules
// swiftlint:disable:next excessive_nesting

// ✅ Correct: Use swiftlintcustom prefix
// swiftlintcustom:disable:next excessive_nesting

// ❌ Wrong: Typo in rule name
// swiftlintcustom:disable:next excessive-nesting

// ✅ Correct: Exact rule identifier
// swiftlintcustom:disable:next excessive_nesting

// ❌ Wrong: disable:next too far from violation
// swiftlintcustom:disable:next excessive_nesting
func deep() {
    // ... many lines ...
    if true { if true { if true { if true { ... }}}} // Not suppressed!
}

// ✅ Correct: Inline suppression on violating line
func deep() {
    if true { if true { if true {
        if true { ... } // swiftlintcustom:disable:this excessive_nesting
    }}}
}
```

## Contributing

To add support for file-level directives:

1. Implement range tracking in `DirectiveParser`
2. Track disable/enable line numbers for each rule
3. Update `isSuppressed()` to check if line falls within disabled range
4. Add comprehensive tests for range logic
5. Update this documentation

See `docs/TODO-file-level-directives.md` for implementation plan.
