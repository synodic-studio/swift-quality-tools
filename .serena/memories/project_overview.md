# Project Overview

## Purpose
Swift Quality Tools is a centralized code quality tooling package providing unified interfaces for SwiftFormat, SwiftLint, and custom SwiftSyntax-based rules with smart configuration discovery.

## Tech Stack
- Swift 6.0+
- SwiftSyntax for custom linting rules
- ArgumentParser for CLI interfaces
- Swift Package Manager

## Structure
- `Sources/SwiftFormatSmart/` - SwiftFormat wrapper with config discovery
- `Sources/SwiftLintSmart/` - SwiftLint wrapper with config discovery  
- `Sources/SwiftLintCustomSmart/` - Custom SwiftSyntax rules runner
- `Sources/SharedUtilities/` - Shared utilities for all tools
- `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/` - SwiftSyntax rule engine
- `Configs/` - Shared SwiftFormat and SwiftLint configurations

## Custom Rules
- `skimmable_body` - SwiftUI View body 15-line limit
- `no_group_body` - Prohibit top-level Group in View bodies
- `one_top_level_view` - Single top-level view in View bodies
- `excessive_nesting` - 4-level indentation depth limit
