# swiftskim — Product Overview

## What it is

A Swift AST-lint engine whose primary ruleset enforces SwiftUI structure. Three CLI
executables (`swiftformat-smart`, `swiftlint-smart`, `swiftskim`) with smart
config discovery, plus 16 custom SwiftSyntax-based rules for AST-accurate analysis
(~two-thirds SwiftUI, one-third general Swift).

**What makes it distinctive:** most linters stop at detection. swiftskim closes the
loop — detection, explanation, and remediation are one system. Violations carry fix
guidance in the message itself, `ErrorFormatter` emits Problem/Context/Fix errors an
agent can act on, and the `swift-quality` skill maps each rule to a refactoring
strategy. And the docs are generated from the same `RuleRegistry` the enforcer runs:
one ruleset, one source of truth, every surface provably agrees.

**Role:** Infrastructure — enforces code quality standards across Swift projects.

## Tech stack

- **Swift 6.1+** — macOS 12.0+
- **SwiftSyntax** — AST-based custom rule engine
- **SwiftArgumentParser** — CLI interface
- **Swift Package Manager** — build system

## Current state

**Status: Active.** Heavy daily use.

- 16 custom rules, single-sourced in `RuleRegistry` (`swiftskim --list-rules`)
- 112 unit tests (Swift Testing) + integration suite
- Passes its own rule set on its own source
- Configured via a dedicated `.swiftskim.yml` (rule selection + two thresholds); rolls up
  separately from SwiftLint/SwiftFormat

## Rules

The canonical list is in `RuleRegistry.all`; run `swiftskim --list-rules`.
Grouped: **View body** (5), **View structure** (4), **Code quality** (3),
**Imports & framework** (4).

## Build note

**Must build in release mode.** Debug builds leave stale binaries that dependent projects
pick up from Xcode build phases. Always `swift build -c release`.

## Connections

- **synodic-kit** — the `swift-quality` skill provides Claude Code guidance for satisfying
  these rules; the formatter/linter runs on edit through the plugin.
- Consumed by Swift projects via Xcode build phases and the CLI.
