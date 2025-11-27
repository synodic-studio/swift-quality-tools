# Code Quality Philosophy

Why quality metrics matter, when to apply formatting, and naming/commenting guidelines.

## Why Quality Metrics Matter

Code quality metrics provide objective measures that correlate with maintainability, readability, and bug density.

### Line Length

**Target: 120 characters warning, 150 characters error**

**Why it matters:**
- Reduces horizontal scrolling during code review
- Improves readability on standard displays
- Forces consideration of code complexity
- Makes side-by-side diffs more practical

**When to enforce:**
- All production code
- During code reviews
- Before committing to repository

**Exceptions:**
- URLs in comments or strings
- Function declarations that need full signatures visible
- Specific comments requiring longer explanations

### Function Body Length

**Target: 30 lines warning, 60 lines error**

**Why it matters:**
- Long functions often do too many things (violates Single Responsibility)
- Harder to understand and test
- More likely to contain bugs
- Difficult to reuse parts of the logic

**When to refactor:**
- Extract related operations into helper functions
- Move complex logic to separate methods
- Consider if function violates SRP

**Exceptions:**
- Switch statements with many cases (consider lookup tables)
- Initialization code with many related settings

### Type/File Length

**Target: 100 lines warning, 150 lines error (for types)**

**Why it matters:**
- Large types suggest too many responsibilities
- Harder to navigate and understand
- Makes refactoring more difficult
- Suggests architectural problems

**When to refactor:**
- Split into multiple focused types
- Extract helper types or extensions
- Consider architectural redesign

**Exceptions:**
- Generated code (Codable implementations, etc.)
- Large enum with many cases
- View models with many related @Published properties

### Cyclomatic Complexity

**Target: 10 warning, 15 error**

**Why it matters:**
- High complexity = many decision paths
- Exponentially harder to test all branches
- More likely to contain bugs
- Difficult to understand control flow

**When to refactor:**
- Extract complex conditions into named functions
- Use guard statements for early exits
- Consider lookup tables for complex branching
- Break into smaller, focused functions

### Nesting Depth

**Target: Type nesting 3 warning/4 error, Function nesting 5 warning/6 error**

**Why it matters:**
- Deep nesting is cognitively demanding
- Suggests complex control flow
- Makes code harder to follow
- Often indicates opportunity for extraction

**When to refactor:**
- Use guard for early exits
- Extract nested logic to functions
- Invert conditionals to reduce nesting
- Consider state machines for complex flow

## When to Apply Formatting

### Always Format

**Before committing:**
- Ensures consistency across the codebase
- Prevents formatting noise in diffs
- Makes code reviews focus on logic, not style

**After completing a feature:**
- Clean up any temporary formatting during development
- Ensure consistent style across new code
- Catch any violations introduced during rapid development

**When code becomes hard to read:**
- Proper formatting can reveal structural issues
- Consistent indentation shows logical structure
- Reveals opportunities for refactoring

### Quality Gates

**Pre-commit:**
```bash
# Format check (don't auto-fix in hooks, just warn)
swiftformat --lint .
swiftlint
```

**Pre-push:**
```bash
# Run comprehensive checks
./run-quality-checks.sh
```

**CI/CD:**
```bash
# Fail build on quality violations
swiftformat --lint .
swiftlint --strict
swift test
```

## Formatting Principles

### Indentation and Whitespace

**Consistency is key:**
- 4 spaces for indentation (never tabs)
- No trailing whitespace
- Single blank line between declarations
- Blank line before closing brace of types

```swift
// ✅ Correct formatting
struct User {
    let id: UUID
    let name: String

    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
    }

}

// ❌ Wrong: Inconsistent spacing
struct User{
    let id:UUID
    let name:String
    func validate()throws{
        guard !name.isEmpty else{
            throw ValidationError.emptyName}
    }
}
```

### Brace Style

**Same-line braces:**
```swift
// ✅ Correct: Opening brace on same line
if condition {
    doSomething()
} else {
    doSomethingElse()
}

// ❌ Wrong: Allman style not used in Swift
if condition
{
    doSomething()
}
```

### Import Organization

**Sorted and grouped:**
```swift
// ✅ Correct: Sorted, testable imports last
import Foundation
import SwiftUI

@testable import MyPackage
```

## Naming Guidelines

### General Principles

**Names should explain what, not how:**
```swift
// ✅ Good: Clear purpose
func calculateMonthlyPayment(principal: Double, rate: Double, years: Int) -> Double

// ❌ Bad: Implementation detail in name
func calculatePaymentUsingAmortizationFormula(p: Double, r: Double, y: Int) -> Double
```

**Avoid abbreviations:**
```swift
// ✅ Good: Full words
let configuration = Configuration()
let manager = DataManager()

// ❌ Bad: Unnecessary abbreviations
let cfg = Configuration()
let mgr = DataManager()
```

