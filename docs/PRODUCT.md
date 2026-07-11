# swiftskim — Product Overview

## What it is

A Swift AST-lint engine whose primary ruleset enforces SwiftUI structure. Three CLI
executables (`swiftformat-smart`, `swiftlint-smart`, `swiftskim`) with smart
config discovery, plus 16 custom SwiftSyntax-based rules for AST-accurate analysis
(~two-thirds SwiftUI, one-third general Swift).

**Role:** Infrastructure — enforces code quality standards across Swift projects.

## Tech stack

- **Swift 6.1+** — macOS 12.0+
- **SwiftSyntax** — AST-based custom rule engine
- **SwiftArgumentParser** — CLI interface
- **Swift Package Manager** — build system

## Current state

**Status: Active.** Heavy daily use.

- 16 custom rules, single-sourced in `RuleRegistry` (`swiftskim --list-rules`)
- 101 unit tests (Swift Testing) + integration suite
- Passes its own rule set on its own source
- Two thresholds configurable per project via a `swiftskim:` block in `.swiftlint.yml`

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
