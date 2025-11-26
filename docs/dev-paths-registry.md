# Development Path Registry

A centralized shell configuration pattern for managing references to development repositories without hardcoding absolute paths.

## Problem Statement

As a developer accumulates multiple projects, packages, and tools, shell configurations become littered with hardcoded paths:

```bash
# Fragile - breaks if you reorganize
alias swiftlint-smart="/Users/bryancostanza/Developer/swift-quality-tools/swiftlint-smart"
alias dev-gravity="cd /Users/bryancostanza/Developer/gravity-well"
```

Reorganizing the `~/Developer` directory requires updating every reference.

## Solution: Environment Variable Registry

A single source file defines all project paths as environment variables. Aliases and functions reference these variables instead of hardcoded paths.

### Implementation

Create `~/.config/dev-paths.sh`:

```bash
# ~/.config/dev-paths.sh
# Central registry of development paths
# Source this in .zshrc: source ~/.config/dev-paths.sh

# =============================================================================
# Root Paths
# =============================================================================
export DEV_ROOT="$HOME/Developer"
export DEV_VENVS="$DEV_ROOT/venvs"
export DEV_WORKTREES="$DEV_ROOT/worktrees"

# =============================================================================
# Infrastructure & Tooling
# =============================================================================
export DEV_SWIFT_QUALITY="$DEV_ROOT/swift-quality-tools"
export DEV_CC_CONFIG="$DEV_ROOT/synodic-cc-config"
export DEV_HOOKS="$DEV_ROOT/synodic-hooks"

# =============================================================================
# Swift Packages / Libraries
# =============================================================================
export DEV_SYNODIC_TOOLS="$DEV_ROOT/synodic-tools"
export DEV_ALLOY="$DEV_ROOT/alloy"

# =============================================================================
# Applications
# =============================================================================
export DEV_GRAVITY_WELL="$DEV_ROOT/gravity-well"
export DEV_SKYGLOW="$DEV_ROOT/skyglow"
export DEV_POINT_ONE_K="$DEV_ROOT/point-one-k"
export DEV_SO_MUCH_COFFEE="$DEV_ROOT/So Much Coffee"
export DEV_AWESOME_TIMER="$DEV_ROOT/Awesome Timer"

# =============================================================================
# Web Projects
# =============================================================================
export DEV_SYNODIC_CO="$DEV_ROOT/synodic-co"
export DEV_KJ6="$DEV_ROOT/kj6-dev"

# =============================================================================
# Helper Function: Quick Navigation
# =============================================================================
# Usage: dev gravity-well  OR  dev swift-quality
dev() {
    local target="DEV_${1//-/_}"  # Convert dashes to underscores
    target="${(U)target}"          # Uppercase (zsh syntax)

    local path="${(P)target}"      # Dereference variable name

    if [[ -z "$path" ]]; then
        echo "Unknown project: $1"
        echo "Available:"
        env | grep '^DEV_' | grep -v '^DEV_ROOT\|^DEV_VENVS\|^DEV_WORKTREES' | sort
        return 1
    fi

    cd "$path" || return 1
}

# Tab completion for dev function
_dev_complete() {
    local projects=(
        gravity-well skyglow point-one-k so-much-coffee awesome-timer
        swift-quality synodic-tools alloy cc-config hooks
        synodic-co kj6
    )
    compadd "${projects[@]}"
}
compdef _dev_complete dev

# =============================================================================
# Tool Aliases (using registry paths)
# =============================================================================
alias swiftlint-smart="$DEV_SWIFT_QUALITY/swiftlint-smart"
alias swiftformat-smart="$DEV_SWIFT_QUALITY/swiftformat-smart"
alias swiftlintcustom-smart="$DEV_SWIFT_QUALITY/swiftlintcustom-smart"

# =============================================================================
# Utility: Show all registered paths
# =============================================================================
dev-list() {
    echo "Development Path Registry:"
    echo "=========================="
    env | grep '^DEV_' | sort | while read -r line; do
        local name="${line%%=*}"
        local path="${line#*=}"
        if [[ -d "$path" ]]; then
            printf "  %-20s → %s\n" "$name" "$path"
        else
            printf "  %-20s → %s (MISSING)\n" "$name" "$path"
        fi
    done
}

# =============================================================================
# Utility: Validate all paths exist
# =============================================================================
dev-check() {
    local missing=0
    env | grep '^DEV_' | sort | while read -r line; do
        local path="${line#*=}"
        if [[ ! -d "$path" ]]; then
            echo "MISSING: $line"
            ((missing++))
        fi
    done
    [[ $missing -eq 0 ]] && echo "All paths valid."
}
```

### .zshrc Integration

Add to `~/.zshrc`:

```bash
# Development path registry
[[ -f ~/.config/dev-paths.sh ]] && source ~/.config/dev-paths.sh
```

## Usage Examples

```bash
# Quick navigation
dev gravity-well          # cd to gravity-well
dev swift-quality         # cd to swift-quality-tools

# List all registered paths
dev-list

# Verify paths exist after reorganization
dev-check

# Tool aliases work anywhere
swiftlint-smart --help

# Use in scripts
echo "Building at $DEV_GRAVITY_WELL"
```

## Benefits

| Benefit | Description |
|---------|-------------|
| **Single source of truth** | One file to update when paths change |
| **Reorganization resilient** | Move `~/Developer` to `~/Code`? Update `DEV_ROOT` |
| **Self-documenting** | `dev-list` shows all registered projects |
| **Validation** | `dev-check` catches broken paths after reorganization |
| **Tab completion** | `dev <TAB>` for quick navigation |
| **Composable** | Aliases, scripts, and functions all use the same variables |

## Conventions

- **Variable naming**: `DEV_PROJECT_NAME` (uppercase, underscores)
- **Function naming**: `dev` for navigation, `dev-*` for utilities
- **Path style**: Always reference `$DEV_ROOT` rather than `$HOME/Developer`

## Comparison with Alternatives

| Approach | Pros | Cons |
|----------|------|------|
| **Environment Registry** | Simple, no dependencies, version-controllable | Manual maintenance |
| **Symlink Farm** (~/.local/bin/) | Clean PATH, works for executables | Only executables, not source paths |
| **direnv** | Per-project context | Not global registry |
| **YAML + helper** | Structured, discoverable | Requires jq/yq dependency |

## Relationship to This Repository

This documentation lives in swift-quality-tools because the Swift quality tool aliases are a primary consumer of the registry pattern. However, the pattern itself is general-purpose and applies to any development environment with multiple repositories.

The swift-quality-tools project benefits from this pattern:

```bash
# Before: fragile
alias swiftlint-smart="/Users/username/Developer/swift-quality-tools/swiftlint-smart"

# After: resilient
alias swiftlint-smart="$DEV_SWIFT_QUALITY/swiftlint-smart"
```

When swift-quality-tools moves (e.g., to a monorepo or different machine), only the registry entry needs updating.
