#!/bin/bash

# Check a single Swift file for SwiftSyntax rule violations
# Usage: ./check-file.sh path/to/YourView.swift

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RULE_ENGINE="$PROJECT_DIR/rule-engine/.build/debug/test-custom-rule"

# Check if rule engine is built
if [ ! -f "$RULE_ENGINE" ]; then
    echo "❌ Rule engine not built. Run ./scripts/setup.sh first"
    exit 1
fi

# Check if file provided
if [ $# -eq 0 ]; then
    echo "Usage: ./check-file.sh <path/to/file.swift>"
    echo ""
    echo "Examples:"
    echo "  ./check-file.sh ../../gravity-well/GravityWell/Views/PhaseControlView.swift"
    echo "  ./check-file.sh ../swiftlint-tests/test-skimmable-body.swift"
    exit 1
fi

# Check if file exists
if [ ! -f "$1" ]; then
    echo "❌ File not found: $1"
    exit 1
fi

echo "🔍 Checking $(basename "$1") for SwiftSyntax rule violations..."
"$RULE_ENGINE" "$1"

exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "✅ Check completed"
else
    echo "❌ Check failed"
fi

exit $exit_code