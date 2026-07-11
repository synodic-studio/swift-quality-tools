// swift-tools-version: 6.0
import PackageDescription

/// A complete "build your own linter" example: depend on swiftskim's SwiftSkim library,
/// add a custom Rule, and run it alongside the 16 built-ins. This is the supported way to
/// add rules without forking swiftskim — the same model the swift-syntax ecosystem uses.
let package = Package(
    name: "custom-rule-linter",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/synodic-studio/swiftskim.git", from: "1.0.0"),
        // A rule authors its check over a SourceFileSyntax, so the consumer needs
        // swift-syntax directly. SwiftPM unifies the version with swiftskim's own.
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "custom-rule-linter",
            dependencies: [
                // The product is `SwiftSkim`; its module is `CustomRules` (what you import).
                .product(name: "SwiftSkim", package: "swiftskim"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
        ),
    ],
)
