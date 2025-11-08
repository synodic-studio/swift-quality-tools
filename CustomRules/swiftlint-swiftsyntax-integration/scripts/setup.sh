#!/bin/bash

# One-time setup script for SwiftSyntax rules
# This builds the rule engine and prepares everything for use

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔧 Setting up SwiftSyntax rules..."
echo "📁 Project directory: $PROJECT_DIR"

# Go to rule engine directory
cd "$PROJECT_DIR/rule-engine"

# Check if already built
if [ -f ".build/debug/test-custom-rule" ]; then
    echo "✅ Rule engine already built"
else
    echo "🏗️  Building rule engine (this may take ~30 seconds)..."
    swift build
    echo "✅ Rule engine built successfully"
fi

# Test that it works
echo "🧪 Testing rule engine..."
if [ -f ".build/debug/test-custom-rule" ]; then
    echo "✅ Rule engine is ready"
    
    # Test with a sample file if available
    if [ -f "../../../gravity-well/GravityWell/Views/PhaseControlView.swift" ]; then
        echo "🔍 Testing with PhaseControlView.swift..."
        .build/debug/test-custom-rule "../../../gravity-well/GravityWell/Views/PhaseControlView.swift"
        echo "✅ Test completed successfully"
    fi
else
    echo "❌ Rule engine build failed"
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "1. Test single file: ./scripts/check-file.sh path/to/your-file.swift"
echo "2. Test entire project: ./scripts/check-project.sh path/to/your-project"
echo "3. Add to Xcode: Copy contents of scripts/xcode-integration.sh"