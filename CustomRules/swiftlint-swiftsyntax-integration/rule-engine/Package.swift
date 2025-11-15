// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftLintCustomRules",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "test-custom-rule", targets: ["test-custom-rule"]),
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
            ],
            path: "Sources/CustomRules",
        ),
        // Executable target for CLI
        .executableTarget(
            name: "test-custom-rule",
            dependencies: [
                "CustomRules",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "Sources",
            sources: ["main.swift"],
        ),
    ],
)
