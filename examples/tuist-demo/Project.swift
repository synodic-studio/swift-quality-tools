// swiftformat:disable acronyms
// (Tuist's API label is `bundleId`; the acronyms rule would rewrite it to bundleID.)
import ProjectDescription

/// A standalone macOS unit-test bundle that imports the SwiftSkim library (via the
/// external SwiftPM product) and runs it. `tuist test` builds and executes it, which
/// proves the library is consumable through Tuist's SwiftPM integration.
let project = Project(
    name: "TuistDemo",
    targets: [
        .target(
            name: "TuistDemoTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "co.synodic.swiftskim.tuistdemo.tests",
            sources: ["Tests/**"],
            dependencies: [.external(name: "SwiftSkim")],
        ),
    ],
)
