# TODO: Fix view_structure_order Line Numbers in Xcode

## Problem
The `view_structure_order` rule violations always show on line 1 in Xcode, even though the rule engine correctly identifies the actual line numbers of the out-of-order properties.

## Current Behavior
```
/path/to/File.swift:1: warning: [view_structure_order] 'propertyName' (stored property) is out of order...
```

## Expected Behavior
```
/path/to/File.swift:29: warning: [view_structure_order] 'propertyName' (stored property) is out of order...
```

## Investigation Findings

### What Works
1. **Rule engine outputs correct line numbers**
   - Test: `/path/to/test-custom-rule File.swift` shows:
   ```
   ⚠️  [view_structure_order] Line 27: 'freezeFrameManager' ...
   ⚠️  [view_structure_order] Line 29: 'selectedColor' ...
   ⚠️  [view_structure_order] Line 30: 'isAddingNewColor' ...
   ```

2. **Xcode mode format is correct**
   - Test: `XCODE_VERSION_ACTUAL=1600 swiftlintcustom-smart File.swift` shows:
   ```
   /path/File.swift:1: warning: [view_structure_order] ...
   ```
   - Still shows line 1, but the parsing infrastructure is in place

3. **Terminal mode format loses line numbers**
   - Test: `swiftlintcustom-smart File.swift` (without XCODE_VERSION_ACTUAL) shows:
   ```
       • [view_structure_order] 'freezeFrameManager' (stored property) is out of order...
   ```
   - No "Line N:" prefix in terminal output

### The Data Flow Problem

**Current flow:**
1. Rule engine outputs: `⚠️  [view_structure_order] Line 27: 'property' ...`
2. `CustomRulesChecker.parseViolation()` parses → creates `Violation(line: 27, ...)`
3. BUT: `extractLineAndMessage()` regex fails to match "Line 27:" format
4. Falls through to file-level violation case → `Violation(line: 0, ...)`
5. `printTerminalViolations()` outputs without line number for line = 0
6. Shell script (`xcode-lint.sh`) parses terminal output without line numbers
7. Defaults to line 1

**Why the regex fails:**
The regex in `extractLineAndMessage()` looks for:
```swift
#"Line (\d+):?"#
```

But the actual rule engine output has:
```
Line 27: 'freezeFrameManager' ...
```

The issue may be with how the message is extracted after finding the line number. The regex matches, but something in the parsing logic breaks.

## Changes Made (Incomplete)

### 1. ViewStructureRules.swift
- ✅ Added `SourceLocationConverter` parameter
- ✅ Track syntax nodes along with categories
- ✅ Get actual line numbers from converter
- ✅ Format violations as "Line N: message"

### 2. CustomRulesChecker.swift
- ✅ Updated `extractLineAndMessage()` to handle "Line N:" format (with colon)
- ❌ **Parsing still fails** - violations get line = 0

### 3. xcode-lint.sh
- ✅ Shell script can parse "Line N:" format from terminal output
- ❌ **But terminal output doesn't include line numbers** because Violation.line = 0

## Root Cause
The `extractLineAndMessage()` function in `CustomRulesChecker.swift` isn't successfully extracting line numbers from the "Line 27:" format. This causes violations to fall through to the file-level case (line = 0), which makes them appear on line 1 in Xcode.

## Proposed Fix
**Option 1: Debug the regex parsing**
1. Add debug logging to `extractLineAndMessage()`
2. Test with actual violation strings
3. Fix the regex or parsing logic
4. Verify violations get line > 0

**Option 2: Special case view_structure_order**
Since the shell script already parses terminal output, modify terminal format to always include line numbers for all rules (not just line > 0):
```swift
// In printTerminalViolations()
print("    • [\(violation.ruleID)] Line \(violation.line): \(violation.message)")
```

**Option 3: Bypass CustomRulesChecker parsing entirely**
Have the shell script parse the raw rule engine output directly instead of going through the terminal format layer.

## Test Cases to Validate Fix

```bash
# 1. Rule engine outputs line numbers
/path/to/test-custom-rule /path/to/ColorCorrectionControlsPanel.swift | grep view_structure_order
# Should show: Line 27, Line 29, Line 30

# 2. Terminal mode preserves line numbers
swiftlintcustom-smart /path/to/ColorCorrectionControlsPanel.swift | grep view_structure_order
# Should show: Line 27, Line 29, Line 30 (currently doesn't)

# 3. Xcode integration shows correct lines
xcodebuild ... | grep "view_structure_order"
# Should show: :27:, :29:, :30: (currently shows :1:)
```

## Files to Modify
- `Sources/SharedUtilities/CustomRulesChecker.swift` - Fix `extractLineAndMessage()`
- Possibly `Scripts/xcode-lint.sh` - Adjust parsing if needed

## Priority
**Medium** - The warnings work and are clickable, they just take you to line 1 instead of the actual property line. Users can still find the issues, it's just less convenient.
