import SwiftSyntax

/// Rules for SwiftUI onChange modifier usage
/// - onchange_ignored_old_value: Detect 2-param onChange with ignored old value
public enum OnChangeRules {
    /// Check for onChange with 2 parameters where the old value is ignored
    ///
    /// BAD:  .onChange(of: value) { _, newValue in use(newValue) }
    /// GOOD: .onChange(of: value) { use(value) }
    ///
    /// The 0-parameter version is more readable and semantically clearer
    public static func checkOnChangeIgnoredOldValue(_ node: FunctionCallExprSyntax, violations: inout [String]) {
        // Check if this is an onChange call
        guard isOnChangeCall(node) else { return }

        // Get the trailing closure
        guard let trailingClosure = node.trailingClosure else { return }

        // Check if it has a closure signature with parameters
        guard let signature = trailingClosure.signature else { return }

        // Check parameter clause type
        switch signature.parameterClause {
        case let .simpleInput(params):
            guard params.count == 2 else { return }

            let firstParam = params.first!
            let firstName = firstParam.name.text

            guard firstName == "_" || firstName.hasPrefix("_") else { return }

            let secondParam = params.last!
            let secondName = secondParam.name.text

            let violation = "⚠️  [onchange_ignored_old_value] Use 0-parameter onChange when old value is ignored - replace '{ \(firstName), \(secondName) in ...' with '{ ... }' and reference the observed value directly"
            violations.append(violation)

        case .parameterClause, .none:
            return
        }
    }

    /// Check if a function call is an onChange modifier
    private static func isOnChangeCall(_ node: FunctionCallExprSyntax) -> Bool {
        // Check if the called expression contains "onChange"
        let callText = node.calledExpression.description.trimmingCharacters(in: .whitespaces)
        return callText.contains("onChange")
    }
}
