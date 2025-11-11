#!/bin/bash

# Xcode Run Script Phase for SwiftSyntax Rules
# 
# SETUP INSTRUCTIONS:
# 1. In Xcode, go to your target → Build Phases
# 2. Add "New Run Script Phase"
# 3. Set Shell: /bin/bash
# 4. Add this script content:
#    source /path/to/swift-quality-tools/CustomRules/swiftlint-swiftsyntax-integration/scripts/xcode-integration.sh
# 5. Adjust SYNODIC_TOOLS_PATH below if needed

# Path to your synodic-tools directory
SYNODIC_TOOLS_PATH="${SRCROOT}/../synodic-tools"

# Path to the SwiftSyntax integration
INTEGRATION_PATH="$SYNODIC_TOOLS_PATH/swiftlint-swiftsyntax-integration"
RULE_ENGINE="$INTEGRATION_PATH/rule-engine/.build/debug/test-custom-rule"

echo "🔍 Running SwiftSyntax custom rules..."

# Check if integration directory exists
if [ ! -d "$INTEGRATION_PATH" ]; then
    echo "warning: SwiftSyntax integration not found at $INTEGRATION_PATH"
    echo "warning: Run setup first: cd $SYNODIC_TOOLS_PATH/swiftlint-swiftsyntax-integration && ./scripts/setup.sh"
    exit 0
fi

# Check if rule engine is built
if [ ! -f "$RULE_ENGINE" ]; then
    echo "warning: Rule engine not built. Run setup first."
    exit 0
fi

# Function to check a file and format for Xcode
check_file() {
    local file_path="$1"
    local relative_path="${file_path#./}"
    
    # Run the rule engine
    local output=$("$RULE_ENGINE" "$file_path" 2>&1)
    
    # Extract violations and format for Xcode
    if echo "$output" | grep -q "⚠️"; then
        local violation=$(echo "$output" | grep "⚠️" | head -1 | sed 's/⚠️ //')
        echo "${relative_path}:1:1: warning: SwiftSyntax Rule: ${violation}"
    fi
}

# Find and check all Swift files
find . -name "*.swift" -type f -not -path "./build/*" -not -path "./.build/*" -not -path "*/DerivedData/*" | while read -r file; do
    check_file "$file"
done

echo "✅ SwiftSyntax rules check complete"