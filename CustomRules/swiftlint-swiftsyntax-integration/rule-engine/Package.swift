// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftLintTest",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "test-custom-rule",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: ".",
            sources: ["test-custom-rule.swift"],
        ),
    ],
)
