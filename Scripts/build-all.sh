#!/bin/bash
# Build script for swift-quality-tools
# Builds main package and custom rule engine with self-healing error messages

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RULE_ENGINE_DIR="$PROJECT_ROOT/CustomRules/swiftlint-swiftsyntax-integration/rule-engine"

echo "🔨 Building swift-quality-tools"
echo ""

# Build main package. Build the wrapper executables explicitly so the on-demand
# SwiftSkim library product (which pulls SwiftSyntax) isn't compiled here — the
# rule engine below already builds SwiftSyntax.
echo "📦 Building main package (release mode)..."
cd "$PROJECT_ROOT"
if swift build -c release \
    --product swiftformat-smart --product swiftlint-smart --product swiftskim; then
    echo "✅ Main package built successfully"
    echo "   Binaries: $PROJECT_ROOT/.build/release/"
else
    EXIT_CODE=$?
    echo ""
    echo "🚨 Build Error: MainPackageBuildFailed"
    echo "Problem: swift build -c release failed with exit code $EXIT_CODE"
    echo "Context: Building main swift-quality-tools package"
    echo "File: $PROJECT_ROOT/Package.swift"
    echo "Fix: Review Swift compilation errors above and fix any build issues"
    echo ""
    exit 1
fi

echo ""

# Build custom rule engine
echo "🔧 Building custom rule engine..."
if [ ! -d "$RULE_ENGINE_DIR" ]; then
    echo ""
    echo "🚨 Build Error: RuleEngineDirectoryNotFound"
    echo "Problem: Custom rule engine directory does not exist"
    echo "Context: Expected at $RULE_ENGINE_DIR"
    echo "Fix: Ensure CustomRules/swiftlint-swiftsyntax-integration/rule-engine/ directory exists"
    echo ""
    exit 1
fi

cd "$RULE_ENGINE_DIR"
if swift build -c release; then
    echo "✅ Custom rule engine built successfully"
    echo "   Binary: $RULE_ENGINE_DIR/.build/release/swiftskim-engine"
else
    EXIT_CODE=$?
    echo ""
    echo "🚨 Build Error: RuleEngineBuildFailed"
    echo "Problem: swift build failed for rule-engine with exit code $EXIT_CODE"
    echo "Context: Building custom SwiftSyntax rule engine"
    echo "File: $RULE_ENGINE_DIR/Package.swift"
    echo "Fix: Review Swift compilation errors above and ensure SwiftSyntax dependencies resolve"
    echo ""
    exit 1
fi

echo ""
echo "🎉 All builds completed successfully!"
echo ""
echo "Available executables:"
echo "  • swiftformat-smart:       $PROJECT_ROOT/.build/release/swiftformat-smart"
echo "  • swiftlint-smart:         $PROJECT_ROOT/.build/release/swiftlint-smart"
echo "  • swiftskim:   $PROJECT_ROOT/.build/release/swiftskim"
echo "  • swiftskim-engine:       $RULE_ENGINE_DIR/.build/release/swiftskim-engine"
echo ""
