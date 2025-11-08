# Swift Quality Tools

Centralized Swift code quality tooling with smart configuration discovery. Provides unified interface for SwiftFormat, SwiftLint, and custom SwiftSyntax-based rules.

## Overview

This package provides three command-line tools:

- **swiftformat-smart** - SwiftFormat with intelligent config discovery
- **swiftlint-smart** - SwiftLint with intelligent config discovery
- **swiftlintcustom-smart** - Custom SwiftSyntax-based linting rules

All tools feature smart configuration discovery that walks up the directory tree to find project-specific configs, with fallback to shared configurations.

## Installation

### Build from Source

```bash
cd ~/Developer/swift-quality-tools
swift build -c release
```

Binaries will be available at:
```
~/Developer/swift-quality-tools/.build/release/
├── swiftformat-smart
├── swiftlint-smart
└── swiftlintcustom-smart
```

### Prerequisites

- **SwiftFormat**: `brew install swiftformat`
- **SwiftLint**: `brew install swiftlint`
- **Swift 5.9+**: For building the tools

## Usage

### swiftformat-smart

Format Swift code with automatic config discovery:

```bash
# Format current directory
swiftformat-smart

# Format specific file
swiftformat-smart Sources/MyFile.swift

# Format directory
swiftformat-smart Sources/

# Use explicit config
swiftformat-smart --config path/to/.swiftformat.yml
```

**Config Discovery Order:**
1. `--config` parameter if provided
2. `.swiftformat.yml` or `.swiftformat` in current directory (error if both)
3. Walk up directories until config found
4. Fall back to `~/Developer/swift-quality-tools/Configs/shared-swiftformat.yml`

### swiftlint-smart

Lint Swift code with automatic config discovery:

```bash
# Lint current directory
swiftlint-smart

# Lint specific file
swiftlint-smart Sources/MyFile.swift

# Lint directory
swiftlint-smart Sources/

# Use explicit config
swiftlint-smart --config path/to/.swiftlint.yml
```

**Config Discovery Order:**
1. `--config` parameter if provided
2. `.swiftlint.yml` or `.swiftlint.yaml` in current directory (error if both)
3. Walk up directories until config found
4. Fall back to `~/Developer/swift-quality-tools/Configs/shared-swiftlint.yml`

### swiftlintcustom-smart

Run custom SwiftSyntax-based rules:

```bash
# Check current directory
swiftlintcustom-smart

# Check specific file
swiftlintcustom-smart Sources/MyFile.swift

# Check directory
swiftlintcustom-smart Sources/
```

**Custom Rules:**
- SwiftUI View `body` properties limited to 10 lines maximum
- SwiftUI View `body` properties must have exactly one top-level view (never Group)

## Integration

### Claude Code Hooks

The hook system at `~/.claude/hooks/` automatically uses these tools:

```python
# ~/.claude/hooks/formatters/swift_formatter.py
SWIFT_TOOLS_PATH = Path.home() / "Developer" / "swift-quality-tools" / ".build" / "release"
```

When you edit Swift files in Claude Code, these tools run automatically.

### Xcode Build Phases

Add to your Xcode project's Build Phases for in-IDE warnings:

**Build Phase Script:**
```bash
if [ -f "${HOME}/Developer/swift-quality-tools/.build/release/swiftformat-smart" ]; then
    "${HOME}/Developer/swift-quality-tools/.build/release/swiftformat-smart" "${SRCROOT}"
fi

if [ -f "${HOME}/Developer/swift-quality-tools/.build/release/swiftlint-smart" ]; then
    "${HOME}/Developer/swift-quality-tools/.build/release/swiftlint-smart" "${SRCROOT}"
fi

if [ -f "${HOME}/Developer/swift-quality-tools/.build/release/swiftlintcustom-smart" ]; then
    "${HOME}/Developer/swift-quality-tools/.build/release/swiftlintcustom-smart" "${SRCROOT}"
fi
```

This provides:
- ✅ In-Xcode error/warning display
- ✅ Consistent quality checks across all projects
- ✅ Automatic config discovery per project

### Manual Command Line

Add to your PATH for easy access:

```bash
# In ~/.zshrc
export PATH="$HOME/Developer/swift-quality-tools/.build/release:$PATH"

# Then use anywhere:
swiftformat-smart .
swiftlint-smart .
swiftlintcustom-smart .
```

## Configuration Files

### Shared Configs

Located in `Configs/`:
- `shared-swiftformat.yml` - Global SwiftFormat rules (100+ rules, Swift 6.0 target)
- `shared-swiftlint.yml` - Global SwiftLint rules (custom SwiftUI rules, performance optimizations)

### Per-Project Configs

Place in project root to override shared configs:
- `.swiftformat.yml` or `.swiftformat`
- `.swiftlint.yml` or `.swiftlint.yaml`

The tools will automatically discover and use project-specific configs when present.

## Custom Rules

SwiftSyntax-based rules in `CustomRules/swiftlint-swiftsyntax-integration/`:

**Current Rules:**
1. **Skimmable SwiftUI body** - Maximum 10 lines in `body` properties
2. **Single top-level view** - Exactly one view at top level (no `Group` wrappers)

**To add new rules:**
1. Edit `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/`
2. Rebuild: `cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine && swift build`

## Architecture

```
swift-quality-tools/
├── Package.swift                    # Swift Package definition
├── Sources/
│   ├── SwiftFormatSmart/            # swiftformat-smart executable
│   ├── SwiftLintSmart/              # swiftlint-smart executable
│   ├── SwiftLintCustomSmart/        # swiftlintcustom-smart executable
│   └── SharedUtilities/             # Shared code
│       ├── ConfigDiscovery.swift    # Smart config finding
│       ├── ColoredOutput.swift      # Terminal colors
│       └── ProcessRunner.swift      # Process execution
├── Configs/                         # Shared configurations
│   ├── shared-swiftformat.yml
│   └── shared-swiftlint.yml
├── CustomRules/                     # Custom SwiftSyntax rules
│   └── swiftlint-swiftsyntax-integration/
└── .build/release/                  # Compiled binaries
```

## Benefits

✅ **Smart Config Discovery** - Automatically finds project configs, falls back to shared
✅ **Centralized Tooling** - Single source of truth for all Swift projects
✅ **Xcode Integration** - In-IDE warnings and errors
✅ **Hook Integration** - Auto-format on every edit in Claude Code
✅ **Fast Native Binaries** - No shell/Python overhead
✅ **Type-Safe Swift** - Robust error handling and CLI parsing
✅ **Consistent Quality** - Same rules across all projects

## Development

### Rebuilding After Changes

```bash
cd ~/Developer/swift-quality-tools
swift build -c release
```

### Testing

```bash
# Test on this repo
./.build/release/swiftformat-smart Sources/
./.build/release/swiftlint-smart Sources/
./.build/release/swiftlintcustom-smart Sources/

# Test on other projects
cd ~/Developer/gravity-well
~/Developer/swift-quality-tools/.build/release/swiftformat-smart .
```

## Migration from synodic-tools

This repo consolidates Swift quality tooling previously scattered in `synodic-tools/`:
- ✅ Moved `shared-swiftformat.yml` → `Configs/`
- ✅ Moved `shared-swiftlint.yml` → `Configs/`
- ✅ Moved `swiftlint-swiftsyntax-integration/` → `CustomRules/`
- ✅ Converted ZSH functions → Swift binaries
- ✅ Better separation of concerns (library vs tools)

## License

Personal tooling for Bryan Costanza's Swift projects.
