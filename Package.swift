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
        .executable(name: "swift-skim", targets: ["SwiftLintCustomSmart"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
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

        // Tests
        .testTarget(
            name: "SharedUtilitiesTests",
            dependencies: ["SharedUtilities"],
        ),
    ],
)
