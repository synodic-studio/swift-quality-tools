# TODO: Consider Removing excessive_indentation Rule

**Created**: 2025-11-18
**Status**: Active rule, consider for future removal

## Context

The `excessive_indentation` rule enforces a maximum of 16 spaces (4 tabs) of physical indentation. While this helps catch deeply nested code, it may be too strict for real-world codebases.

## Current Implementation

- **Rule**: `excessive_indentation`
- **Limit**: 16 spaces (4 tabs × 4 spaces)
- **Enforcement**: Physical line-by-line space counting
- **Location**: `CustomRules/swiftlint-swiftsyntax-integration/rule-engine/Sources/CustomRules/CodeQualityRules.swift`

## Rationale for Potential Removal

1. **SwiftFormat handles indentation** - Already have automated formatting that manages indentation
2. **Architectural rules are better** - Focus on high-level violations (body line count, no Group wrappers) rather than low-level formatting
3. **Edge cases exist** - Some legitimate code patterns require deeper nesting (complex closures, builder patterns)
4. **Already refactored** - Most violations have been fixed in PR #7, so the immediate value is diminished

## Decision Criteria

Consider removing if:
- SwiftFormat adequately handles indentation concerns
- The rule creates more noise than value in practice
- Developers frequently need to work around it for legitimate code
- Other architectural rules provide better signal

Consider keeping if:
- Rule catches real architectural problems that SwiftFormat can't
- Teams find the 16-space limit useful for code reviews
- It prevents actual maintenance issues in practice

## Alternative Approaches

If removed, consider:
1. **Rely on SwiftFormat** - Let automated formatting handle indentation consistency
2. **Code review guidelines** - Document in CLAUDE-SWIFT.md that deep nesting should be avoided
3. **Higher-level rules** - Focus on rules like `skimmable_body`, `no_group_body` that catch architectural issues
4. **Increase limit** - If the rule is useful but too strict, increase to 20-24 spaces

## Action Items

- [ ] Monitor violation frequency over next few months
- [ ] Gather team feedback on whether rule is helpful or noisy
- [ ] Evaluate if SwiftFormat alone is sufficient
- [ ] Make decision by Q1 2025

## References

- PR #6: Refactored excessive_nesting → excessive_indentation
- PR #7: Fixed all 66 violations in swift-quality-tools
- CLAUDE.md: Rule documentation
