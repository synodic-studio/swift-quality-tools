# Xcode Setup Guide

## Step-by-Step Xcode Integration

### 1. Open Your Project
- Open `GravityWell.xcodeproj` in Xcode
- Select your app target (not the project)

### 2. Add Build Phase
- Go to your target's **Build Phases** tab
- Click **+** (plus) button at the top left
- Select **New Run Script Phase**

### 3. Configure Run Script Phase
- **Shell**: `/bin/bash`
- **Script**: Copy and paste this exactly:

```bash
source "${SRCROOT}/../swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration/scripts/xcode-integration.sh"
```

### 4. Position the Build Phase
- Drag the "Run Script" phase to be **after** any existing SwiftLint phases
- But **before** "Compile Sources"

### 5. Build Your Project
- Press **⌘+B** to build
- Look for output in the build log:
  - `🔍 Running SwiftSyntax custom rules...`
  - `✅ SwiftSyntax rules check complete`

### 6. Check for Warnings
- Open the **Issue Navigator** (⌘+5)
- Look for warnings like:
  ```
  PhaseControlView.swift:1:1: warning: SwiftSyntax Rule: SwiftUI View body has 27 lines (maximum: 12)
  ```

## Troubleshooting

### No Warnings Appear
1. **Check Build Log**:
   - Look for "Running SwiftSyntax custom rules..." message
   - If missing, the script isn't running

2. **Verify Path**:
   - The script assumes gravity-well and synodic-tools are sibling directories
   - Adjust `SYNODIC_TOOLS_PATH` in the script if different

3. **Check Setup**:
   - Run setup first: `cd swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration && ./scripts/setup.sh`

### "Rule engine not built" Warning
```bash
cd swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration
./scripts/setup.sh
```

### Build Takes Too Long
- First build downloads SwiftSyntax (~30 seconds)
- Subsequent builds are much faster
- Consider using manual scripts during development

## Alternative: Manual Testing

If Xcode integration is problematic, use manual scripts:

```bash
# Check single file
cd swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration
./scripts/check-file.sh ../../gravity-well/GravityWell/Views/PhaseControlView.swift

# Check entire project
./scripts/check-project.sh ../../gravity-well
```

## Build Phase Script Explanation

The script does:
1. **Finds** the SwiftSyntax rule engine
2. **Scans** all Swift files in your project
3. **Runs** the rule on each file
4. **Formats** violations as Xcode warnings
5. **Excludes** build/derived data directories

## Performance Notes

- **First run**: ~30 seconds (downloads SwiftSyntax)
- **Subsequent runs**: ~1-2 seconds for typical projects
- **Large projects**: May take longer but still reasonable

## What the Rule Detects

✅ **Will trigger warning**:
- SwiftUI View `body` with 13+ lines
- Complex nested closures
- Long conditional chains

❌ **Won't trigger**:
- Non-SwiftUI views
- Computed properties
- Empty lines (don't count)
- Opening/closing braces (don't count)