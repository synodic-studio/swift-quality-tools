#!/bin/bash
# Clean-room verification that the public `SwiftSkim` SwiftPM library product works
# as an external consumer sees it: depend on the package, conform a custom `Rule`,
# call `SwiftSkim.lint`, and assert both the external rule and a built-in rule fire.
#
# Usage:
#   Scripts/verify-consumer-spm.sh            # depend on the local working tree (path)
#   Scripts/verify-consumer-spm.sh --remote   # depend on the pushed git URL at the
#                                             # latest released tag (from: "X.Y.Z") —
#                                             # exactly what an external consumer writes
#
# Exits non-zero on any mismatch. Builds in an isolated temp dir; leaves no trace.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=helpers/emit-spm-consumer.sh
source "$SCRIPT_DIR/helpers/emit-spm-consumer.sh"

REMOTE_URL="https://github.com/synodic-studio/swiftskim.git"

MODE="path"
[ "${1:-}" = "--remote" ] && MODE="remote"

if [ "$MODE" = "remote" ]; then
    # Resolve the shipped artifact — the latest release tag — and consume it via a
    # semver requirement, the way a public dependent pins it.
    RELEASE_VERSION="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
    if [ -z "$RELEASE_VERSION" ]; then
        echo "FAIL: no release tag found (git describe --tags); cannot test the shipped artifact"; exit 1
    fi
    DEP=".package(url: \"$REMOTE_URL\", from: \"$RELEASE_VERSION\")"
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
