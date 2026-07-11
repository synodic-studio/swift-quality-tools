# swiftskim pi extension

A [pi](https://github.com/earendil-works) coding-agent extension that exposes
swiftskim as agent tools, so a pi agent can lint Swift with the same AST rules the
CLI runs.

## Tools

- **`swiftskim_lint`** — run the custom SwiftSyntax rules on a file or directory
  (optionally filtered to specific rule ids). Returns the violations.
- **`swiftskim_list_rules`** — list every rule id with its one-line summary.

## Requirements

The `swiftskim` binary must be resolvable:

- on `PATH` (`brew install synodic-studio/synodic/swiftskim`), or
- via the `SWIFTSKIM_BIN` environment variable pointing at the binary.

## Use

Point your pi agent at `tools.ts` as an extension (see pi's extension docs). The
tools call `swiftskim` with argv arrays (no shell), paths are contained to the
project directory, and `only_rules` is allowlisted to `snake_case` ids — so agent
input cannot inject commands.

This is one of several thin surfaces over the same engine; see the repo README for
the CLI, Xcode build phase, and Claude Code plugin.
