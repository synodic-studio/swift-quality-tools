#!/bin/bash

# Build and test SwiftLint with custom SwiftSyntax rules

set -e

cd "$(dirname "$0")/.."

echo "Building SwiftLint with custom rules using Bazel..."
bazel build //:swiftlint_with_extra_rules

echo "Running SwiftLint with custom rules on test files..."
bazel-bin/swiftlint_with_extra_rules lint \
    --config swiftlint-tests/test-custom-syntax-config.yml \
    swiftlint-tests/test-skimmable-body.swift

echo "Done!"