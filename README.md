# Swift Quality Tools

Centralized Swift code quality tooling with smart configuration discovery. Three command-line binaries plus 12 custom SwiftSyntax-based lint rules that text-pattern linters cannot express.

## What's in here

- **`swiftformat-smart`**: SwiftFormat with project-aware config discovery
- **`swiftlint-smart`**: SwiftLint with project-aware config discovery
- **`swiftlintcustom-smart`**: Custom SwiftSyntax-based linting rules with parallel processing

All three walk up the directory tree to find a project-specific config, falling back to the shared configs in `Configs/` when none is present.

## Installation

### Build from source

```bash
cd ~/Developer/swift-quality-tools
./Scripts/build-all.sh
```

That builds all three binaries plus the custom rule engine. Manual build:

```bash
swift build -c release
```

Binaries land in `.build/release/`:

```
~/Developer/swift-quality-tools/.build/release/
├── swiftformat-smart
├── swiftlint-smart
└── swiftlintcustom-smart
```

### Prerequisites

- **SwiftFormat**: `brew install swiftformat`
- **SwiftLint**: `brew install swiftlint`
- **Swift 5.9+** for building the tools themselves

## Usage

### swiftformat-smart

```bash
swiftformat-smart                                      # current directory
swiftformat-smart Sources/MyFile.swift                 # single file
swiftformat-smart Sources/                             # directory
swiftformat-smart --config path/to/.swiftformat.yml    # explicit config
```

### swiftlint-smart

```bash
swiftlint-smart                                        # current directory
swiftlint-smart Sources/MyFile.swift                   # single file
swiftlint-smart Sources/                               # directory
swiftlint-smart --config path/to/.swiftlint.yml        # explicit config
```

### swiftlintcustom-smart

```bash
swiftlintcustom-smart                                  # parallel by default
swiftlintcustom-smart Sources/MyFile.swift             # single file
swiftlintcustom-smart Sources/                         # directory
swiftlintcustom-smart --sequential Sources/            # debug mode
```

Parallel processing is on by default and uses every available CPU core. Pass `--sequential` for predictable output when debugging a rule. The custom rule engine auto-builds on first run.

### Config discovery order

For all three tools:

1. `--config` flag if provided
2. Project-local config in current directory
3. Walk up parent directories until a config is found
4. Fall back to `Configs/shared-*.yml` in this repo

## Custom Rules

The rules live in `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/test-custom-rule.swift`.

1. **`skimmable_body`**: SwiftUI View `body` properties capped at 15 lines
2. **`no_group_body`**: `body` must not be a top-level `Group` (unless it has modifiers)
3. **`one_top_level_view`**: `body` must have exactly one top-level view
4. **`excessive_indentation`**: physical indentation capped at 16 spaces / 4 tabs
5. **`stack_minimum_children`**: `VStack`/`HStack`/`ZStack` must have at least 2 children (`ForEach` and `if`/`else` with 2+ branches allowed)
6. **`view_structure_order`**: view property ordering (currently disabled, has bugs)
7. **`no_wrapper_body`**: flags pointless wrapper `body` properties
8. **`blank_line_import_separation`**: blank line required between regular and `@testable` imports
9. **`preview_required`**: every file declaring a `View`, `ViewModifier`, or `Shape` must have at least one `#Preview`
10. **`no_exported_import`**: bans `@_exported import` (underscore prefix is unstable Swift API)
11. **`prefer_swift_testing`**: flags `import XCTest` and `XCTAssert*` calls in favor of Swift Testing
12. **`prefer_shorthand_optional_binding`**: flags `if let foo = bar` in favor of the shorthand `if let bar`

### Adding a rule

1. Edit `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/test-custom-rule.swift`
2. Rebuild: `./Scripts/build-all.sh`

### Suppressing a rule on a specific line

Custom rules support line-specific suppression using the `swiftlintcustom:` prefix (separate from SwiftLint's `swiftlint:` so the standard linter's `superfluous_disable_command` safety check still works):

```swift
// swiftlintcustom:disable:next excessive_nesting
var computed: String {
    // Deep nesting allowed here
}

func deep() { // swiftlintcustom:disable:this excessive_nesting
    // ...
}
```

See `docs/swiftlint-directive-support.md` for the full directive syntax.

## Integration

### Claude Code hooks

