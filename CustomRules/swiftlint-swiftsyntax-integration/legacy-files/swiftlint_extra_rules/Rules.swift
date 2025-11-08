import SwiftLintFramework

/// Entry point that SwiftLint calls to get custom rules
public func extraRules() -> [any Rule.Type] {
    [
        SkimmableBodyRule.self,
        NoGroupBodyRule.self,
        OneTopLevelViewRule.self,
    ]
}
