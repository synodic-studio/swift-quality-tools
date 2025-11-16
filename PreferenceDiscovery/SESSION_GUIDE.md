# Phase 4 Alpha: Preference Discovery Session Guide

## Overview

This systematic preference discovery session extracts implicit Swift coding preferences by presenting intentional edge cases and recording decisions. The goal is to convert unstated preferences into automated enforcement (SwiftSyntax rules), workflow guidance (apple-platform-dev skill), or critical reminders (CLAUDE-SWIFT.md).

## Prerequisites

**Before Starting:**
- ✅ Phase 3 completed (documentation consolidation)
- ✅ All SwiftSyntax rules documented and tested
- ✅ Current toolchain baseline established
- ✅ 60-120 minutes available (uninterrupted)
- ✅ PreferenceDiscovery.swift file ready
- ✅ PREFERENCE_TRACKING.md template ready

**Mental Preparation:**
- This is discovery, not validation - there are no "right" answers
- Some preferences may surprise you ("I didn't know I cared about that!")
- Context-dependent answers are valid and valuable
- Weak preferences are okay to document for future observation

## Session Structure

**Total Time**: 90-120 minutes

### Phase 1: Introduction (5 minutes)

**Purpose**: Set context and expectations

**Key Points:**
- Goal: Discover implicit preferences through systematic review
- Format: Binary choices with reasoning
- Output: Codified rules, skill guidance, or documented observations
- Emphasis: No pressure to have strong opinions on everything

### Phase 2: Category Review (75-90 minutes)

Review each category systematically. For each example:

1. **Present Code**: Show the variation
2. **Initial Reaction**: Accept / Reject / Context-Dependent
3. **Probe Reasoning**: "Why does this matter? What makes it better/worse?"
4. **Rate Confidence**: Strong / Moderate / Weak
5. **Note Implementation**: Where should this guidance live?

**Category Breakdown:**

| Category | Examples | Est. Time |
|----------|----------|-----------|
| A. Property Wrapper Ordering | 8 | 10 min |
| B. View Body Edge Cases | 10 | 15 min |
| C. Naming Conventions | 10 | 15 min |
| D. Constants Patterns | 8 | 10 min |
| E. Architecture Boundaries | 10 | 20 min |
| F. Preview Patterns | 6 | 10 min |

**Pacing Strategy:**
- Start with simpler categories (A, D) to build momentum
- Move to complex/subjective categories (E, C) when warmed up
- Take 5-minute break after 45 minutes

### Phase 3: Synthesis (15 minutes)

**Review for Consistency:**
- Check related decisions for contradictions
- Identify patterns across categories
- Clarify context-dependent frameworks

**Example Consistency Checks:**
- If "View" suffix rejected → Check file naming preference
- If constants at top accepted → Check initialization order
- If extraction threshold defined → Check new View creation threshold

### Phase 4: Codification Planning (15 minutes)

**Categorize Discoveries:**

**Strong Preferences → SwiftSyntax Rules:**
- Clear mechanical pattern
- Unambiguous enforcement
- Example: "Property wrappers must precede access modifiers"

**Moderate Preferences → Skill Guidance:**
- Context-dependent decisions
- Workflow-oriented
- Example: "Extract to new View when reused OR exceeds 10 lines"

**Weak/Contextual → CLAUDE-SWIFT.md:**
- Critical anti-patterns
- Quick reference reminders
- Example: "Prefer descriptive preview names for complex states"

**Uncertain → Document for Observation:**
- No clear preference yet
- Monitor in future development
- Example: "Boolean property naming prefix (is/has/shows)"

## Recording Guidelines

### Decision Format

For each example, record:

```markdown
### [Example ID]: [Description]
- **Decision**: [Accept / Reject / Context]
- **Reasoning**: [1-2 sentences explaining why]
- **Confidence**: [Strong / Moderate / Weak]
- **Implementation**: [SwiftSyntax / Skill / CLAUDE-SWIFT / None]
```

### Context-Dependent Template

When decision depends on context:

```markdown
**Context Rule**: [Describe the decision framework]

**Accept when**: [Specific conditions]
**Reject when**: [Specific conditions]

**Example Accept**: [Code snippet]
**Example Reject**: [Code snippet]
```

## Best Practices

### During Review

**DO:**
- ✅ Trust initial reactions - they reveal implicit preferences
- ✅ Explain reasoning out loud (captures decision framework)
- ✅ Mark "weak" confidence honestly - valuable data
- ✅ Note "I don't care" - helps focus automation efforts
- ✅ Take breaks to maintain decision quality

**DON'T:**
- ❌ Second-guess gut reactions
- ❌ Force strong opinions where none exist
- ❌ Rush through examples (quality > speed)
- ❌ Skip reasoning - "I just prefer it" isn't enough
- ❌ Ignore context - many good patterns depend on situation

### Reasoning Quality

**Good Reasoning Examples:**

**Weak**: "I like it better"
**Better**: "Looks cleaner"
**Best**: "Reduces cognitive load by making property type immediately visible before scanning right to wrapper details"

**Weak**: "That's wrong"
**Better**: "Violates convention"
**Best**: "Conflicts with SwiftFormat's expected modifier ordering, creates friction with tooling"

### Implementation Criteria

**SwiftSyntax Rule Criteria:**
- ✅ Can be detected mechanically via AST
- ✅ Unambiguous enforcement (no gray areas)
- ✅ Applies broadly across projects
- ✅ Strong or moderate preference

**Skill Guidance Criteria:**
- ✅ Requires context or judgment
- ✅ Workflow-oriented decision
- ✅ Can be explained with examples
- ✅ Moderate preference or context-dependent

**CLAUDE-SWIFT.md Criteria:**
- ✅ Critical anti-pattern
- ✅ Easy to forget
- ✅ Needs quick reference reminder
- ✅ Strong preference but hard to automate

