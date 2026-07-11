# SwiftSkim

A Swift AST-lint engine whose primary ruleset enforces SwiftUI structure. It pairs
three config-discovering CLI wrappers around SwiftFormat/SwiftLint with a
SwiftSyntax rule engine that enforces **16 custom rules** text-pattern linters
cannot express — most of them SwiftUI structure rules, the rest general Swift hygiene.

The name is the thesis: the flagship rule, `skimmable_body`, exists to keep code
readable at a glance. The whole toolkit optimizes for code you can skim.

### What it is (and isn't)

swiftskim is an **opinionated orchestrator**, not a neutral linter. It drives your
installed SwiftFormat and SwiftLint (both required — `brew install swiftformat
swiftlint`) alongside its own SwiftSyntax engine, and it ships an **opinionated
default config** (`Configs/`) that encodes a specific house style. That's the point,
not an accident — but it means: bring your own `.swiftformat` / `.swiftlint.yml` (the
wrappers discover project-local config first) if you don't want the bundled taste. The
genuinely novel, style-neutral part is the AST engine and its `SwiftSkim` library,
which you can consume on its own.

## What's in here

- **`swiftformat-smart`** — SwiftFormat with project-aware config discovery
- **`swiftlint-smart`** — SwiftLint with project-aware config discovery
- **`swiftskim`** — the custom SwiftSyntax rule engine, run in parallel

All three walk up the directory tree to find a project-specific config, falling back
to the bundled configs in `Configs/` when none is present.

## One source of truth

Every custom rule is defined once, as data, in `RuleRegistry` (in the rule engine).
The CLI prints straight from it:

```
$ swiftskim --list-rules
Custom SwiftSyntax rules (16 total):
  skimmable_body                     View/ViewModifier body capped at 15 lines
  one_top_level_view                 body must have exactly one top-level view
  onchange_ignored_old_value         Use 0-parameter onChange when the old value is ignored
  ...
```

The help text and this README derive from that registry rather than maintaining
their own copies, so the list of rules the tool *enforces* cannot drift from the
list it *documents*.

## Installation

### Build from source

```bash
git clone git@github.com:synodic-studio/swiftskim.git
cd swiftskim
./Scripts/build-all.sh
```

That builds all four binaries (the three wrappers plus the `swiftskim-engine`) from the
single package into `.build/release/`. The engine also auto-builds on first run of
`swiftskim` if it's missing.

### Prerequisites