The hook system at `~/.claude/hooks/` calls into the binaries automatically:

```python
# ~/.claude/hooks/formatters/swift_formatter.py
SWIFT_TOOLS_PATH = Path.home() / "Developer" / "swift-quality-tools" / ".build" / "release"
```

When you edit a Swift file in Claude Code, formatting runs immediately and lint warnings show up in the next response.

### Xcode build phases

Add a "Run Script" build phase to surface lint warnings in the Issue Navigator:

```bash
"${HOME}/Developer/swift-quality-tools/Scripts/xcode-lint.sh"
```

The script runs both linters and works around Xcode's subprocess output suppression by parsing and re-echoing warnings as standard Xcode warning lines.

`swiftlintcustom-smart` auto-detects when it's running inside Xcode (via `XCODE_VERSION_ACTUAL`) and formats violations as clickable warnings without any flags.

If you want explicit control instead of the wrapper script:

```bash
if [ -f "${HOME}/Developer/swift-quality-tools/.build/release/swiftlint-smart" ]; then
    "${HOME}/Developer/swift-quality-tools/.build/release/swiftlint-smart" "${SRCROOT}" || true
fi

if [ -f "${HOME}/Developer/swift-quality-tools/.build/release/swiftlintcustom-smart" ]; then
    "${HOME}/Developer/swift-quality-tools/.build/release/swiftlintcustom-smart" "${SRCROOT}"
fi
```

SwiftFormat is intentionally not in the build phase. It runs on every edit through the Claude Code hook, and build phases stay linters-only.

### Manual command line

Add the binaries to your PATH:

```bash
# In ~/.zshrc
export PATH="$HOME/Developer/swift-quality-tools/.build/release:$PATH"

swiftformat-smart .
swiftlint-smart .
swiftlintcustom-smart .
```

## Configuration

### Shared configs (in `Configs/`)

- `shared-swiftformat.yml`: SwiftFormat ruleset, Swift 6.0 target
- `shared-swiftlint.yml`: SwiftLint ruleset, custom SwiftUI rules

### Per-project configs

Place either of these in a project root to override the shared config:

- `.swiftformat.yml` or `.swiftformat`
- `.swiftlint.yml` or `.swiftlint.yaml`

The tools discover them automatically.

## Architecture

```
swift-quality-tools/
├── Package.swift                    # Swift Package definition
├── Scripts/
│   ├── build-all.sh                 # Build everything
│   └── test-tools.sh                # Integration validation
├── Sources/
│   ├── SwiftFormatSmart/            # swiftformat-smart binary
│   ├── SwiftLintSmart/              # swiftlint-smart binary
│   ├── SwiftLintCustomSmart/        # swiftlintcustom-smart binary
│   └── SharedUtilities/
│       ├── ConfigDiscovery.swift    # Walk-up config finder
│       ├── ColoredOutput.swift      # Terminal colors
│       ├── ProcessRunner.swift      # Subprocess execution
│       └── ErrorFormatter.swift     # Self-healing error messages
├── Configs/                         # Shared rulesets
│   ├── shared-swiftformat.yml
│   └── shared-swiftlint.yml
├── CustomRules/
│   └── swiftlint-swiftsyntax-integration/
│       └── rule-engine/
│           ├── Package.swift
│           └── test-custom-rule.swift
└── .build/release/                  # Compiled binaries
```

## Development

### Rebuilding after changes

```bash
cd ~/Developer/swift-quality-tools
./Scripts/build-all.sh
```

### Testing

```bash
./Scripts/run-tests.sh                # full suite (unit + integration)
swift test                            # unit tests only (Swift Testing)
./Scripts/test-tools.sh               # integration only (binary validation)
```

Manual testing on this repo or any other Swift project:

```bash
./.build/release/swiftformat-smart Sources/
./.build/release/swiftlint-smart Sources/
./.build/release/swiftlintcustom-smart Sources/
```

### Error message format

All three tools emit self-healing errors in a fixed shape so the Claude Code hook can act on them:

```
[Tool] Error: [ErrorType]
Problem: [What is wrong]
Context: [What was being attempted]
Fix: [Concrete next step]
```

The shape is consistent enough that an LLM can parse it and either fix the issue or surface a clear question.

## License

Swift quality tooling by Synodic Studio. See `LICENSE` for the terms.
