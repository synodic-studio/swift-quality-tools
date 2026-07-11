#!/bin/bash
# Verify the swiftskim pi extension registers its tools and that they work against
# the real swiftskim binary. Thin wrapper over pi/verify-extension.mjs that points
# SWIFTSKIM_BIN at the freshly-built binary.
#
# Usage: Scripts/verify-pi-extension.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v node >/dev/null 2>&1; then
    echo "FAIL: node not found on PATH"; exit 1
fi

export SWIFTSKIM_BIN="${SWIFTSKIM_BIN:-$REPO_ROOT/.build/release/swiftskim}"
if [ ! -x "$SWIFTSKIM_BIN" ]; then
    echo "FAIL: swiftskim binary not found at $SWIFTSKIM_BIN (build first: Scripts/build-all.sh)"; exit 1
fi

echo "🤖 pi extension verification (SWIFTSKIM_BIN=$SWIFTSKIM_BIN)"
node "$REPO_ROOT/pi/verify-extension.mjs"
