#!/bin/bash
# Verify the public CLI path: install swiftskim from the Homebrew tap and exercise the
# installed binaries — list rules, lint a known-bad file, confirm the engine and bundled
# Configs came along.
#
# By default this certifies the SHIPPED ARTIFACT — the tagged release the formula's
# stable install builds (what an off-the-shelf `brew install` gets). Pass --head to
# instead test the pushed develop HEAD (the next release candidate); push before that.
#
# Usage: Scripts/verify-brew-install.sh [--head]

set -euo pipefail

MODE="stable"
[ "${1:-}" = "--head" ] && MODE="head"

# `brew reinstall` doesn't take --HEAD, so uninstall then install fresh.
brew uninstall --force swiftskim >/dev/null 2>&1 || true
if [ "$MODE" = "head" ]; then
    echo "🍺 installing --HEAD (develop) synodic-studio/synodic/swiftskim ..."
    brew install --HEAD synodic-studio/synodic/swiftskim
else
    echo "🍺 installing stable (tagged release) synodic-studio/synodic/swiftskim ..."
    brew install synodic-studio/synodic/swiftskim
fi

BIN="$(command -v swiftskim)"
echo "   installed at: $BIN"

# 1. Rule registry prints through the wrapper.
if swiftskim --list-rules | grep -q "16 total"; then
    echo "✅ --list-rules reports 16 rules"
else
    echo "FAIL: --list-rules did not report 16 rules"; exit 1
fi

# 2. Linting a known-bad file flags the expected built-in rule.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/BadView.swift" <<'EOF'
import SwiftUI
struct BadView: View {
    var body: some View {
        Group {
            Text("hi")
        }
    }
}
EOF
# Capture first (swiftskim exits non-zero on violations; with pipefail a
# `swiftskim | grep` pipeline would report the tool's exit, not grep's).
LINT_OUT="$(swiftskim "$TMP/BadView.swift" 2>&1 || true)"
if printf '%s' "$LINT_OUT" | grep -q "no_group_body"; then
    echo "✅ lint flags no_group_body on bad input"
else
    echo "FAIL: expected no_group_body violation"; printf '%s\n' "$LINT_OUT"; exit 1
fi

# 3. The engine binary is co-installed beside the wrapper (sibling resolution).
if [ -x "$(dirname "$BIN")/swiftskim-engine" ]; then
    echo "✅ swiftskim-engine co-installed"
else
    echo "FAIL: swiftskim-engine not found beside wrapper"; exit 1
fi

echo "🎉 brew install verification passed"
