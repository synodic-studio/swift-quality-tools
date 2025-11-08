# Installing Bazel for SwiftLint Custom Rules

## Option 1: Using Homebrew (Recommended)
```bash
brew install bazel
```

## Option 2: Using Bazelisk (Bazel Version Manager)
```bash
brew install bazelisk
```

## After Installation

1. Build SwiftLint with custom rules:
```bash
cd synodic-tools
bazel build //:swiftlint_with_extra_rules
```

2. Run tests:
```bash
./swiftlint-tests/build-and-test-custom-rules.sh
```

3. Use the custom SwiftLint binary:
```bash
bazel-bin/swiftlint_with_extra_rules lint --config shared-swiftlint.yml
```

## Integration with Existing Workflow

Once built, you can replace your regular swiftlint command with the Bazel-built version that includes your custom SwiftSyntax rules.