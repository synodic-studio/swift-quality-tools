#!/bin/bash

# Test SwiftSyntax-based rule without full Bazel setup

set -e

cd "$(dirname "$0")/.."

echo "Testing SwiftSyntax-based skimmable body rule..."

# Create a minimal Package.swift for testing
cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftLintTest",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .executableTarget(
            name: "test-custom-rule",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: ".",
            sources: ["test-custom-rule.swift"]
        )
    ]
)
EOF

echo "Building test executable..."
swift build

if [ $# -eq 0 ]; then
    echo "Running test on skimmable body test file..."
    .build/debug/test-custom-rule swiftlint-tests/test-skimmable-body.swift
else
    echo "Running test on file: $1"
    .build/debug/test-custom-rule "$1"
fi

echo "Cleaning up..."
rm -rf .build Package.swift Package.resolved

echo "Test complete!"