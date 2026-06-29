---
type: proof
title: Swiftlint:ignore directive support for custom SwiftSyntax rules
capability: SwiftLint directive integration for custom rules
kind: built
tags: [SwiftSyntax, directive parsing, rule suppression, developer experience]
created: 2025-11-24
confidence: 0.9
sources: [635f8682]
---
Added a DirectiveParser that tokenizes source comments looking for // swiftlint:disable:next and // swiftlint:disable:this patterns, filtering violations from the CustomRulesVisitor output. The parser supports multiple rule IDs per directive and associates suppressions with specific line numbers. This allows developers to handle false positives or intentional violations without losing overall rule coverage. The implementation uses the same syntax as SwiftLint, so no new annotation format is needed. File-level disable/enable was deferred due to range tracking complexity, but the line-level coverage addresses the most common suppression needs.
