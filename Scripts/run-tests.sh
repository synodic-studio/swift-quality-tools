#!/bin/bash
# Run all tests for swiftskim
# Includes unit tests and end-to-end validation

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🧪 Running swiftskim Test Suite"
echo ""

# Run Swift unit tests
echo "📋 Running unit tests..."
cd "$PROJECT_ROOT"

if swift test; then
    echo "✅ All unit tests passed"
else
    EXIT_CODE=$?
    echo ""
    echo "🚨 Test Error: UnitTestsFailed"
    echo "Problem: Swift unit tests failed with exit code $EXIT_CODE"
    echo "Context: Running 'swift test' in $PROJECT_ROOT"
    echo "Fix: Review test failures above and fix failing tests"
    echo ""
    exit 1
fi

echo ""

# Run integration tests (validate tools work)
echo "🔧 Running integration tests..."
./Scripts/test-tools.sh

echo ""
echo "🎉 All tests passed!"
echo ""
