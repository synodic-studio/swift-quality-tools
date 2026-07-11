# Example: your own rule, no fork

A complete ~60-line linter that runs swiftskim's 16 built-in rules **plus a rule of your
own** (`no_print_statements`), by depending on the `SwiftSkim` library — no fork of
swiftskim required. This is the supported way to add rules: compose your own tool against
the library, the same model the swift-syntax ecosystem uses.

```bash
swift run custom-rule-linter                 # lints a built-in demo snippet
swift run custom-rule-linter path/to/*.swift # lints your files
```

## How it works

1. `Package.swift` depends on `swiftskim` (product `SwiftSkim`, module `CustomRules`) and
   on `swift-syntax` (your rule's `check` receives a `SourceFileSyntax`).
2. `Sources/custom-rule-linter/main.swift` conforms a `NoPrintStatements` type to the
   `Rule` protocol and hands it to `SwiftSkim.lint(source:externalRules:)`. Its violations
   come out in the same format as the built-ins and honor `swiftskim:disable` the same way.

`SwiftSkim.lint` also takes `only:` / `disabled:` to filter the combined set of built-in
and custom rules by id, and `runBuiltIns: false` to run only your rules.
