# swift-quality-tools — Product Overview

## What It Is

Unified Swift code quality tooling package. Three CLI executables (`swiftformat-smart`, `swiftlint-smart`, `swiftlintcustom-smart`) with smart config discovery and 12 custom SwiftSyntax-based lint rules for AST-accurate analysis.

**Role:** Infrastructure — enforces code quality standards across all Swift projects.

## Tech Stack

- **Swift 5.9+** — macOS 12.0+
- **SwiftSyntax** — AST-based custom rule engine
- **SwiftArgumentParser** — CLI interface
- **Swift Package Manager** — build system

## Current State

**Status: Active.** Heavy daily use, rules actively expanded.

- Last commit: 2026-02-24
- 535 source files (includes rule engine + tests)
- 86 unit tests, integration test suite
- Recent: `preview_required` rule updated for Shape protocol

## Custom Rules (12)

1. `skimmable_body` — 15-line max for View/ViewModifier bodies
2. `no_group_body` — no Group without modifiers
3. `one_top_level_view` — single top-level view in body
4. `no_if_modifier` — detect custom `.if` modifier anti-pattern
5. `no_if_without_else` — if without else in @ViewBuilder
6. `excessive_nesting` — max depth 3
7. `stack_minimum_children` — VStack/HStack/ZStack need 2+ children
8. `onchange_ignored_old_value` — use 0-param onChange
9. `single_modifier_per_line` — each modifier on own line
10. `no_exported_import` — prohibit @_exported import
11. `prefer_swift_testing` — prefer Swift Testing over XCTest
12. `prefer_shorthand_optional_binding` — shorthand optional binding

## Build Note

**Must build in release mode.** Debug builds leave stale binaries that dependent projects (gravity-well, etc.) pick up from Xcode build phases. Always `swift build -c release`.

## Connections

- **synodic-tools** — consumes shared configs (shared-swiftformat.yml, shared-swiftlint.yml)
- **synodic-kit** — `swift-quality` skill provides Claude Code integration
- Consumed by: every Swift project via Xcode build phases
