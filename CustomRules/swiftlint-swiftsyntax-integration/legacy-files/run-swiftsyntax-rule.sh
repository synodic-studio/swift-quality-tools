#!/bin/bash

# Simple script to run SwiftSyntax rule on files
# Usage: ./run-swiftsyntax-rule.sh <file.swift>

# Check if temp-test build exists
if [ ! -f "temp-test/.build/debug/test-custom-rule" ]; then
    echo "Building SwiftSyntax rule..."
    cd temp-test
    swift build > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ Build failed"
        exit 1
    fi
    cd ..
    echo "✅ Build complete"
fi

# Run the rule
if [ $# -eq 0 ]; then
    echo "Usage: ./run-swiftsyntax-rule.sh <file.swift>"
    echo "Example: ./run-swiftsyntax-rule.sh ../gravity-well/GravityWell/Views/PhaseControlView.swift"
    exit 1
fi

echo "🔍 Checking $1 for SwiftSyntax rule violations..."
temp-test/.build/debug/test-custom-rule "$1"