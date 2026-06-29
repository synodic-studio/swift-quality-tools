---
type: proof
title: Smart configuration discovery with project-aware fallback chain
capability: Hierarchical configuration discovery
kind: built
tags: [file system traversal, configuration management, tooling design]
created: 2025-11-07
confidence: 0.95
sources: [98744e40]
---
Designed and implemented a ConfigDiscovery subsystem shared across three command-line tools (swiftformat-smart, swiftlint-smart, swiftlintcustom-smart). Given a file path or directory, it looks for .swiftformat.yml or .swiftlint.yml in the current directory, then walks up parent directories until a match is found. If none is found, it falls back to shared configs in the Configs/ directory of this tooling repository. This means a developer can run any tool from anywhere in their project and get the correct configuration without manually specifying paths. The system supports explicit --config overrides and handles edge cases like multiple configs in nested directories. This pattern is now the foundation for all quality tooling workflows in the organization.
