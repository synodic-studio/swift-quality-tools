// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-quality-tools",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .executable(name: "swiftformat-smart", targets: ["SwiftFormatSmart"]),
        .executable(name: "swiftlint-smart", targets: ["SwiftLintSmart"]),
        .executable(name: "swiftskim", targets: ["SwiftLintCustomSmart"]),
        // The rule engine as an importable library: conform to `Rule` in your own
        // package and run it via `SwiftSkim.lint(externalRules:)`.
        .library(name: "SwiftSkim", targets: ["CustomRules"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        // Shared utilities library
        .target(
            name: "SharedUtilities",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),

        // SwiftFormat Smart executable
        .executableTarget(
            name: "SwiftFormatSmart",
            dependencies: [
                "SharedUtilities",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),

        // SwiftLint Smart executable
        .executableTarget(
            name: "SwiftLintSmart",
            dependencies: [
                "SharedUtilities",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),

        // SwiftLint Custom Smart executable
        .executableTarget(
            name: "SwiftLintCustomSmart",
            dependencies: [
                "SharedUtilities",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
        ),

        // Rule engine as a library, vended from the root so it is importable via
        // .package(url:). Shares sources with the nested rule-engine package (which
        // still builds the CLI engine binary).
        .target(
            name: "CustomRules",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            path: "CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules",
        ),

        // Tests
        .testTarget(
            name: "SharedUtilitiesTests",
            dependencies: ["SharedUtilities"],
        ),
    ],
)
