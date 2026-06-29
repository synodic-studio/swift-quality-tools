---
type: proof
title: AST-based nesting depth rule replacing physical indentation
capability: AST-based nesting depth analysis
kind: designed
tags: [SwiftSyntax, AST traversal, code complexity measurement, static analysis]
created: 2025-11-19
confidence: 0.95
sources: [277f9500]
---
Replaced a physical indentation rule (max 16 spaces) with an AST-based excessive_nesting rule that tracks code block depth (max 3 levels). By visiting both CodeBlockSyntax and ClosureExprSyntax nodes, the rule accurately measures nesting in functions, if statements, and SwiftUI view builders. This avoids the classic problem of indentation-based checks flagging long modifier chains (e.g., .padding().background().cornerRadius()) as excessive depth, since modifiers don't increase AST nesting. The rule uncovered 55 violations in the tools repo itself and 100+ in a production codebase (gravity-well), driving genuine view extraction.
