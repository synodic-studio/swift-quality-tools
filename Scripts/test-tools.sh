#!/bin/bash
# Test script for swift-quality-tools
# Validates that all tools are working correctly

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/.build/release"

echo "🧪 Testing swift-quality-tools"
echo ""

# Check if tools exist
echo "📋 Checking executables..."
MISSING_TOOLS=()

if [ ! -f "$TOOLS_DIR/swiftformat-smart" ]; then
    MISSING_TOOLS+=("swiftformat-smart")
fi

if [ ! -f "$TOOLS_DIR/swiftlint-smart" ]; then
    MISSING_TOOLS+=("swiftlint-smart")
fi

if [ ! -f "$TOOLS_DIR/swiftlintcustom-smart" ]; then
    MISSING_TOOLS+=("swiftlintcustom-smart")
fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo ""
    echo "🚨 Test Error: ExecutablesNotFound"
    echo "Problem: Missing executables: ${MISSING_TOOLS[*]}"
    echo "Context: Expected in $TOOLS_DIR"
    echo "Fix: Run './Scripts/build-all.sh' to build all tools"
    echo ""
    exit 1
fi

echo "✅ All executables found"
echo ""

# Test each tool's --help
echo "🔍 Testing tool help messages..."

echo "  Testing swiftformat-smart --help..."
if "$TOOLS_DIR/swiftformat-smart" --help > /dev/null 2>&1; then
    echo "  ✅ swiftformat-smart"
else
    echo "  ❌ swiftformat-smart --help failed"
    exit 1
fi

echo "  Testing swiftlint-smart --help..."
if "$TOOLS_DIR/swiftlint-smart" --help > /dev/null 2>&1; then
    echo "  ✅ swiftlint-smart"
else
    echo "  ❌ swiftlint-smart --help failed"
    exit 1
fi

echo "  Testing swiftlintcustom-smart --help..."
if "$TOOLS_DIR/swiftlintcustom-smart" --help > /dev/null 2>&1; then
    echo "  ✅ swiftlintcustom-smart"
else
    echo "  ❌ swiftlintcustom-smart --help failed"
    exit 1
fi

echo ""

# Check for required commands
echo "🔧 Checking required commands..."

REQUIRED_COMMANDS=("swiftformat" "swiftlint" "swift")
MISSING_COMMANDS=()

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        MISSING_COMMANDS+=("$cmd")
    else
        echo "  ✅ $cmd"
    fi
done

if [ ${#MISSING_COMMANDS[@]} -ne 0 ]; then
    echo ""
    echo "⚠️  Warning: Missing commands: ${MISSING_COMMANDS[*]}"
    echo "Install missing commands:"
    for cmd in "${MISSING_COMMANDS[@]}"; do
        echo "  brew install $cmd"
    done
    echo ""
else
    echo ""
fi

# Check configs
echo "📝 Checking shared configurations..."

CONFIG_DIR="$PROJECT_ROOT/Configs"
if [ -f "$CONFIG_DIR/shared-swiftformat.yml" ]; then
    echo "  ✅ shared-swiftformat.yml"
else
    echo "  ❌ shared-swiftformat.yml not found"
    exit 1
fi

if [ -f "$CONFIG_DIR/shared-swiftlint.yml" ]; then
    echo "  ✅ shared-swiftlint.yml"
else
    echo "  ❌ shared-swiftlint.yml not found"
    exit 1
fi

echo ""

# Check custom rule engine
echo "🔍 Checking custom rule engine..."
RULE_ENGINE="$PROJECT_ROOT/CustomRules/swiftlint-swiftsyntax-integration/rule-engine/.build/release/swift-skim-engine"

if [ -f "$RULE_ENGINE" ]; then
    echo "  ✅ Custom rule engine built"
else
    echo "  ⚠️  Custom rule engine not built (will auto-build on first use)"
fi

echo ""
echo "🎉 All tests passed!"
echo ""
echo "Tools are ready to use:"
echo "  • swiftformat-smart"
echo "  • swiftlint-smart"
echo "  • swiftlintcustom-smart"
echo ""
