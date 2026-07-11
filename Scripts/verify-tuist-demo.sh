#!/bin/bash
# Verify the SwiftSkim library is consumable through Tuist's SwiftPM integration:
# resolve it as an external dependency, then build + run a test target that imports
# and calls it. Uses the pushed develop HEAD (examples/tuist-demo/Package.swift
# points at the remote URL), so push before running.
#
# Usage: Scripts/verify-tuist-demo.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEMO="$REPO_ROOT/examples/tuist-demo"

if ! command -v tuist >/dev/null 2>&1; then
    echo "FAIL: tuist not found on PATH"; exit 1
fi

echo "🏗  tuist demo verification (dir: $DEMO)"
cd "$DEMO"
tuist install
tuist generate --no-open
tuist test
echo "✅ tuist demo verification passed"