**Use domain language:**
```swift
// ✅ Good: Domain-specific terms
struct MortgageCalculator {
    func calculateAmortization() -> [Payment]
}

// ❌ Bad: Generic technical terms
struct FinanceComputer {
    func computeSchedule() -> [Result]
}
```

### Type Naming

**PascalCase for types:**
```swift
// Types: structs, classes, enums, protocols
struct UserProfile
class DataManager
enum NetworkError
protocol DataServiceProtocol
```

**Descriptive and specific:**
```swift
// ✅ Good: Specific purpose clear
struct PaymentCalculator
class UserAuthenticationManager
enum NetworkRequestError

// ❌ Bad: Too generic
struct Calculator
class Manager
enum Error
```

### Function and Variable Naming

**camelCase for functions and variables:**
```swift
func fetchUserData()
var isLoading = false
let maxRetryCount = 3
```

**Verbs for functions, nouns for properties:**
```swift
// ✅ Good: Clear distinction
func loadData() // Verb - action
var dataCount: Int // Noun - thing

// ❌ Bad: Unclear purpose
func data() // Is this getting or setting?
var loading() // Is this a property or function?
```

### Boolean Naming

**Use is/has/should prefixes:**
```swift
// ✅ Good: Clear boolean meaning
var isLoading: Bool
var hasError: Bool
var shouldRetry: Bool

// ❌ Bad: Unclear if boolean
var loading: Bool // Could be "Loading" type
var error: Bool // Could be Error? type
```

## Commenting Guidelines

### When to Comment

**Document the why, not the what:**
```swift
// ✅ Good: Explains business logic
// Users under 18 cannot create accounts per COPPA regulations
guard user.age >= 18 else {
    throw ValidationError.underAge
}

// ❌ Bad: Explains obvious code
// Check if age is greater than or equal to 18
guard user.age >= 18 else {
    throw ValidationError.underAge
}
```

**Complex algorithms:**
```swift
// ✅ Good: Explains approach
// Using binary search for O(log n) performance on sorted array
func findIndex(of value: Int) -> Int? {
    var low = 0
    var high = array.count - 1
    // Implementation
}
```

### Documentation Comments

**Use /// for public APIs:**
```swift
/// Calculates the monthly mortgage payment.
///
/// Uses the standard amortization formula to determine the fixed monthly payment
/// required to pay off the loan over the specified term.
///
/// - Parameters:
///   - principal: The initial loan amount in dollars
///   - rate: Annual interest rate as a decimal (e.g., 0.05 for 5%)
///   - years: Loan term in years
/// - Returns: Monthly payment amount in dollars
/// - Throws: `CalculationError.invalidInput` if any parameter is negative
func calculateMonthlyPayment(
    principal: Double,
    rate: Double,
    years: Int
) throws -> Double {
    // Implementation
}
```

### What NOT to Comment

**Temporary notes:**
```swift
// ❌ Bad: TODOs and FIXMEs for core functionality
func processData() {
    // TODO: implement this
    // FIXME: this crashes sometimes
}
```

**Obvious code:**
```swift
// ❌ Bad: Comment states the obvious
// Create a new user
let user = User(name: "John")

// Set the user's email
user.email = "john@example.com"
```

**Outdated information:**
```swift
// ❌ Bad: Comment doesn't match code
// Returns true if user is admin (code actually returns role)
func getUserStatus() -> UserRole {
    return user.role
}
```

## Self-Documenting Code

**The best documentation is clear code:**

```swift
// ❌ Bad: Needs comments to understand
func calc(p: Double, r: Double, n: Int) -> Double {
    let mr = r / 12 // Monthly rate
    let np = n * 12 // Number of payments
    // Monthly payment formula
    return p * (mr * pow(1 + mr, Double(np))) / (pow(1 + mr, Double(np)) - 1)
}

// ✅ Good: Code documents itself
func calculateMonthlyPayment(
    principal: Double,
    annualRate: Double,
    years: Int
) -> Double {
    let monthlyRate = annualRate / 12
    let numberOfPayments = years * 12
    let rateMultiplier = monthlyRate * pow(1 + monthlyRate, Double(numberOfPayments))
    let rateDenominator = pow(1 + monthlyRate, Double(numberOfPayments)) - 1

    return principal * rateMultiplier / rateDenominator
}
```

## Quality as a Habit

**Build quality in, don't bolt it on:**
- Write clean code from the start
- Refactor as you go
- Keep functions small and focused
- Name things clearly
- Format consistently

**Quality gates prevent regression:**
- Pre-commit checks catch issues early
- Pre-push validation prevents broken builds
- CI/CD enforcement maintains standards
- Code review focuses on logic, not style

**Quality enables velocity:**
- Clean code is faster to modify
- Good names reduce cognitive load
- Consistent style aids navigation
- Tests catch regressions
- Documentation reduces questions

The goal isn't perfection—it's sustainable, maintainable code that your future self (and teammates) can understand.
