#!/bin/bash
# Verify the post-edit hook (hooks/format-swift.py) that backs the Claude Code and
# Codex plugins and the Cursor afterFileEdit hook. Feeds the hook a synthetic event
# in each agent's documented payload shape — no live agent session needed — and
# asserts a violation yields exit 2 with the rule on stderr.
#
#   - Claude Code : {"tool_input":{"file_path": ...}}          (Edit|Write|MultiEdit)
#   - Cursor      : {"file_path": ..., "edits":[...]}          (afterFileEdit)
#   - Codex       : {"tool_input":{"input":"*** Update File: ..."}}  (apply_patch)
#
# NOTE: this checks the hook's handling of each documented shape. It does not fire
# the hook inside a live Codex/Cursor session — that final smoke test is manual.
#
# Usage: Scripts/verify-agent-hooks.sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO_ROOT/hooks/format-swift.py"

export PATH="$REPO_ROOT/.build/release:$PATH"
export CLAUDE_PLUGIN_ROOT="$REPO_ROOT"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
echo "🪝 Agent post-edit hook verification (Claude Code / Codex / Cursor)"

BAD="$TMP/BadView.swift"
cat > "$BAD" <<'EOF'
import SwiftUI
struct BadView: View {
    var body: some View {
        Group {
            Text("hi")
        }
    }
}
EOF

CLEAN="$TMP/Point.swift"
cat > "$CLEAN" <<'EOF'
struct Point {
    let x: Int
    let y: Int
}
EOF

FAILED=0

# feed_hook <json>  ->  prints hook stderr; sets HOOK_CODE
feed_hook() {
    HOOK_STDERR="$(printf '%s' "$1" | python3 "$HOOK" 2>&1 1>/dev/null)"
    HOOK_CODE=$?
}

expect_violation() {
    local label="$1" json="$2"
    feed_hook "$json"
    if [ "$HOOK_CODE" = "2" ] && printf '%s' "$HOOK_STDERR" | grep -q "no_group_body"; then
        echo "✅ $label: violation -> exit 2, no_group_body reported"
    else
        echo "❌ $label: expected exit 2 + no_group_body, got code=$HOOK_CODE"
        printf '%s\n' "$HOOK_STDERR"
        FAILED=1
    fi
}

expect_clean() {
    local label="$1" json="$2"
    feed_hook "$json"
    if [ "$HOOK_CODE" = "0" ]; then
        echo "✅ $label: clean/ignored -> exit 0"
    else
        echo "❌ $label: expected exit 0, got code=$HOOK_CODE"
        FAILED=1
    fi
}

# Claude Code — tool_input.file_path
expect_violation "Claude Code" "$(printf '{"tool_input":{"file_path":"%s"},"cwd":"%s"}' "$BAD" "$TMP")"
# Cursor — top-level file_path + edits
expect_violation "Cursor"      "$(printf '{"file_path":"%s","edits":[{"old_string":"a","new_string":"b"}],"cwd":"%s"}' "$BAD" "$TMP")"
# Codex — apply_patch, path inside the patch text
expect_violation "Codex"       "$(printf '{"tool_name":"apply_patch","tool_input":{"input":"*** Begin Patch\\n*** Update File: %s\\n*** End Patch"},"cwd":"%s"}' "$BAD" "$TMP")"

# Clean Swift and a non-Swift edit must pass through.
expect_clean "clean file"   "$(printf '{"tool_input":{"file_path":"%s"},"cwd":"%s"}' "$CLEAN" "$TMP")"
expect_clean "non-Swift"    "$(printf '{"tool_input":{"file_path":"%s/notes.txt"},"cwd":"%s"}' "$TMP" "$TMP")"

# ---------------------------------------------------------------- lint scope
# A file the project's own `swiftlint-smart .` never looks at must not block an edit.
# SwiftLint applies included:/excluded: only when discovering files itself, so without
# scoping the hook — which always names a path — lints out-of-scope files with default
# scope and blocks on violations no repo-wide run would ever report.
PROJ="$TMP/scoped"
mkdir -p "$PROJ/Sources" "$PROJ/Vendor" "$PROJ/Engine"
cat > "$PROJ/.swiftlint.yml" <<'EOF'
included:
  - Sources
excluded:
  - Vendor
file_length:
  warning: 5
  error: 10
EOF

# 40 lines of plain Swift: a serious file_length violation under that config, and
# nothing any swiftskim rule objects to.
make_long_file() {
    {
        echo "struct Long$2 {"
        for i in $(seq 1 18); do
            printf '    let field%d: Int\n    // filler %d\n' "$i" "$i"
        done
        echo "}"
    } > "$1"
}
make_long_file "$PROJ/Sources/Long.swift" Included
make_long_file "$PROJ/Engine/Long.swift" Engine
make_long_file "$PROJ/Vendor/Long.swift" Vendor

scope_event() { printf '{"tool_input":{"file_path":"%s"},"cwd":"%s"}' "$1" "$PROJ"; }

feed_hook "$(scope_event "$PROJ/Sources/Long.swift")"
if [ "$HOOK_CODE" = "2" ] && printf '%s' "$HOOK_STDERR" | grep -q "file_length"; then
    echo "✅ in-scope violation: exit 2, file_length reported"
else
    echo "❌ in-scope violation: expected exit 2 + file_length, got code=$HOOK_CODE"
    printf '%s\n' "$HOOK_STDERR"
    FAILED=1
fi

expect_clean "outside included:" "$(scope_event "$PROJ/Engine/Long.swift")"
expect_clean "inside excluded:"  "$(scope_event "$PROJ/Vendor/Long.swift")"

# The same rule against this repo's real config: the rule-engine sources sit outside
# `included: [Sources, Tests]`, so an explicit-path lint must agree with `swiftlint-smart .`
# and report nothing. Run the linter directly — it does not touch the files.
ENGINE_DIR="$REPO_ROOT/CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules"
SCOPE_FAILED=0
for engine_file in "$ENGINE_DIR"/*.swift; do
    if ! (cd "$REPO_ROOT" && swiftlint-smart "$engine_file" >/dev/null 2>&1); then
        echo "❌ repo engine source blocks an explicit-path lint: ${engine_file#"$REPO_ROOT"/}"
        SCOPE_FAILED=1
        FAILED=1
    fi
done
[ "$SCOPE_FAILED" = "0" ] && echo "✅ repo rule-engine sources: out of scope, explicit-path lint reports nothing"

if [ "$FAILED" = "1" ]; then
    echo "🚨 Agent hook verification FAILED"; exit 1
fi
echo "🎉 Agent post-edit hook verification passed (all three payload shapes)"
