# SwiftLint SwiftSyntax Integration

This directory contains a complete working solution for integrating SwiftSyntax-based custom rules into your Xcode projects.

## 📁 Directory Structure

```
swiftlint-swiftsyntax-integration/
├── README.md                    # This file
├── QUICK_START.md               # Getting started guide
├── XCODE_SETUP_GUIDE.md         # Detailed Xcode integration
├── DIRECTORY_STRUCTURE.md       # Directory organization
├── SWIFTSYNTAX_RULES.md         # Technical implementation details
├── XCODE_INTEGRATION.md         # Integration patterns and options
├── CLEANUP_SUMMARY.md           # Organization history
├── rule-engine/                 # The core SwiftSyntax rule implementation
│   ├── Package.swift            # Swift Package Manager configuration
│   ├── test-custom-rule.swift   # SwiftSyntax rule implementation
│   └── .build/                  # Built executable (after running setup)
├── scripts/                     # Integration scripts
│   ├── setup.sh                 # One-time setup script
│   ├── check-file.sh            # Check single file
│   ├── check-project.sh         # Check entire project
│   └── xcode-integration.sh     # Xcode build phase script
├── examples/                    # Example configurations
│   ├── gravity-well-example.sh  # Example for GravityWell project
│   └── sample-output.txt        # Example output
└── legacy-files/                # Deprecated/experimental files
    ├── README.md                # Legacy file documentation
    ├── swiftlint_extra_rules/   # Bazel-based implementation
    └── *.sh, *.swift            # Alternative implementations
```

## 🚀 Quick Start

### 1. One-Time Setup
```bash
cd swiftlint-swiftsyntax-integration
./scripts/setup.sh
```

### 2. Test It Works
```bash
./scripts/check-file.sh ../../gravity-well/GravityWell/Views/PhaseControlView.swift
```

### 3. Check Entire Project
```bash
./scripts/check-project.sh ../../gravity-well
```

### 4. Add to Xcode (Optional)
- Copy contents of `scripts/xcode-integration.sh`
- Add as "Run Script" build phase in Xcode
- Adjust path to point to this directory

## 🔧 How It Works

1. **SwiftSyntax Parser**: Parses Swift files into Abstract Syntax Tree (AST)
2. **Rule Engine**: Visits AST nodes to find SwiftUI View body properties
3. **Line Counting**: Accurately counts logical lines (excluding braces, empty lines)
4. **Violation Detection**: Reports bodies with more than 15 lines

## 📋 What Gets Detected

**✅ Will Trigger Warning:**
- SwiftUI View body with 13+ lines of content
- Nested closures, conditionals, loops count as separate lines
- Comments within body count as lines

**❌ Won't Trigger:**
- Opening/closing braces don't count
- Empty lines don't count
- Computed properties that extract body logic
- Non-SwiftUI View bodies

## 🎯 Example Output

```
🔍 Checking PhaseControlView.swift...
⚠️ SwiftUI View body has 27 lines (maximum: 15)
Found 1 violation(s)

💡 Suggestion: Extract complex logic into computed properties:
   var body: some View {
       VStack {
           headerView
           contentView
           footerView
       }
   }
```

## 🔍 Troubleshooting

### "No such file or directory" errors
- Run `./scripts/setup.sh` first
- Ensure you're in the correct directory

### "Build failed" errors
- Check internet connection (downloads SwiftSyntax)
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`

### No violations found when expected
- Verify the file contains `var body: some View`
- Check that it's actually a SwiftUI View (not UIKit)

## 🏗️ Integration Options

### Option A: Manual Script (Recommended for Learning)
```bash
# Check specific file
./scripts/check-file.sh path/to/YourView.swift

# Check entire project
./scripts/check-project.sh path/to/your-project
```

### Option B: Xcode Integration
1. Add "Run Script" build phase
2. Set shell: `/bin/bash`
3. Script content: `source /path/to/swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration/scripts/xcode-integration.sh`

### Option C: Git Hook
```bash
# Install pre-commit hook (using legacy file)
cp legacy-files/git-pre-commit-hook /path/to/your-project/.git/hooks/pre-commit
chmod +x /path/to/your-project/.git/hooks/pre-commit
```

## 📚 Technical Details

- **Language**: Swift with SwiftSyntax library
- **Performance**: ~30 seconds first build, <1 second subsequent runs
- **Dependencies**: Swift Package Manager, SwiftSyntax 509.x
- **Compatibility**: macOS 12+, Xcode 14+

## 🔄 Maintenance

- **Updates**: Run `./scripts/setup.sh` to rebuild after changes
- **Clean**: Delete `rule-engine/.build` to force rebuild
- **Extend**: Modify `rule-engine/test-custom-rule.swift` to add new rules