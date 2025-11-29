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

Use the automated build script to build all components:

```bash
cd ~/Developer/swift-quality-tools
./Scripts/build-all.sh
```

This builds:
- Main package (swiftformat-smart, swiftlint-smart, swiftlintcustom-smart)
- Custom rule engine

**Manual build:**
```bash
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

Run custom SwiftSyntax-based rules with parallel processing:

```bash
# Check current directory (parallel - uses all CPU cores)
swiftlintcustom-smart

# Check specific file
swiftlintcustom-smart Sources/MyFile.swift

# Check directory
swiftlintcustom-smart Sources/

# Sequential mode (for debugging)
swiftlintcustom-smart --sequential Sources/
```

**Performance:**
- ⚡ Parallel processing enabled by default (uses all available CPU cores)
- 🚀 2-6x faster than sequential on multi-core systems
- 📈 Scales automatically with available hardware
- 🔧 Use `--sequential` flag to disable for debugging

**Custom Rules:**
- `skimmable_body`: SwiftUI View `body` properties limited to 15 lines maximum
- `no_group_body`: SwiftUI View `body` properties must have exactly one top-level view (never Group)
- `one_top_level_view`: SwiftUI View `body` must have exactly one top-level view
- `excessive_nesting`: Indentation depth limited to 4 levels maximum for all functions, closures, and initializers

**First Run:**
The custom rule engine auto-builds on first use if not already built.

## Integration

### Claude Code Hooks

The hook system at `~/.claude/hooks/` automatically uses these tools:

```python
# ~/.claude/hooks/formatters/swift_formatter.py
SWIFT_TOOLS_PATH = Path.home() / "Developer" / "swift-quality-tools" / ".build" / "release"
```

When you edit Swift files in Claude Code, these tools run automatically.

### Xcode Build Phases

Add to your Xcode project's Build Phases to show lint warnings in the IDE.

**Note:** SwiftFormat runs on edit via Claude Code hooks, not in build phases. Only linters (SwiftLint + custom rules) should be in build phases.

**Recommended: Single Script Approach**

Add a "Run Script" build phase with:
```bash
"${HOME}/Developer/swift-quality-tools/Scripts/xcode-lint.sh"
```

This script runs both linters and works around Xcode's subprocess output suppression by parsing and re-echoing warnings.

**Known Limitation:** Xcode's build phase sandbox suppresses subprocess output. The script works around this by running swiftlintcustom-smart in terminal mode, parsing the output, and re-echoing warnings directly.

**Alternative: Direct Tool Invocation**

If you prefer explicit control:
```bash
if [ -f "${HOME}/Developer/swift-quality-tools/.build/release/swiftlint-smart" ]; then
    "${HOME}/Developer/swift-quality-tools/.build/release/swiftlint-smart" "${SRCROOT}" || true
fi

if [ -f "${HOME}/Developer/swift-quality-tools/.build/release/swiftlintcustom-smart" ]; then
    "${HOME}/Developer/swift-quality-tools/.build/release/swiftlintcustom-smart" "${SRCROOT}"
fi
```

**Auto-Detection:** `swiftlintcustom-smart` automatically detects when running in Xcode (via `XCODE_VERSION_ACTUAL` environment variable) and formats violations as clickable warnings for the Issue Navigator.

This provides:
- ✅ Clickable lint warnings in Xcode Issue Navigator
- ✅ Consistent quality checks across all projects
- ✅ Automatic config discovery per project
- ✅ Auto-detection of Xcode environment (no flags needed)
- ✅ Single script for easy maintenance

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
1. **`skimmable_body`** - SwiftUI View body line count limit (15 lines max)
2. **`no_group_body`** - Prohibit top-level Group in View bodies (unless it has modifiers)
3. **`one_top_level_view`** - Enforce single top-level view in View bodies
4. **`excessive_indentation`** - Physical indentation limit (16 spaces / 4 tabs max)
5. **`stack_minimum_children`** - VStack/HStack/ZStack must have at least 2 children (ForEach allowed; if/else allowed if any branch has 2+ views)
6. **`view_structure_order`** - Enforce View property ordering (DISABLED - has bugs)
7. **`no_wrapper_body`** - Detect pointless wrapper body properties
8. **`blank_line_import_separation`** - Enforce blank line between regular and @testable imports
9. **`preview_required`** - Every file with View/ViewModifier must have at least one #Preview
10. **`no_exported_import`** - Prohibit `@_exported import` (underscore prefix = internal Swift API, not stable)
11. **`prefer_swift_testing`** - Prefer Swift Testing framework over XCTest (detects `import XCTest` and XCTAssert* calls)
12. **`prefer_shorthand_optional_binding`** - Detect optional binding renames (`if let foo = bar`) - use shorthand with original name instead

**To add new rules:**
1. Edit `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/test-custom-rule.swift`
2. Rebuild: `./Scripts/build-all.sh` or manually:
   ```bash
   cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine
   swift build
   ```

### Suppressing Custom Rules

Custom rules support line-specific suppression using the `swiftlintcustom:` prefix:

```swift
// swiftlintcustom:disable:next excessive_nesting
var computed: String {
    // Deep nesting allowed here
}

