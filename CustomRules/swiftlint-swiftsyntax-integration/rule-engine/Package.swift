// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftLintCustomRules",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "swift-skim-engine", targets: ["swift-skim-engine"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Library target containing all rule modules
        .target(
            name: "CustomRules",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources/CustomRules",
        ),
        // Executable target for CLI
        .executableTarget(
            name: "swift-skim-engine",
            dependencies: [
                "CustomRules",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources",
            sources: ["main.swift"],
        ),
        // Tests for the public Rule extensibility API.
        .testTarget(
            name: "CustomRulesTests",
            dependencies: ["CustomRules"],
            path: "Tests/CustomRulesTests",
        ),
    ],
)
