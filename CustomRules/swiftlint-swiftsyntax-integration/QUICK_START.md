# Quick Start Guide

## ✅ Everything is Ready to Use!

The SwiftSyntax rule integration is **completely set up** and **working**. Here's how to use it:

## 🚀 Test That It Works

```bash
# Go to the integration directory
cd swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration

# Test on a single file
./scripts/check-file.sh ../../gravity-well/GravityWell/Views/PhaseControlView.swift

# Test on entire project
./scripts/check-project.sh ../../gravity-well
```

**Expected output:**
```
🔍 Checking PhaseControlView.swift for SwiftSyntax rule violations...
⚠️ SwiftUI View body has 27 lines (maximum: 15)
Found 1 violation(s)
✅ Check completed
```

## 🎯 Add to Xcode Project

### Simple Copy-Paste Method:

1. **Open GravityWell.xcodeproj**
2. **Go to Target → Build Phases**
3. **Add "New Run Script Phase"**
4. **Set Shell:** `/bin/bash`
5. **Copy this script exactly:**

```bash
source "${SRCROOT}/../swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration/scripts/xcode-integration.sh"
```

6. **Build your project** (⌘+B)
7. **Check Issue Navigator** (⌘+5) for warnings

## 📁 What You Have

```
swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration/
├── README.md              # Comprehensive documentation
├── QUICK_START.md         # This file
├── XCODE_SETUP_GUIDE.md   # Detailed Xcode setup
├── DIRECTORY_STRUCTURE.md # Organization guide
├── SWIFTSYNTAX_RULES.md   # Technical details
├── XCODE_INTEGRATION.md   # Integration patterns
├── CLEANUP_SUMMARY.md     # Organization history
├── scripts/               # ✅ Production scripts
│   ├── setup.sh           # ✅ Already run
│   ├── check-file.sh      # ✅ Test single file
│   ├── check-project.sh   # ✅ Test entire project
│   └── xcode-integration.sh # ✅ Xcode script
├── rule-engine/           # ✅ Built and working
├── examples/              # ✅ Sample usage
└── legacy-files/          # 📦 Experimental/deprecated files
```

## 💡 What the Rule Does

**Detects:** SwiftUI View bodies with more than 15 lines
**Suggests:** Breaking large bodies into computed properties

**Example violation:**
```swift
var body: some View {
    VStack {
        Text("Line 1")
        Text("Line 2")
        // ... 25 more lines
    }
}
```

**Suggested fix:**
```swift
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}

private var headerView: some View {
    // Complex header logic
}
```

## 🔧 Troubleshooting

### "Rule engine not built" error
```bash
cd swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration
./scripts/setup.sh
```

### No warnings in Xcode
- Check build log for "Running SwiftSyntax custom rules..." message
- Verify script path matches your directory structure
- Try manual script first to confirm it works

### Path issues
- Scripts assume `gravity-well` and `synodic-tools` are siblings
- Adjust paths in scripts if your structure is different

## 🎉 Success!

You now have:
- ✅ Working SwiftSyntax rule engine
- ✅ Command-line scripts for testing
- ✅ Xcode integration ready
- ✅ Comprehensive documentation

The rule correctly detects that PhaseControlView has 27 lines (violating the 10-line limit) and provides clear output for both manual testing and Xcode integration.