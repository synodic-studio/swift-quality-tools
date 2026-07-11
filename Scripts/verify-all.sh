#!/bin/bash
# Release gate: verify swiftskim and every public delivery surface.
#
# Two stages:
#   local   (default) — no network: build, unit+integration tests, self-lint,
#                        Claude Code plugin hook, pi extension, SPM consumer (path).
#   release (--release) — adds the surfaces that consume the PUSHED develop HEAD:
#                        Homebrew install, SPM consumer (remote), Linux clean-room,
#                        Tuist demo. Push the release commit before running these.
#
# Usage:
#   Scripts/verify-all.sh              # local stage only
#   Scripts/verify-all.sh --release    # local + release stage
#
# Runs every step (does not stop at the first failure) and prints a summary;
# exits non-zero if any step failed.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

RELEASE=0
[ "${1:-}" = "--release" ] && RELEASE=1

RESULTS=()
FAILED=0

# run <label> <command...> — run a step, record pass/fail, keep going.
run() {
    local label="$1"; shift
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "▶ $label"
    echo "════════════════════════════════════════════════════════════"
    if "$@"; then
        RESULTS+=("✅ $label")
    else
        RESULTS+=("❌ $label")
        FAILED=1
    fi
}

self_lint() { .build/release/swiftskim . ; }

# ---- local stage (no network) ----
run "build (release)"            "$SCRIPT_DIR/build-all.sh"
run "unit + integration tests"  "$SCRIPT_DIR/run-tests.sh"
run "self-lint"                 self_lint
run "agent post-edit hooks"     "$SCRIPT_DIR/verify-agent-hooks.sh"
run "pi extension"              "$SCRIPT_DIR/verify-pi-extension.sh"
run "SPM consumer (path)"       "$SCRIPT_DIR/verify-consumer-spm.sh"

# ---- release stage (consumes pushed develop HEAD) ----
if [ "$RELEASE" = "1" ]; then
    run "Homebrew install"        "$SCRIPT_DIR/verify-brew-install.sh"
    run "SPM consumer (remote)"   "$SCRIPT_DIR/verify-consumer-spm.sh" --remote
    run "Linux clean-room"        "$SCRIPT_DIR/verify-consumer-linux.sh"
    run "Tuist demo"              "$SCRIPT_DIR/verify-tuist-demo.sh"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Verification summary$([ "$RELEASE" = "1" ] && echo " (local + release)" || echo " (local)")"
echo "════════════════════════════════════════════════════════════"
for r in "${RESULTS[@]}"; do echo "  $r"; done
echo ""

if [ "$FAILED" = "1" ]; then
    echo "🚨 One or more verifications FAILED."
    exit 1
fi
echo "🎉 All verifications passed."
