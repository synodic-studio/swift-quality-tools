# TODO: Enforce Private Access for SwiftUI Property Wrappers

## Overview

Create a custom SwiftLint rule to enforce `private` access control for SwiftUI property wrappers that represent view-internal state.

## Rule Identifier

`private_property_wrappers`

## Rationale

SwiftUI property wrappers like `@State`, `@StateObject`, and `@EnvironmentObject` represent view-internal state that should not be accessed directly from outside the view. Making them `private` enforces proper encapsulation and prevents coupling between views.

## Property Wrappers That Should Be Private

### Always Private (High Confidence)

These represent internal view state and should **always** be private:

1. **`@State`** - View's internal mutable state
   ```swift
   // ❌ Bad
   @State var counter: Int = 0

   // ✅ Good
   private @State var counter: Int = 0
   ```

2. **`@StateObject`** - View owns and manages the lifecycle
   ```swift
   // ❌ Bad
   @StateObject var viewModel = MyViewModel()

   // ✅ Good
   private @StateObject var viewModel = MyViewModel()
   ```

3. **`@EnvironmentObject`** - Injected from environment, view-internal
   ```swift
   // ❌ Bad
   @EnvironmentObject var appState: AppState

   // ✅ Good
   private @EnvironmentObject var appState: AppState
   ```

4. **`@Environment`** - Reading from environment
   ```swift
   // ❌ Bad
   @Environment(\.colorScheme) var colorScheme

   // ✅ Good
   private @Environment(\.colorScheme) var colorScheme
   ```

5. **`@AppStorage`** - Persistent storage, typically view-internal
   ```swift
   // ❌ Bad
   @AppStorage("isDarkMode") var isDarkMode = false

   // ✅ Good
   private @AppStorage("isDarkMode") var isDarkMode = false
   ```

6. **`@SceneStorage`** - Scene-specific storage
   ```swift
   // ❌ Bad
   @SceneStorage("selectedTab") var selectedTab = 0

   // ✅ Good
   private @SceneStorage("selectedTab") var selectedTab = 0
   ```

7. **`@FetchRequest`** - Core Data fetch, typically view-internal
   ```swift
   // ❌ Bad
   @FetchRequest(sortDescriptors: []) var items: FetchedResults<Item>

   // ✅ Good
   private @FetchRequest(sortDescriptors: []) var items: FetchedResults<Item>
   ```

8. **`@GestureState`** - Gesture tracking state
   ```swift
   // ❌ Bad
   @GestureState var dragOffset: CGSize = .zero

   // ✅ Good
   private @GestureState var dragOffset: CGSize = .zero
   ```

9. **`@FocusState`** - Focus management
   ```swift
   // ❌ Bad
   @FocusState var isEmailFocused: Bool

   // ✅ Good
   private @FocusState var isEmailFocused: Bool
   ```

10. **`@ScaledMetric`** - Dynamic type scaling
    ```swift
    // ❌ Bad
    @ScaledMetric var imageSize: CGFloat = 100

    // ✅ Good
    private @ScaledMetric var imageSize: CGFloat = 100
    ```

### Sometimes Non-Private (Lower Confidence)

These can be legitimately internal/public in certain scenarios:

1. **`@Binding`** - Often passed from parent view
   ```swift
   // ✅ Valid: Public API for reusable component
   struct ToggleRow: View {
       @Binding var isOn: Bool  // Intentionally non-private
   }

   // ❌ But if it's never used externally, should be private
   struct MyView: View {
       @Binding var internalState: Bool  // Should be private if only used internally
   }
   ```

2. **`@ObservedObject`** - Often passed from parent, but sometimes internal
   ```swift
   // ✅ Valid: Passed from parent
   struct DetailView: View {
       @ObservedObject var item: Item  // Intentionally non-private
   }

   // ❌ If created internally, should be @StateObject and private
   struct MyView: View {
       @ObservedObject var viewModel = MyViewModel()  // Wrong! Use @StateObject + private
   }
   ```

## Edge Cases & Exceptions

### When Non-Private Might Be Acceptable

1. **Reusable Components with Public APIs**
   ```swift
   // A reusable toggle component that accepts a binding
   public struct CustomToggle: View {
       @Binding var isOn: Bool  // Public interface

       public init(isOn: Binding<Bool>) {
           self._isOn = isOn
       }
   }
   ```

2. **Testing Requirements**
   - **Recommendation**: Use `@testable import` instead of making properties internal
   - **Rare Exception**: Cross-module testing without `@testable` access

3. **Protocol Requirements**
   ```swift
   protocol ViewModelProviding {
       var viewModel: SomeViewModel { get }
   }

   struct MyView: View, ViewModelProviding {
       @StateObject var viewModel = SomeViewModel()  // Protocol requirement
   }
   ```
   **Better Solution**: Use computed property wrapper:
   ```swift
   struct MyView: View, ViewModelProviding {
       private @StateObject var _viewModel = SomeViewModel()
       var viewModel: SomeViewModel { _viewModel }
   }
   ```

4. **Cross-Module View Composition**
   - **Rare**: Views in different modules need direct property access
   - **Better Solution**: Pass values through initializers, not direct property access

