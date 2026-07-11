#!/bin/bash
# Build script for swiftskim
# Builds all binaries (wrappers + rule engine) from the single root package,
# with self-healing error messages. The rule engine used to be a nested SwiftPM
# package; it now shares the root package, so one build emits everything and
# SwiftSyntax compiles once.

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔨 Building swiftskim"
echo ""

echo "📦 Building package (release mode)..."
cd "$PROJECT_ROOT"
if swift build -c release; then
    echo "✅ Build succeeded"
    echo "   Binaries: $PROJECT_ROOT/.build/release/"
else
    EXIT_CODE=$?
    echo ""
    echo "🚨 Build Error: PackageBuildFailed"
    echo "Problem: swift build -c release failed with exit code $EXIT_CODE"
    echo "Context: Building the swiftskim package"
    echo "File: $PROJECT_ROOT/Package.swift"
    echo "Fix: Review Swift compilation errors above and fix any build issues"
    echo ""
    exit 1
fi

echo ""
echo "🎉 Build completed successfully!"
echo ""
echo "Available executables:"
echo "  • swiftformat-smart:   $PROJECT_ROOT/.build/release/swiftformat-smart"
echo "  • swiftlint-smart:     $PROJECT_ROOT/.build/release/swiftlint-smart"
echo "  • swiftskim:           $PROJECT_ROOT/.build/release/swiftskim"
echo "  • swiftskim-engine:    $PROJECT_ROOT/.build/release/swiftskim-engine"
echo ""
