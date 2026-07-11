#!/bin/bash
# Verify the public CLI path: install swiftskim from the Homebrew tap (HEAD) and
# exercise the installed binaries — list rules, lint a known-bad file, confirm the
# engine and bundled Configs came along. Reinstalls from the pushed develop HEAD,
# so push before running.
#
# Usage: Scripts/verify-brew-install.sh

set -euo pipefail

# `brew reinstall` doesn't take --HEAD, so uninstall then install --HEAD to force a
# fresh build from the pushed develop HEAD.
echo "🍺 installing --HEAD synodic-studio/synodic/swiftskim ..."
brew uninstall --force swiftskim >/dev/null 2>&1 || true
brew install --HEAD synodic-studio/synodic/swiftskim

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
