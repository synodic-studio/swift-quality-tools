// swift-tools-version: 5.9
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings()
#endif

/// Tuist reads this manifest to resolve external SwiftPM dependencies. The demo
/// depends on the public `SwiftSkim` product at the shipped tagged release, the way
/// a real consumer pins it.
let package = Package(
    name: "TuistDemo",
    dependencies: [
        .package(url: "https://github.com/synodic-studio/swiftskim.git", from: "1.0.0"),
    ],
)