**No Action Criteria:**
- ✅ Weak or no preference
- ✅ Purely stylistic (no impact)
- ✅ Too context-dependent to codify
- ✅ Document for future observation

## Post-Session Actions

### Immediate (Same Day)

1. **Review** tracking template for completeness
2. **Identify** top 5 high-priority rules
3. **Draft** implementation plan with timeline
4. **Document** uncertain cases for monitoring

### Short-Term (Within Week)

1. **Implement** 2-3 high-priority SwiftSyntax rules
2. **Update** apple-platform-dev skill with frameworks
3. **Add** critical reminders to CLAUDE-SWIFT.md
4. **Create** test suite from examples
5. **Commit** PreferenceDiscovery.swift as reference

### Long-Term (Quarterly)

1. **Monitor** swift-edits.yml for new patterns
2. **Review** "observation" cases for emerging preferences
3. **Validate** rules against real-world usage
4. **Refine** based on feedback and friction
5. **Schedule** next preference discovery session

## Expected Outcomes

### Quantitative Goals

- **Strong Preferences**: 10-15 clear decisions
- **Moderate Preferences**: 15-20 context-aware decisions
- **Weak/None**: 10-15 documented observations
- **New SwiftSyntax Rules**: 2-5 high-priority rules
- **Skill Updates**: 3-5 decision frameworks
- **CLAUDE-SWIFT Additions**: 2-3 critical reminders

### Qualitative Goals

- **Explicit Implicit Knowledge**: Convert gut feelings to documented patterns
- **Reduced Friction**: Automate decisions to eliminate repeated questions
- **Consistent Codebase**: Align all projects with discovered preferences
- **Efficient Reviews**: Clear guidance reduces cognitive load
- **Future-Proof**: Documented rationale helps maintain rules over time

## Example Session Flow

### Opening (5 min)

> "Let's systematically discover your Swift coding preferences. I'll show you edge cases and variations, you react honestly. No pressure to have strong opinions on everything - 'I don't care' is perfectly valid data. Ready?"

### Category A (10 min)

> **Example A2**: "Here's reversed wrapper ordering: `private @State var count`. React: Accept, Reject, or Context?"
>
> → "Reject"
>
> "Why does this matter?"
>
> → "Conflicts with SwiftFormat expectations, property wrapper should come first"
>
> "How confident?"
>
> → "Strong - I've never seen it the other way"
>
> "Implementation?"
>
> → "SwiftSyntax rule - mechanical check, clear violation"

### Mid-Session Check (45 min)

> "We're halfway through. Feeling decision fatigue? Want a 5-minute break? Any patterns emerging?"

### Synthesis (90 min)

> "Let's check consistency: You said 'View' suffix is optional, and file naming should match type. If we have UserProfile (no suffix), should the file be UserProfile.swift or UserProfileView.swift?"

### Wrap-Up (105 min)

> "Great session. You identified 12 strong preferences, 18 context-dependent patterns. Top priorities: wrapper ordering rule, extraction threshold framework, preview naming guidance. I'll draft the implementation plan."

## Success Metrics

**Session Successful If:**
- ✅ All 52 examples reviewed
- ✅ Reasoning documented for strong preferences
- ✅ Context-dependent frameworks defined
- ✅ Implementation path identified for each
- ✅ No contradictions in related decisions
- ✅ Clear next steps established

**Session Needs Refinement If:**
- ❌ Too many "I don't know" responses (unclear examples)
- ❌ Contradictory decisions (need synthesis)
- ❌ No strong preferences found (examples too trivial)
- ❌ Decision fatigue before completion (pacing issue)
- ❌ Unclear implementation paths (need criteria)

## Tips for Success

1. **Start Fresh**: Don't do this when tired or distracted
2. **Read Code Out Loud**: Helps trigger reactions
3. **Compare Directly**: Look at both options side-by-side
4. **Think Real-World**: "Would this annoy me in a PR review?"
5. **Trust Patterns**: If you consistently prefer X, that's data
6. **Document Uncertainty**: "I think I prefer X, but not sure" is valuable
7. **Revisit If Needed**: Okay to change answer after seeing more examples
8. **Focus on Impact**: Prefer clarity > cleverness, maintainability > brevity

## Appendix: Category Descriptions

### A. Property Wrapper Ordering
**Focus**: Mechanical ordering of wrappers, modifiers, types
**Example**: `@State private var` vs `private @State var`
**Complexity**: Low - mostly mechanical
**Expected**: Strong preferences, suitable for SwiftSyntax

### B. View Body Edge Cases
**Focus**: Line count boundaries, special cases, exceptions
**Example**: Is 16 lines (1 over limit) acceptable?
**Complexity**: Medium - requires judgment
**Expected**: Mixed strong/context-dependent

### C. Naming Conventions
**Focus**: Names for types, properties, functions, constants
**Example**: "View" suffix required? ViewModel vs model naming?
**Complexity**: High - very subjective
**Expected**: Mostly context-dependent or weak

### D. Constants Patterns
**Focus**: Where to define, when to extract, acceptable literals
**Example**: Is `1` acceptable without constant? What about `10`?
**Complexity**: Medium - threshold judgments
**Expected**: Mixed preferences, clear thresholds

### E. Architecture Boundaries
**Focus**: When to extract, create new files, use extensions
**Example**: 3-line section - extract or keep inline?
**Complexity**: Very High - workflow decisions
**Expected**: Context-dependent frameworks for skill

### F. Preview Patterns
**Focus**: Preview requirements, content, organization
**Example**: One comprehensive vs multiple focused previews?
**Complexity**: Medium - balance detail vs simplicity
**Expected**: Moderate preferences, workflow guidance
