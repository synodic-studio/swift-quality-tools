# Design decisions

The load-bearing choices behind swiftskim and *why* — the rationale that the code and
commit messages don't capture on their own. Newest context first within each entry.

## Identity: an opinionated orchestrator, not a neutral linter

swiftskim drives your installed **SwiftFormat + SwiftLint** (both required) alongside its
own SwiftSyntax engine, and ships an opinionated default config (`Configs/`) encoding a
house style. That coupling is the point, not an accident. The genuinely novel,
style-neutral part is the AST engine and its importable `SwiftSkim` library — everything
else is convenience wrappers over tools you already run. Owned plainly in the README's
"What it is (and isn't)".

## Name: `swiftskim` (single token)

No hyphen, so it sits in the `swiftlint` / `swiftformat` family and works as a command,
a module (`SwiftSkim`), an env prefix (`SWIFTSKIM_HOME`), and the directive prefix
(`swiftskim:`). The flagship rule `skimmable_body` is the thesis: code you can skim.

## Swift 6.1 is the floor — own "modern Swift"

The codebase uses SE-0439 function-call trailing commas, enforced repo-wide by
swiftformat. Only a Swift 6.1+ toolchain parses them. We keep them and state a 6.1+ floor
rather than lower the shared formatting config fleet-wide. `Package.swift` keeps
tools-version 5.9 deliberately (bumping risks flipping to the Swift 6 language mode /
strict concurrency); a comment there records the effective floor.

## Rule identity is single-sourced

Every rule is defined once in `RuleRegistry`. `--list-rules` prints from it; `--help`
points there rather than copying. `RuleConformanceTests` locks the registry against the
engine's dispatch sites, so a rule can't be enforced under one id and emitted/suppressed
under another (a real bug this closed: dispatched `prefer_zero_param_onchange`, emitted
`onchange_ignored_old_value`). Prose rule lists in docs are convenience indexes, not the
source of truth.

## Configuration: a dedicated `.swiftskim.yml`

swiftskim's rules roll up **separately** from SwiftLint and SwiftFormat — each owns its
own file. `.swiftskim.yml` governs rule selection (`disabled_rules` / `only_rules`) and
the two thresholds. It deliberately does **not** configure file selection: exclusions
stay shared from `.swiftlint.yml`'s `excluded:`, so the config layers rules on top of the
file set you already lint. Precedence: CLI `--only-rules` fully overrides config
selection; in-config `only_rules` beats `disabled_rules`. Unknown rule ids are a hard
error (exit 2), never a silent no-op. Legacy fallback: a `swiftskim:` block in
`.swiftlint.yml` still supplies thresholds when no `.swiftskim.yml` exists.

## Extensibility: a library, not runtime plugins

The CLI takes **no** runtime rule plugins — dynamically loading compiled Swift into a
linter is fragile, and avoiding it keeps the CLI one fast tree walk. Adding a rule off the
shelf means composing your own linter against the `SwiftSkim` library (conform to `Rule`,
call `SwiftSkim.lint`), the same model the swift-syntax ecosystem uses. External rules run
in the same walk as built-ins and share suppression, id filtering, and output. Runnable
example: `examples/custom-rule/`. Contributing a *built-in* rule is a different path:
`RuleRegistry` + `CustomRulesVisitor` + rebuild.

## Suppression: `swiftskim:` prefix

Deliberately distinct from SwiftLint's `swiftlint:` so SwiftLint's
`superfluous_disable_command` check still works. The older `swiftlintcustom:` prefix
remains a working legacy alias (`DirectiveParser` generalizes over a prefix list).

## Release model: git tags, no release branch

For this public repo we use annotated semver tags (`v1.0.0`); the Homebrew formula pins
the tag via git `tag:`/`revision:` — reproducible, with **no tarball hosting** (keeps the
shop's "no tarball releases" spirit). `--HEAD` still tracks `develop`. `develop` stays the
working branch; there is no separate `release`/`production` branch, because tags already
mark shipped points and a release branch would add merge ceremony that buys nothing. This
is a deliberate exception to the shop's default HEAD-only formulas, justified because this
is the one public, portfolio-facing tool where reproducibility matters.

## Release gate verifies the shipped artifact

`Scripts/verify-all.sh` checks every delivery surface. Its `--release` stage consumes the
**shipped tag** — brew (stable install), SPM (`from:<tag>`), Linux clean-room
(`from:<tag>`), and the Tuist demo (`from:<tag>`) all resolve the exact artifact the
public installs, not the current branch. The local stage covers HEAD via a path-dependency
consumer. This is what makes "what we document, verify, and ship are the same thing" true
rather than aspirational.

## Delivery surfaces

One engine, several thin skippable surfaces: CLI / Homebrew, Xcode build phase, the
`SwiftSkim` SwiftPM library, a Claude Code plugin (verified), Codex and Cursor hooks
(**best-effort — built to documented payload shapes, checked with synthetic events, not
fired in a live session; the hook fails open**), and a pi extension. No MCP server — the
plugin hooks cover the agents directly, by design.

## Package layout

A single root SwiftPM package emits all four binaries; SwiftSyntax compiles once. (The
rule engine was formerly a nested package; the deep source path under
`CustomRules/swiftlint-swiftsyntax-integration/rule-engine/` is a leftover from that.)