### When to Allow Internal/Public Access

**Rule of thumb**: If you can't explain a specific architectural reason why a property wrapper needs non-private access, it should be private.

**Valid reasons**:
- Explicit public API for reusable component library
- Required by protocol conformance (and computed wrapper not viable)
- Cross-module composition (rare, often indicates design issue)

**Invalid reasons**:
- "Might need it later" - YAGNI principle applies
- "Easier for testing" - Use `@testable import`
- "SwiftUI doesn't require it" - Encapsulation is still valuable

## Rule Configuration Options

### Strictness Levels

1. **Strict (Recommended)**: All property wrappers must be private, no exceptions
   ```yaml
   private_property_wrappers:
     strictness: strict
     # Violations on: @State, @StateObject, @EnvironmentObject, @Environment,
     # @AppStorage, @SceneStorage, @FetchRequest, @Binding, @ObservedObject, etc.
   ```

2. **Moderate**: Allow @Binding and @ObservedObject to be non-private
   ```yaml
   private_property_wrappers:
       strictness: moderate
     allow_public:
       - Binding
       - ObservedObject
     # Only flag: @State, @StateObject, @EnvironmentObject, etc.
   ```

3. **Relaxed**: Only enforce for state-owning wrappers
   ```yaml
   private_property_wrappers:
     strictness: relaxed
     enforce_private:
       - State
       - StateObject
       - EnvironmentObject
     # Everything else allowed to be non-private
   ```

## Implementation Notes

### Detection Strategy

1. Use SwiftSyntax to find `VariableDeclSyntax` nodes
2. Check for SwiftUI property wrapper attributes
3. Check access level modifiers (`private`, `fileprivate`, `internal`, `public`, `open`)
4. If no access modifier present, default is `internal` (violation)
5. If `public` or `internal` (explicit or default), flag as violation

### Violation Message Format

```
⚠️  [private_property_wrappers] Line 42: @State property 'counter' should be private - view state should not be exposed outside the view
⚠️  [private_property_wrappers] Line 43: @EnvironmentObject property 'appState' should be private - injected dependencies should be private
⚠️  [private_property_wrappers] Line 44: @Binding property 'isOn' may be non-private if used as public API - add suppression directive if intentional
```

### Suppression Support

Allow suppression for legitimate cases:
```swift
// swiftlint:disable:next private_property_wrappers
@Binding var isOn: Bool  // Public API for reusable component
```

## Benefits

1. **Enforces Encapsulation** - View internals stay internal
2. **Prevents Accidental Coupling** - Can't accidentally reference another view's @State
3. **Clearer Intent** - `private` makes it explicit that property is view-internal
4. **Safer Refactoring** - Compiler prevents external access during refactoring
5. **Better Code Reviews** - Reviewers can see when state is intentionally exposed
6. **Consistency** - Team follows same pattern across codebase

## Drawbacks & Considerations

1. **Verbosity** - Adds `private` keyword to many property declarations
   - **Counter**: Explicit is better than implicit, especially for state management

2. **Learning Curve** - New developers might not understand why
   - **Counter**: Enforces good practice from the start

3. **False Positives** - Reusable components with legitimate public APIs
   - **Counter**: Use suppression directives for these cases

4. **Doesn't Prevent All Issues** - Can still have tight coupling through other means
   - **Counter**: True, but reduces one common source of coupling

## Related Rules

- `view_structure_order` - Already enforces ordering, could add access level checks
- `no_wrapper_body` - Detects unnecessary wrapper bodies
- Future: `no_public_state` - Broader rule about exposing mutable state

## Implementation Priority

**Recommendation**: Medium Priority

- **High Value**: Enforces important encapsulation principle
- **Low Risk**: Easy to suppress when needed
- **Moderate Effort**: Straightforward SwiftSyntax implementation

## References

- [SwiftUI Property Wrappers Documentation](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
- [Swift Access Control](https://docs.swift.org/swift-book/LanguageGuide/AccessControl.html)
- [WWDC: Data Essentials in SwiftUI](https://developer.apple.com/videos/play/wwdc2020/10040/)

## Open Questions

1. **Should we enforce for ALL property wrappers or just SwiftUI ones?**
   - Recommendation: Start with SwiftUI-specific, expand later if needed

2. **Should we have different strictness for @Binding vs @State?**
   - Recommendation: Yes - @Binding often legitimately non-private, @State almost never

3. **How to handle custom property wrappers?**
   - Recommendation: Don't enforce for custom wrappers initially, add opt-in list later

4. **Should `fileprivate` be allowed?**
   - Recommendation: Yes - `fileprivate` is acceptable, it's still more restrictive than `internal`

## Implementation Checklist

- [ ] Create `PrivatePropertyWrappersRule.swift` in CustomRules
- [ ] Add SwiftSyntax visitor for property declarations
- [ ] Check for SwiftUI property wrapper attributes
- [ ] Detect access level (explicit or default)
- [ ] Generate violations with helpful messages
- [ ] Add configuration support for strictness levels
- [ ] Write comprehensive tests
- [ ] Add to rule engine integration
- [ ] Document in README
- [ ] Update CLAUDE.md with new rule identifier
