#!/usr/bin/env bash
# Sync SwiftFormat config across all Swift repos under ~/Developer/
# Creates .swiftformat symlinks pointing to the shared config in this repo.
#
# Usage: ./scripts/sync-swiftformat.sh [--dry-run] [--format]
#   --dry-run   Show what would be done without making changes
#   --format    Run swiftformat after setting up symlinks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/Configs/shared-swiftformat.yml"
DEVELOPER_DIR="$(cd "$REPO_ROOT/.." && pwd)"

DRY_RUN=false
RUN_FORMAT=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --format) RUN_FORMAT=true ;;
    esac
done

# Repos to skip (not Bryan's Swift projects, or owns the config)
SKIP_REPOS="swift-quality-tools ShapeScript archive worktrees venvs scripts"

should_skip() {
    local dir="$1"
    for skip in $SKIP_REPOS; do
        [ "$dir" = "$skip" ] && return 0
    done
    return 1
}

has_swift_files() {
    find "$1" -name "*.swift" -maxdepth 4 -print -quit 2>/dev/null | grep -q .
}

echo "SwiftFormat Config Sync"
echo "Config: $CONFIG_FILE"
echo "Scanning: $DEVELOPER_DIR"
echo ""

created=0
replaced=0
skipped=0
already_ok=0

for dir in "$DEVELOPER_DIR"/*/; do
    repo_name="$(basename "$dir")"

    # Skip non-git directories
    [ ! -d "$dir/.git" ] && continue

    # Skip excluded repos
    if should_skip "$repo_name"; then
        continue
    fi

    # Skip repos without Swift files
    if ! has_swift_files "$dir"; then
        continue
    fi

    target_link="$dir/.swiftformat"
    relative_config="../swift-quality-tools/Configs/shared-swiftformat.yml"

    # Check current state
    if [ -L "$target_link" ]; then
        current_target="$(readlink "$target_link")"
        if [ "$current_target" = "$relative_config" ]; then
            echo "  OK  $repo_name (symlink already correct)"
            already_ok=$((already_ok + 1))
            continue
        fi
    fi

    if [ -f "$target_link" ] && [ ! -L "$target_link" ]; then
        # Regular file exists — replace it
        if $DRY_RUN; then
            echo "  REPLACE  $repo_name (existing .swiftformat → symlink)"
        else
            rm "$target_link"
            ln -s "$relative_config" "$target_link"
            echo "  REPLACE  $repo_name (was regular file, now symlink)"
        fi
        replaced=$((replaced + 1))
    elif [ -f "${target_link}.yml" ] && [ ! -L "${target_link}.yml" ]; then
        # .swiftformat.yml exists — remove it and create .swiftformat symlink
        if $DRY_RUN; then
            echo "  REPLACE  $repo_name (existing .swiftformat.yml → .swiftformat symlink)"
        else
            rm "${target_link}.yml"
            ln -s "$relative_config" "$target_link"
            echo "  REPLACE  $repo_name (.swiftformat.yml removed, .swiftformat symlink created)"
        fi
        replaced=$((replaced + 1))
    elif [ ! -e "$target_link" ]; then
        # No config exists — create symlink
        if $DRY_RUN; then
            echo "  CREATE  $repo_name"
        else
            ln -s "$relative_config" "$target_link"
            echo "  CREATE  $repo_name"
        fi
        created=$((created + 1))
    else
        echo "  SKIP  $repo_name (unexpected state)"
        skipped=$((skipped + 1))
    fi

    # Optionally run swiftformat
    if $RUN_FORMAT && ! $DRY_RUN; then
        echo "         formatting $repo_name..."
        if ! swiftformat "$dir" --config "$CONFIG_FILE" 2>&1 | tail -1; then
            echo "         WARNING: swiftformat had issues in $repo_name"
        fi
    fi
done

echo ""
echo "Summary: $created created, $replaced replaced, $already_ok already OK, $skipped skipped"
