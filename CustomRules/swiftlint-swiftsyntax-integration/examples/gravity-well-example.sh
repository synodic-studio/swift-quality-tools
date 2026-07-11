#!/bin/bash

# Example: Check GravityWell project for SwiftSyntax rule violations
# This shows how to use the integration with your actual project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🎯 GravityWell Project Example"
echo "=============================="

# Check if GravityWell exists
if [ ! -d "../../../gravity-well" ]; then
    echo "❌ GravityWell project not found at ../../../gravity-well"
    echo "💡 Adjust the path in this script to match your project location"
    exit 1
fi

echo "🔍 Checking specific file (PhaseControlView.swift)..."
"$PROJECT_DIR/scripts/check-file.sh" "../../../gravity-well/GravityWell/Views/PhaseControlView.swift"

echo ""
echo "🔍 Checking entire GravityWell project..."
"$PROJECT_DIR/scripts/check-project.sh" "../../../gravity-well"

echo ""
echo "💡 To integrate with Xcode:"
echo "1. Open GravityWell.xcodeproj"
echo "2. Go to Target → Build Phases"
echo "3. Add 'New Run Script Phase'"
echo "4. Set Shell: /bin/bash"
echo "5. Script content:"
echo "   source \"\${SRCROOT}/../swiftskim/CustomRules/swiftlint-swiftsyntax-integration/scripts/xcode-integration.sh\""