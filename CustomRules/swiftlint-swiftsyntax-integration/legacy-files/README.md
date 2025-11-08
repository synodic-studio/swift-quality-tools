# Legacy Files

This directory contains experimental and deprecated files from the SwiftSyntax integration development process.

## What's Here

### Bazel-Based Approach (Deprecated)
- `BUILD.bazel`, `MODULE.bazel`, `.bazelrc` - Bazel build configuration
- `INSTALL_BAZEL.md` - Bazel installation guide
- `main.swift` - Custom SwiftLint binary entry point
- `swiftlint_extra_rules/` - Bazel-based rule implementation

### Old Scripts (Superseded)
- `xcode-swiftlint-*.sh` - Various Xcode integration attempts
- `run-swiftsyntax-rule.sh` - Old manual runner
- `swiftlint-custom` - CLI wrapper script
- `git-pre-commit-hook` - Git hook integration
- `check-swiftsyntax-rules.swift` - Direct Swift implementation attempt
- `test-custom-rule.swift` - Standalone rule test

### Test Infrastructure (Moved)
- `test-swiftsyntax-rule.sh` - Old test runner
- `build-and-test-custom-rules.sh` - Bazel-based test script
- `test-custom-syntax-config.yml` - Test configuration

## Why Deprecated

1. **Bazel Complexity**: Required complex build setup
2. **Performance Issues**: Some approaches were too slow
3. **Integration Problems**: Difficult to integrate with existing workflows
4. **Superseded**: Better solutions implemented in parent directory

## Current Solution

The working solution is in the parent directory:
- Simple Swift Package Manager approach
- Fast, reliable scripts
- Easy Xcode integration
- Comprehensive documentation

These files are kept for reference but are not needed for the current implementation.