// Or inline
func deep() { // swiftlintcustom:disable:this excessive_nesting
    // ...
}
```

**Note:** Use `swiftlint:` for standard rules and `swiftlintcustom:` for custom rules. This keeps SwiftLint's `superfluous_disable_command` safety check working for standard rules.

See `docs/swiftlint-directive-support.md` for full documentation.

## Architecture

```
swift-quality-tools/
├── Package.swift                    # Swift Package definition
├── Scripts/                         # Build and test scripts
│   ├── build-all.sh                 # Build all components
│   └── test-tools.sh                # Validate installation
├── Sources/
│   ├── SwiftFormatSmart/            # swiftformat-smart executable
│   ├── SwiftLintSmart/              # swiftlint-smart executable
│   ├── SwiftLintCustomSmart/        # swiftlintcustom-smart executable
│   └── SharedUtilities/             # Shared code
│       ├── ConfigDiscovery.swift    # Smart config finding
│       ├── ColoredOutput.swift      # Terminal colors
│       ├── ProcessRunner.swift      # Process execution
│       └── ErrorFormatter.swift     # Self-healing error messages
├── Configs/                         # Shared configurations
│   ├── shared-swiftformat.yml
│   └── shared-swiftlint.yml
├── CustomRules/                     # Custom SwiftSyntax rules
│   └── swiftlint-swiftsyntax-integration/
│       └── rule-engine/
│           ├── Package.swift
│           └── test-custom-rule.swift
└── .build/release/                  # Compiled binaries
```

## Benefits

✅ **Smart Config Discovery** - Automatically finds project configs, falls back to shared
✅ **Centralized Tooling** - Single source of truth for all Swift projects
✅ **Xcode Integration** - In-IDE warnings and errors
✅ **Hook Integration** - Auto-format on every edit in Claude Code
✅ **Fast Native Binaries** - No shell/Python overhead
✅ **Type-Safe Swift** - Robust error handling and CLI parsing
✅ **Self-Healing Errors** - Actionable error messages for LLM auto-repair
✅ **Consistent Quality** - Same rules across all projects

## Development

### Rebuilding After Changes

```bash
cd ~/Developer/swift-quality-tools
./Scripts/build-all.sh
```

### Testing

Run the complete test suite (unit tests + integration tests):

```bash
./Scripts/run-tests.sh
```

**Test individual components:**

```bash
# Unit tests only (Swift Testing framework)
swift test

# Integration tests only (tool validation)
./Scripts/test-tools.sh
```

**Manual testing:**
```bash
# Test on this repo
./.build/release/swiftformat-smart Sources/
./.build/release/swiftlint-smart Sources/
./.build/release/swiftlintcustom-smart Sources/

# Test on other projects
cd ~/Developer/gravity-well
~/Developer/swift-quality-tools/.build/release/swiftformat-smart .
```

**Test Coverage:**
- ErrorFormatter - Self-healing error message formatting
- ConfigDiscovery - Smart config file discovery and validation
- Integration - All three tools executable and working correctly

### Error Messages

All tools provide self-healing error messages following the pattern:
```
🚨 [Tool] Error: [ErrorType]
Problem: [Clear description]
Context: [What was being attempted]
Fix: [Actionable suggestion]
```

This enables LLM auto-repair when errors occur in Claude Code hooks.

## Migration from synodic-tools

This repo consolidates Swift quality tooling previously scattered in `synodic-tools/`:
- ✅ Moved `shared-swiftformat.yml` → `Configs/`
- ✅ Moved `shared-swiftlint.yml` → `Configs/`
- ✅ Moved `swiftlint-swiftsyntax-integration/` → `CustomRules/`
- ✅ Converted ZSH functions → Swift binaries
- ✅ Better separation of concerns (library vs tools)

## License

Personal tooling for Bryan Costanza's Swift projects.
