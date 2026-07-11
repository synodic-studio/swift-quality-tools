# AGENTS.md

Canonical guidance for working in **swift-skim** (repo: `synodic-studio/swift-skim`;
local dir is still `~/Developer/swift-quality-tools`). `CLAUDE.md` imports this file.

## What this is

A Swift AST-lint engine whose primary ruleset enforces SwiftUI structure. Three
config-discovering CLI wrappers (`swiftformat-smart`, `swiftlint-smart`,
`swiftlintcustom-smart`) plus a SwiftSyntax rule engine enforcing 16 custom rules
text-pattern linters cannot express (~two-thirds SwiftUI, one-third general Swift).

Delivered as thin, skippable surfaces over one engine: CLI, Xcode build phase, and
a Claude Code plugin/skill.

## Build in release mode — always

```bash
swift build -c release
cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine && swift build -c release
```

Other projects' Xcode build phases reference `.build/release/` binaries. A debug-only
build leaves those stale, so Xcode shows outdated or missing warnings. After any change:
build **release** (both the main package and the rule engine), test with
`swiftlintcustom-smart`, then commit. Never hand back control having built only debug.

## Rule identity is single-sourced

Every custom rule is defined once in `RuleRegistry.all` (in the rule engine). That is
the source of truth. Do **not** re-copy the rule list into docs — point at it:

```bash
swiftlintcustom-smart --list-rules   # authoritative list + one-line summaries
```

Adding a rule: append to `RuleRegistry.all` (id + summary), dispatch it in
`CustomRulesVisitor` using the **same** id, rebuild. The conformance test asserts the
documented lists match the registry, so an id can never silently diverge from what the
engine emits, filters, and suppresses. (This closed a real bug where the onChange rule
dispatched under `prefer_zero_param_onchange` but emitted `onchange_ignored_old_value`.)

## Configurable thresholds

Two rules take a per-project threshold via a `swift_skim:` block in `.swiftlint.yml`:

```yaml
swift_skim:
  skimmable_body_max_lines: 20      # default 15
  excessive_nesting_max_depth: 4    # default 3
```

## Warning-handling philosophy

**Every warning must be addressed — fixed properly OR exempted with a justified
suppression directive.** Not acceptable: ignoring warnings ("they were there before"),
dismissing them as unimportant, committing with unaddressed warnings, or degrading code
to silence a warning.

Before "fixing" a warning, ask: does this change improve the code or make it worse? If
you cannot improve it and the code is correct as-is, add a suppression **with a reason**.
If the code has a real problem, fix it properly.

### Suppression format

Custom rules use the `swiftlintcustom:` prefix — deliberately distinct from SwiftLint's
`swiftlint:` so SwiftLint's `superfluous_disable_command` check still works.

```swift
// Reason: <why this is intentional/correct>
// swiftlintcustom:disable:next <rule_id>
<code line>

// swiftlintcustom:disable <rule_id>
// ... block ...
// swiftlintcustom:enable <rule_id>
```

`:this` and `:previous` target the current and preceding line. If a `swiftlint:` or
`swiftformat:` directive sits immediately adjacent, they interfere (each `:next` binds
the very next line) — use `:this`/`:previous` to disambiguate.

## Architecture

- **Main tools:** `swiftformat-smart`, `swiftlint-smart`, `swiftlintcustom-smart`
  (`Sources/Swift*Smart/`), over a shared `Sources/SharedUtilities/`.
- **Rule engine:** separate SwiftPM package in
  `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/`. Rules live one-area-per-file
  in `Sources/CustomRules/*.swift`; `RuleRegistry.swift` is canonical.
- **Config discovery:** walk up for a project config, fall back to bundled `Configs/`.
- **Self-healing errors:** fixed `Problem/Context/Fix` shape an automated caller can parse.

## Testing

```bash
./Scripts/run-tests.sh   # full suite (unit + integration)
swift test               # unit only (Swift Testing)
```

Fixtures (deliberately-broken sample inputs) live in `Fixtures/` and are excluded from
linting. The tool passes its own rule set on its own source: `swiftlintcustom-smart .`
must exit clean before committing.

## Build troubleshooting

If engine changes don't take effect: `swift package clean && swift build -c release`, or
`rm -rf .build .swiftpm && swift build -c release`. The "unhandled files" warning for
`Sources/CustomRules/*.swift` is expected. First clean build is slow (SwiftSyntax);
incrementals are fast.
