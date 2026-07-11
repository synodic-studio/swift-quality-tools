#!/bin/bash
# Clean-room Linux verification of the public `SwiftSkim` library product, run inside
# a Swift container (OrbStack/Docker). This proves the library has no macOS-only
# assumptions — it compiles the `SwiftSkim` product (SwiftSyntax + Foundation only),
# not the macOS wrappers. Depends on the pushed develop HEAD (uses the remote URL).
#
# Usage:   Scripts/verify-consumer-linux.sh
# Env:     SWIFT_IMAGE (default swift:6.1) to pin the toolchain image.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=helpers/emit-spm-consumer.sh
source "$SCRIPT_DIR/helpers/emit-spm-consumer.sh"

# swiftskim uses Swift 6.1 syntax (SE-0439 trailing commas, enforced repo-wide by
# swiftformat), so 6.1 is the real floor. Older images fail to parse the manifest.
IMAGE="${SWIFT_IMAGE:-swift:6.1}"
REMOTE_URL="https://github.com/synodic-studio/swiftskim.git"
BRANCH="develop"

if ! command -v docker >/dev/null 2>&1; then
    echo "FAIL: docker (OrbStack provides it) not found on PATH"; exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "🐧 SwiftSkim Linux clean-room verification (image: $IMAGE)"
echo "   workdir: $WORK"

emit_spm_consumer "$WORK" ".package(url: \"$REMOTE_URL\", branch: \"$BRANCH\")" "swiftskim"

echo "🔨 Building + running consumer inside container..."
docker run --rm -v "$WORK":/work -w /work "$IMAGE" \
    bash -lc "swift run SwiftSkimConsumer"
echo "✅ Linux clean-room verification passed"
