#!/bin/bash
#
# Xcode Build Phase Linting Script
# Run SwiftFormat, SwiftLint, and custom SwiftSyntax rules
#
# Usage: Add to Xcode Build Phase:
#   "${HOME}/Developer/swift-quality-tools/Scripts/xcode-lint.sh"
#

set -e

TOOLS_DIR="${HOME}/Developer/swift-quality-tools/.build/release"

# SwiftFormat
if [ -f "${TOOLS_DIR}/swiftformat-smart" ]; then
    "${TOOLS_DIR}/swiftformat-smart" "${SRCROOT}" || true
else
    echo "warning: swiftformat-smart not found at ${TOOLS_DIR}"
fi

# SwiftLint
if [ -f "${TOOLS_DIR}/swiftlint-smart" ]; then
    "${TOOLS_DIR}/swiftlint-smart" "${SRCROOT}" || true
else
    echo "warning: swiftlint-smart not found at ${TOOLS_DIR}"
fi

# Custom SwiftLint Rules (auto-detects Xcode environment)
if [ -f "${TOOLS_DIR}/swiftlintcustom-smart" ]; then
    "${TOOLS_DIR}/swiftlintcustom-smart" "${SRCROOT}"
else
    echo "warning: swiftlintcustom-smart not found at ${TOOLS_DIR}"
    exit 1
fi