- **SwiftFormat**: `brew install swiftformat`
- **SwiftLint**: `brew install swiftlint`
- **Swift 6.1+** to build the tools or consume the library (the codebase uses SE-0439
  trailing commas, which older toolchains can't parse)

## Usage

```bash
swiftformat-smart Sources/                 # format
swiftlint-smart Sources/                   # standard lint
swiftskim Sources/             # custom AST rules (parallel by default)
swiftskim --list-rules         # print the rule registry
swiftskim --sequential Sources/  # deterministic output for debugging
```

### Config discovery order

For all three tools:

1. `--config` flag if provided
2. Project-local config in the current directory
3. Walk up parent directories until a config is found
4. Fall back to the bundled `Configs/shared-*.yml`

### Configurable thresholds

Two rules take a threshold you can tune per project, in a `swiftskim:` block in
`.swiftlint.yml` (no forking required):

```yaml
swiftskim:
  skimmable_body_max_lines: 20      # default 15
  excessive_nesting_max_depth: 4    # default 3
```

Omit the block, or any key, to keep the defaults.

## Custom rules

The rules live in `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules/`,
one file per area. `RuleRegistry.swift` is the canonical list. The 16 rules, by area:

**View body** — `skimmable_body`, `one_top_level_view`, `no_group_body`, `no_if_modifier`, `no_if_without_else`

**View structure** — `view_structure_order`, `no_wrapper_body`, `stack_minimum_children`, `single_modifier_per_line`

**Code quality** — `excessive_nesting`, `prefer_shorthand_optional_binding`, `onchange_ignored_old_value`

**Imports & framework** — `preview_required`, `prefer_swift_testing`, `no_exported_import`, `blank_line_import_separation`

Run `swiftskim --list-rules` for the authoritative list with one-line summaries.

### Adding a rule

1. Append it to `RuleRegistry.all` (id + summary)
2. Dispatch it in `CustomRulesVisitor` using the **same** id
3. Rebuild: `./Scripts/build-all.sh`

A conformance test asserts the documented lists match the registry, so the id is
single-valued across the tool.

### Bring your own rule

The 16 built-ins are dispatched in one tree walk for speed. To add your *own* AST
rule without forking, conform to the `Rule` protocol and hand it to the engine —
your rule runs alongside the built-ins and gets the same suppression and output
handling:

```swift
import CustomRules
import SwiftSyntax

struct NoStructNamedFoo: Rule {
    let id = "no_struct_named_foo"
    let summary = "A struct may not be named Foo"
    func check(_ file: SourceFileSyntax, context: RuleContext) -> [Violation] {
        // walk `file`, return Violation(ruleID:line:message:) for each hit
    }
}

let violations = SwiftSkim.lint(source: source, externalRules: [NoStructNamedFoo()])
```

Your rule id participates in `swiftskim:disable` exactly like a built-in.

The engine is vended as a `SwiftSkim` library product from the root manifest, so you
can depend on it from another package:

```swift
.package(url: "https://github.com/synodic-studio/swiftskim.git", branch: "develop"),
// then add "SwiftSkim" (product) to your target's dependencies
```

### Suppressing a rule

Custom rules use the `swiftlintcustom:` prefix — deliberately distinct from SwiftLint's
own `swiftlint:`, so SwiftLint's `superfluous_disable_command` check still works:

```swift
// swiftlintcustom:disable:next skimmable_body
var body: some View { ... }

// swiftlintcustom:disable excessive_nesting
// ... block region ...
// swiftlintcustom:enable excessive_nesting
```

`:this` and `:previous` suppress the current and preceding line respectively.

## Integration

SwiftSkim is delivered as several thin surfaces over the same engine — use any,
skip any:

- **Command line** — add `.build/release/` to your `PATH`.
- **Xcode build phase** — add a "Run Script" phase calling `Scripts/xcode-lint.sh`.
  `swiftskim` auto-detects Xcode via `XCODE_VERSION_ACTUAL` and formats
  violations as clickable inline warnings.
- **Claude Code** — the `swift-quality` plugin (`.claude-plugin/`) bundles the linting
  skill; the formatter/linter runs on edit through the plugin's PostToolUse hook.
- **Codex CLI** — the same plugin, manifested at `.codex-plugin/`, reuses the shared
  `hooks/hooks.json` + `skills/`; the hook fires on Codex's `apply_patch` PostToolUse.
- **Cursor** — `.cursor/hooks.json` runs the same hook on Cursor's `afterFileEdit`.
- **pi** — the extension in `pi/` exposes `swiftskim_lint` / `swiftskim_list_rules` tools.

The Claude Code and Codex hooks share one `hooks/hooks.json` (its matcher covers
`Edit|Write|MultiEdit|apply_patch`) and one `hooks/format-swift.py`, which recognizes
all three agents' post-edit payload shapes and exits 2 with the violations on stderr.

## Development

```bash
./Scripts/build-all.sh     # build everything (release)
./Scripts/run-tests.sh     # full suite (unit + integration)
swift test                 # unit tests only (Swift Testing)
```

The tool passes its own rule set on its own source (`swiftskim .` exits clean).

### Verifying the delivery surfaces

`Scripts/verify-all.sh` is a release gate that checks every public surface — the CLI,
the Claude Code plugin hook, the pi extension, the `SwiftSkim` SwiftPM library (via SPM,
a Linux clean-room container, and a Tuist demo), and the Homebrew install:

```bash
./Scripts/verify-all.sh              # local surfaces (no network)
./Scripts/verify-all.sh --release    # + surfaces that consume the pushed HEAD
```

Each surface also has its own `Scripts/verify-*.sh` for running one in isolation.

### Self-healing error format

All three tools emit errors in a fixed shape so an automated caller can act on them:

```
[Tool] Error: [ErrorType]
Problem: [What is wrong]
Context: [What was being attempted]
Fix: [Concrete next step]
```

## License

SwiftSkim by Synodic Studio. MIT — see `LICENSE`.
