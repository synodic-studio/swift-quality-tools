#!/bin/bash

# Fast Xcode Run Script Phase for Custom SwiftSyntax Rules
# This version compiles the rule once and reuses it

# Path to synodic-tools (adjust if needed)
SYNODIC_TOOLS_PATH="${SRCROOT}/../synodic-tools"

# Check if synodic-tools exists
if [ ! -d "$SYNODIC_TOOLS_PATH" ]; then
    echo "warning: synodic-tools not found at $SYNODIC_TOOLS_PATH"
    exit 0
fi

# Check if our direct script exists
if [ ! -f "$SYNODIC_TOOLS_PATH/check-swiftsyntax-rules.swift" ]; then
    echo "warning: SwiftSyntax rule script not found"
    exit 0
fi

echo "🔍 Running custom SwiftSyntax rules..."

# Build the rule once if needed
cd "$SYNODIC_TOOLS_PATH"
if [ ! -f ".build/debug/check-swiftsyntax-rules" ] || [ "check-swiftsyntax-rules.swift" -nt ".build/debug/check-swiftsyntax-rules" ]; then
    echo "Building SwiftSyntax rule..."
    
    # Create Package.swift for our rule
    cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "CheckSwiftSyntaxRules",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .executableTarget(
            name: "check-swiftsyntax-rules",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: ".",
            sources: ["check-swiftsyntax-rules.swift"]
        )
    ]
)
EOF
    
    swift build -c release > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        echo "warning: Failed to build SwiftSyntax rule"
        rm -f Package.swift Package.resolved
        exit 0
    fi
    
    rm -f Package.swift Package.resolved
fi

# Go back to project directory
cd "$SRCROOT"

# Run the rule on all Swift files
find . -name "*.swift" -type f -not -path "./build/*" -not -path "./.build/*" -not -path "./DerivedData/*" | while read -r file; do
    "$SYNODIC_TOOLS_PATH/.build/release/check-swiftsyntax-rules" "$file"
done

echo "✅ Custom SwiftSyntax rules check complete"