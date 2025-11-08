#!/bin/bash

# Xcode Run Script Phase for Custom SwiftSyntax Rules
# Add this as a "Run Script" build phase in Xcode
# Note: Keep SwiftLintPlugins for standard SwiftLint rules

# Path to synodic-tools (adjust if needed)
SYNODIC_TOOLS_PATH="${SRCROOT}/../synodic-tools"

echo "🔍 Running custom SwiftSyntax rules..."

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

# Function to run custom rule on a file and format for Xcode
check_file() {
    local file_path="$1"
    local relative_path="${file_path#./}"
    
    # Run the test and capture output
    local output=$("$SYNODIC_TOOLS_PATH/swiftlint-tests/test-swiftsyntax-rule.sh" "$file_path" 2>&1)
    
    # Extract violation information
    local violation=$(echo "$output" | grep "⚠️" | head -1)
    
    if [ -n "$violation" ]; then
        # Format as Xcode warning
        echo "${relative_path}:1:1: warning: Custom SwiftSyntax Rule: ${violation}"
    fi
}

# Export function so it can be used in subshells
export -f check_file
export SYNODIC_TOOLS_PATH

# Find and check all Swift files
find . -name "*.swift" -type f -not -path "./build/*" -not -path "./.build/*" | while read -r file; do
    check_file "$file"
done

echo "✅ Custom SwiftSyntax rules check complete"