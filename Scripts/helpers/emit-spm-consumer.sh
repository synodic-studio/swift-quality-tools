# Shared helper: write a throwaway SwiftPM package that consumes the public
# `SwiftSkim` library product exactly as an external user would — depending on the
# package, conforming a custom `Rule`, and calling `SwiftSkim.lint`.
#
# Sourced by the macOS (host) and Linux (container) consumer verifications so the
# consumer code never drifts between them.
#
#   emit_spm_consumer <target_dir> <swiftskim_dependency_line> <package_identity>
#
# where <swiftskim_dependency_line> is a PackageDescription dependency, e.g.
#   '.package(path: "/abs/path/to/swiftskim")'
#   '.package(url: "https://github.com/synodic-studio/swiftskim.git", branch: "develop")'
# and <package_identity> is the SwiftPM identity of that dependency, used as the
# `package:` label in `.product(...)`. For a path dependency this is the directory
# basename (e.g. "swiftskim"); for a URL dependency it is the URL's last
# path component minus ".git" (e.g. "swiftskim").

emit_spm_consumer() {
    local dir="$1"
    local dep="$2"
    local pkgid="$3"

    mkdir -p "$dir/Sources/SwiftSkimConsumer"

    cat > "$dir/Package.swift" <<EOF
// swift-tools-version: 5.9
import PackageDescription

// A consumer that authors its own \`Rule\` needs swift-syntax directly, since
// \`Rule.check\` takes a \`SourceFileSyntax\`. SwiftPM unifies the version with
// swiftskim's own swift-syntax requirement.
// No trailing commas after the final call argument: portable to -swift-version 5
// (the Linux container rejects function-call trailing commas that macOS accepts).
let package = Package(
    name: "SwiftSkimConsumer",
    platforms: [.macOS(.v12)],
    dependencies: [
        $dep,
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftSkimConsumer",
            dependencies: [
                .product(name: "SwiftSkim", package: "$pkgid"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ]
        )
    ]
)
EOF

    cat > "$dir/Sources/SwiftSkimConsumer/main.swift" <<'EOF'
import CustomRules
import Foundation
import SwiftSyntax

/// A trivial external rule: flag any struct named `Foo`.
struct NoStructNamedFoo: Rule {
    let id = "no_struct_named_foo"
    let summary = "A struct may not be named Foo"
    func check(_ file: SourceFileSyntax, context: RuleContext) -> [Violation] {
        var hits: [Violation] = []
        for stmt in file.statements {
            guard let decl = stmt.item.as(StructDeclSyntax.self), decl.name.text == "Foo" else { continue }
            let line = context.converter.location(for: decl.name.positionAfterSkippingLeadingTrivia).line
            hits.append(Violation(ruleID: id, line: line, message: "struct named Foo"))
        }
        return hits
    }
}

// Bad input: a struct named Foo (external rule) whose body is a bare Group (built-in).
let bad = """
import SwiftUI
struct Foo: View {
    var body: some View {
        Group {
            Text("hi")
        }
    }
}
"""

let violations = SwiftSkim.lint(source: bad, externalRules: [NoStructNamedFoo()])
let joined = violations.joined(separator: "\n")

var ok = true
if !joined.contains("no_struct_named_foo") {
    print("FAIL: external rule did not fire"); ok = false
}
if violations.count < 2 {
    print("FAIL: expected a built-in violation alongside the external rule; got \(violations.count)"); ok = false
}

let clean = SwiftSkim.lint(source: "let x = 1\n", externalRules: [NoStructNamedFoo()])
if !clean.isEmpty {
    print("FAIL: clean source reported \(clean)"); ok = false
}

if ok {
    print("OK: SwiftSkim library consumer verified (\(violations.count) violations on bad input)")
} else {
    print("---- violations ----")
    for v in violations { print(v) }
    exit(1)
}
EOF
}
