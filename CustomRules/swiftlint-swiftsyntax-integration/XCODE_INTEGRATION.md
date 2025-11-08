# Xcode Integration for SwiftSyntax Rules

## Quick Setup

### Step 1: Update Your Run Script Phase
Replace the content of your existing run script phase with the contents of `xcode-swiftlint-simple.sh`:

```bash
#!/bin/bash

# Simple Xcode Run Script Phase for Custom SwiftSyntax Rules
# This version uses our existing test infrastructure

# Path to synodic-tools (adjust if needed)
SYNODIC_TOOLS_PATH="${SRCROOT}/../synodic-tools"

# Check if synodic-tools exists
if [ ! -d "$SYNODIC_TOOLS_PATH" ]; then
    echo "warning: synodic-tools not found at $SYNODIC_TOOLS_PATH"
    exit 0
fi

# Check if our test script exists
if [ ! -f "$SYNODIC_TOOLS_PATH/swiftlint-tests/test-swiftsyntax-rule.sh" ]; then
    echo "warning: SwiftSyntax rule test script not found"
    exit 0
fi

echo "🔍 Running custom SwiftSyntax rules..."

# Function to check a single file and format output for Xcode
check_file() {
    local file_path="$1"
    local relative_path="${file_path#./}"
    
    # Run our test script on the file
    local temp_output=$(mktemp)
    
    # Modify our test script to work with single files
    cd "$SYNODIC_TOOLS_PATH"
    
    # Create temporary package and build if needed
    if [ ! -f ".build/debug/test-custom-rule" ]; then
        echo "Building SwiftSyntax rule (one-time setup)..."
        cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftLintTest",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .executableTarget(
            name: "test-custom-rule",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: ".",
            sources: ["test-custom-rule.swift"]
        )
    ]
)
EOF
        
        swift build > /dev/null 2>&1
        rm -f Package.swift Package.resolved
    fi
    
    # Run the rule
    if [ -f ".build/debug/test-custom-rule" ]; then
        local output=$(.build/debug/test-custom-rule "$file_path" 2>/dev/null)
        local violation=$(echo "$output" | grep "⚠️" | head -1)
        
        if [ -n "$violation" ]; then
            echo "$relative_path:1:1: warning: Custom SwiftSyntax Rule: $violation"
        fi
    fi
    
    cd "$SRCROOT"
    rm -f "$temp_output"
}

# Find all Swift files and check them
find . -name "*.swift" -type f -not -path "./build/*" -not -path "./.build/*" -not -path "./DerivedData/*" | while read -r file; do
    check_file "$file"
done

echo "✅ Custom SwiftSyntax rules check complete"
```

### Step 2: Build Phase Configuration

**Recommended Setup**:
1. **Keep SwiftLintPlugins** in "Run Build Tool Plug-ins" (for standard SwiftLint rules)
2. **Add Custom SwiftSyntax Script** in "Run Script" phase

**Build Phase Order**:
1. SwiftLintPlugins (Run Build Tool Plug-ins)
2. Custom SwiftSyntax Script (Run Script)
3. Compile Sources

### Step 3: Expected Output

After building, you should see in the build log:
- Standard SwiftLint warnings from the plugin
- Custom SwiftSyntax warnings like:
  ```
  GravityWell/Views/PhaseControlView.swift:1:1: warning: Custom SwiftSyntax Rule: ⚠️ SwiftUI View body has 27 lines (maximum: 10)
  ```

## Performance Notes

- **First build**: Takes ~30 seconds to download and build SwiftSyntax
- **Subsequent builds**: Only a few seconds to run the rules
- **Incremental builds**: Only checks files that exist (no rebuild needed)

## Troubleshooting

### No Warnings Appearing
1. Check build logs for "Building SwiftSyntax rule" message
2. Verify synodic-tools path is correct
3. Ensure the run script phase is before "Compile Sources"

### Build Taking Too Long
1. The first build downloads SwiftSyntax (~30 seconds)
2. Subsequent builds should be much faster
3. Consider using Option 1 (CLI wrapper) for development

### Path Issues
- The script assumes gravity-well and synodic-tools are sibling directories
- Adjust `SYNODIC_TOOLS_PATH` if your structure is different

## Alternative: CLI Wrapper

For development, you might prefer the CLI wrapper:
```bash
# In your gravity-well directory
ln -s ../synodic-tools/swiftlint-custom ./swiftlint-custom
./swiftlint-custom
```

This gives you both standard SwiftLint and custom SwiftSyntax rules without Xcode integration complexity.