# tuist-demo

A minimal [Tuist](https://tuist.dev) project that consumes the public `SwiftSkim`
library as an external SwiftPM dependency and exercises it in a macOS unit-test
target — proof that SwiftSkim is usable from a Tuist-managed app, not just raw SwiftPM.

## Layout

- **`Package.swift`** — declares the `swiftskim` SwiftPM dependency Tuist resolves.
- **`Project.swift`** — a `.unitTests` target depending on `.external(name: "SwiftSkim")`.
- **`Tests/DemoTests.swift`** — imports `CustomRules` and calls `SwiftSkim.lint(...)`.

The imported module is `CustomRules` (the target inside the `SwiftSkim` product).

## Run it

```bash
tuist install            # resolve the SwiftSkim package
tuist generate --no-open # generate the Xcode project (never opens Xcode)
tuist test               # build + run the demo test
```

Or, from the repo root: `Scripts/verify-tuist-demo.sh`.
