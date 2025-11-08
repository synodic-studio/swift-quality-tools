# SwiftSyntax-Based Custom Rules

This document describes the SwiftSyntax-based custom rule implementation that replaces the performance-problematic regex-based rules.

## Problem

The original regex-based `skimmable_body` rule in SwiftLint was causing performance issues due to catastrophic backtracking with complex patterns.

## Solution

Implemented a SwiftSyntax-based rule that:
- Parses Swift code into an Abstract Syntax Tree (AST)
- Accurately identifies SwiftUI View body properties
- Counts logical lines within the body
- Provides precise violation reporting

## Files Created

- `test-custom-rule.swift` - Standalone SwiftSyntax rule implementation
- `swiftlint-tests/test-swiftsyntax-rule.sh` - Test runner script
- `swiftlint_extra_rules/` - Full Bazel-based integration (optional)

## Usage

### Quick Test (Recommended)
```bash
./swiftlint-tests/test-swiftsyntax-rule.sh
```

This script:
1. Creates a temporary Swift Package with SwiftSyntax dependency
2. Builds the custom rule
3. Tests it against `test-skimmable-body.swift`
4. Cleans up afterward

### Results
The test correctly identifies violations:
- `ViolatingView1`: 13 lines (triggers warning)
- `ViolatingView2`: 12 lines (triggers warning)
- `ValidView1`: 9 lines (no violation)
- `ValidView2`: Uses computed properties (no violation)

## Benefits

1. **Performance**: No regex backtracking issues
2. **Accuracy**: Proper Swift syntax parsing
3. **Maintainability**: Clear Swift code instead of complex regex
4. **Extensibility**: Easy to add more sophisticated rules

## Integration Options

1. **Standalone Testing**: Use the test script for validation
2. **Bazel Integration**: Full SwiftLint custom binary (more complex setup)
3. **Future**: Wait for SwiftLint to support SwiftSyntax rules natively

## Next Steps

The regex-based rules in `shared-swiftlint.yml` are commented out. The SwiftSyntax-based implementation is ready for use via the test script until a full integration solution is available.