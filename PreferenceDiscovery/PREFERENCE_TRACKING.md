# Swift Preference Discovery - Tracking Template

**Session Date**: [YYYY-MM-DD]
**Reviewer**: Bryan Costanza
**Session Duration**: [Estimate: 90-120 minutes]

## Instructions

For each example in PreferenceDiscovery.swift:

1. **Review** the code variation
2. **Decide**: Accept / Reject / Context-Dependent
3. **Explain**: Why does this matter? What makes it better/worse?
4. **Rate Confidence**: Strong / Moderate / Weak
5. **Implementation Path**: SwiftSyntax / Skill / CLAUDE-SWIFT / None

## Decision Framework

**Accept**: "This pattern is fine and should be allowed"
**Reject**: "This pattern should be flagged/prevented"
**Context-Dependent**: "Acceptable in some cases, not others" (specify context)

**Strong**: Clear, unambiguous preference
**Moderate**: Preference but with some flexibility
**Weak**: Mild preference or indifferent

---

## A. Property Wrapper Ordering

### A1: Standard Pattern (@State private var)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### A2: Reversed Order (private @State var)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### A3: Multiple Wrappers (@State @MainActor vs @MainActor @State)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### A4: Explicit vs Inferred Type
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### A5: Line Breaks with Many Wrappers
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### A6: Grouped vs Separated Environment Properties
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### A7: Alphabetical Ordering Within Category
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### A8: Complex Initialization ([String]() vs [] vs Array<String>())
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

---

## B. View Body Edge Cases

### B1: Body at Exactly 15 Lines
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B2: Body at 16 Lines (One Over Limit)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B3: ViewModifier Body - Same 15-Line Rule?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B4: Computed Property Returning Single View (Wrapper Pattern)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B5: Computed Property Returning Multiple Views via @ViewBuilder
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B6: Body with Complex Switch Statement
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B7: Single-Line Body with Long Modifier Chain
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B8: Body with ForEach - Counts Toward Line Limit?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B9: Empty Body with EmptyView
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### B10: Body with Multiple Trailing Closures
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

---

## C. Naming Conventions

### C1: View Suffix - Required or Optional?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C2: ViewModel Naming (viewModel / model / vm)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C3: Boolean Property Naming (is / has / shows prefix)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C4: Computed Property Names (noun / verb / descriptive)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C5: Constants Enum Naming (Constants / Metrics / Layout)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C6: Private Property Naming with Underscore
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C7: File-Level Constants - Where to Define?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C8: Action Handler Naming (handle* / on* / did* / *ed)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C9: Binding Property Naming
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### C10: Preview Naming (descriptive / none / type name)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

---

## D. Constants Patterns

### D1: Constants Enum Placement (top / bottom of type)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### D2: Small Magic Numbers (1, 2, 3, 5, 10 acceptable?)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### D3: Common Values - Extract or Inline? (2x / 3x repetition)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### D4: Calculated Constants - Formula in Definition?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### D5: Constants Scope (flat / nested namespaces)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### D6: Color Constants - Where to Define?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### D7: String Constants - Extract or Inline?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### D8: Numeric Types for Constants (CGFloat / Double / Int / inferred)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

---

## E. Architecture Boundaries

### E1: When to Extract Computed Property vs Keep Inline?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E2: When to Create New View Type vs Computed Property?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E3: One Type Per File - Strictly Enforced?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E4: Extension Usage - When to Use?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E6: Manager vs ViewModel vs Controller Naming
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E7: Protocol Conformance - Extension or Inline?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E8: Nested Types - When Acceptable?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E9: File Naming - Match Type Name or Descriptive?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### E10: Initializer Placement - Before Body (Required by Linter)
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

---

## F. Preview Patterns

### F1: One Comprehensive Preview vs Multiple Focused Previews
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### F2: Preview Content - Minimal or Realistic?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### F3: Preview with Dependencies - Mock or Real?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### F4: Preview Placement - Immediately After Type or End of File?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### F5: Preview for ViewModifier - Required?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

### F6: Preview in Separate File - Acceptable?
- **Decision**: ☐ Accept ☐ Reject ☐ Context
- **Reasoning**:
- **Confidence**: ☐ Strong ☐ Moderate ☐ Weak
- **Implementation**: ☐ SwiftSyntax ☐ Skill ☐ CLAUDE-SWIFT ☐ None

---

## Session Summary

**Total Decisions**: 52 edge cases
**Strong Preferences**: [ ]
**Moderate Preferences**: [ ]
**Weak Preferences**: [ ]
**Context-Dependent**: [ ]

**Codification Plan**:
- **SwiftSyntax Rules**: [ new rules identified]
- **Skill Updates**: [ sections to add]
- **CLAUDE-SWIFT Updates**: [ reminders to add]
- **No Action**: [ cases documented for observation]

**Follow-Up Actions**:
1. [ ] Implement high-priority SwiftSyntax rules
2. [ ] Update apple-platform-dev skill with decision frameworks
3. [ ] Add critical anti-patterns to CLAUDE-SWIFT.md
4. [ ] Create test suite from discovered patterns
5. [ ] Document uncertain cases for future observation

**Notes**:
[Add any additional insights, patterns, or observations from the session]
