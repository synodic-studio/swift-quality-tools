#!/bin/bash

# Check an entire project for SwiftSyntax rule violations
# Usage: ./check-project.sh path/to/project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
RULE_ENGINE="$PROJECT_DIR/rule-engine/.build/debug/test-custom-rule"

# Check if rule engine is built
if [ ! -f "$RULE_ENGINE" ]; then
    echo "❌ Rule engine not built. Run ./scripts/setup.sh first"
    exit 1
fi

# Check if project path provided
if [ $# -eq 0 ]; then
    echo "Usage: ./check-project.sh <path/to/project>"
    echo ""
    echo "Examples:"
    echo "  ./check-project.sh ../../gravity-well"
    echo "  ./check-project.sh ~/Developer/MyApp"
    exit 1
fi

# Check if project directory exists
if [ ! -d "$1" ]; then
    echo "❌ Project directory not found: $1"
    exit 1
fi

PROJECT_PATH="$1"
echo "🔍 Checking project: $PROJECT_PATH"

# Count total Swift files
TOTAL_FILES=$(find "$PROJECT_PATH" -name "*.swift" -type f -not -path "*/build/*" -not -path "*/.build/*" -not -path "*/DerivedData/*" | wc -l | tr -d ' ')
echo "📄 Found $TOTAL_FILES Swift files"

if [ "$TOTAL_FILES" -eq 0 ]; then
    echo "❌ No Swift files found in project"
    exit 1
fi

# Check each file
VIOLATION_COUNT=0
FILE_COUNT=0

find "$PROJECT_PATH" -name "*.swift" -type f -not -path "*/build/*" -not -path "*/.build/*" -not -path "*/DerivedData/*" | while read -r file; do
    FILE_COUNT=$((FILE_COUNT + 1))
    
    # Show progress for large projects
    if [ $((FILE_COUNT % 10)) -eq 0 ]; then
        echo "📊 Processed $FILE_COUNT/$TOTAL_FILES files..."
    fi
    
    # Run rule on file
    output=$("$RULE_ENGINE" "$file" 2>&1)
    
    # Check if there are violations
    if echo "$output" | grep -q "⚠️"; then
        echo "📁 $(basename "$(dirname "$file")")/$(basename "$file")"
        echo "$output" | grep "⚠️"
        echo ""
        VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
    fi
done

echo "🏁 Project check complete"
echo "📊 $TOTAL_FILES files checked"

# Note: Due to subshell, we can't easily get the final violation count
# But the output above shows all violations found