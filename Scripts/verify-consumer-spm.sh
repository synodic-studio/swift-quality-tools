#!/bin/bash
# Clean-room verification that the public `SwiftSkim` SwiftPM library product works
# as an external consumer sees it: depend on the package, conform a custom `Rule`,
# call `SwiftSkim.lint`, and assert both the external rule and a built-in rule fire.
#
# Usage:
#   Scripts/verify-consumer-spm.sh            # depend on the local working tree (path)
#   Scripts/verify-consumer-spm.sh --remote   # depend on the pushed git URL + branch
#
# Exits non-zero on any mismatch. Builds in an isolated temp dir; leaves no trace.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=helpers/emit-spm-consumer.sh
source "$SCRIPT_DIR/helpers/emit-spm-consumer.sh"

REMOTE_URL="https://github.com/synodic-studio/swiftskim.git"
BRANCH="develop"

MODE="path"
[ "${1:-}" = "--remote" ] && MODE="remote"

if [ "$MODE" = "remote" ]; then
    DEP=".package(url: \"$REMOTE_URL\", branch: \"$BRANCH\")"
    PKGID="swiftskim"
else
    DEP=".package(path: \"$REPO_ROOT\")"
    # Path-dependency identity is the directory basename, not Package.name.
    PKGID="$(basename "$REPO_ROOT")"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "🧪 SwiftSkim SPM-consumer verification (mode: $MODE, package: $PKGID)"
echo "   workdir: $WORK"

emit_spm_consumer "$WORK" "$DEP" "$PKGID"

echo "🔨 Building + running consumer..."
( cd "$WORK" && swift run -c release SwiftSkimConsumer )
echo "✅ SPM-consumer verification passed"
