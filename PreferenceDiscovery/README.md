# Swift Preference Discovery

Systematic framework for discovering and codifying implicit Swift coding preferences through edge case review.

## Purpose

Extract unstated coding preferences by presenting intentional variations and recording decisions. Converts implicit knowledge into:

- **SwiftSyntax Rules**: Mechanical enforcement of clear preferences
- **apple-platform-dev Skill**: Workflow guidance for context-dependent decisions
- **CLAUDE-SWIFT.md**: Critical reminders for anti-patterns

## Files

### PreferenceDiscovery.swift
**52 intentional code variations across 6 categories:**

- **A. Property Wrapper Ordering** (8 examples): `@State private` vs `private @State`, multiple wrappers, type annotations
- **B. View Body Edge Cases** (10 examples): 15/16 line boundaries, ViewModifier rules, computed property patterns
- **C. Naming Conventions** (10 examples): View suffix, boolean prefixes, handler naming, preview naming
- **D. Constants Patterns** (8 examples): Placement, magic number thresholds, extraction criteria, namespace organization
- **E. Architecture Boundaries** (10 examples): Extract thresholds, file organization, extension usage, nested types
- **F. Preview Patterns** (6 examples): Multiple vs single, minimal vs realistic, dependency handling

### PREFERENCE_TRACKING.md
**Structured template for recording decisions:**

Each example includes:
- Accept / Reject / Context-Dependent decision
- Reasoning (why does this matter?)
- Confidence level (Strong / Moderate / Weak)
- Implementation path (SwiftSyntax / Skill / CLAUDE-SWIFT / None)

### SESSION_GUIDE.md
**Complete facilitation guide for 90-120 minute session:**

- Session structure and timing
- Recording guidelines
- Decision quality criteria
- Implementation criteria
- Post-session action plan
- Success metrics

## Quick Start

### Prerequisites

1. **Phase 3 Complete**: Documentation consolidation finished
2. **Time Available**: 90-120 minutes uninterrupted
3. **Mental State**: Fresh, not fatigued

### Session Flow

1. **Review SESSION_GUIDE.md** (10 minutes)
2. **Open PreferenceDiscovery.swift** in Xcode
3. **Open PREFERENCE_TRACKING.md** in editor
4. **Work through categories** systematically
5. **Record decisions** with reasoning
6. **Review for consistency** (15 minutes)
7. **Plan implementation** (15 minutes)

### Post-Session

1. **Implement 2-3 high-priority rules** (SwiftSyntax)
2. **Update apple-platform-dev skill** (workflow frameworks)
3. **Add critical reminders** (CLAUDE-SWIFT.md)
4. **Create test suite** from examples
5. **Commit discoveries** as reference

## Expected Outcomes

**Quantitative:**
- 10-15 strong preferences → automated rules
- 15-20 context-aware patterns → skill guidance
- 10-15 observations → documented for future
- 2-5 new SwiftSyntax rules
- 3-5 skill decision frameworks

**Qualitative:**
- Explicit implicit knowledge
- Reduced decision friction
- Consistent codebase
- Efficient code reviews
- Future-proof rationale

## Integration with Phase 3

Phase 4 Alpha builds on Phase 3 consolidation:

**Phase 3 Outputs:**
- apple-platform-dev skill (15-line body rule, violation workflow)
- CLAUDE-SWIFT.md (157 lines, critical reminders only)
- 9 SwiftSyntax rules (documented and tested)

**Phase 4 Alpha Adds:**
- Systematic edge case discovery
- Preference codification methodology
- Decision framework documentation
- Continuous improvement process

## Methodology

Based on research across:
- **Preference Elicitation**: Choice-based queries, ~10 query sessions, context-rich scenarios
- **Edge Case Discovery**: Boundary testing, equivalence partitioning, systematic exploration
- **Pattern Mining**: Frequency analysis, anomaly detection, expert curation
- **UX Research**: Qualitative probing, decision consistency, confidence rating

## Future Sessions

**Quarterly Preference Discovery:**
1. Review swift-edits.yml for new patterns
2. Monitor "observation" cases for emerging preferences
3. Validate existing rules against usage
4. Refine based on feedback
5. Expand to new categories

**Continuous Improvement:**
- Add examples as edge cases discovered
- Update based on tooling evolution
- Integrate community best practices
- Maintain decision rationale

## License

Part of swift-quality-tools package.
Preference discovery framework and examples available for Swift development teams.
