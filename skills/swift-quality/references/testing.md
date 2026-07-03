# Testing Standards

Swift Testing standards, best practices, and known issues.

## Mandatory Swift Testing

**ALWAYS use Swift Testing (`import Testing`)**
**NEVER use XCTest**

Reference: https://developer.apple.com/documentation/testing/migratingfromxctest

## Basic Test Structure

### Simple Test

```swift
import Testing

@Test
func userNameFormatting() {
    let user = User(firstName: "John", lastName: "Doe")
    let formatted = user.fullName

    #expect(formatted == "John Doe")
}
```

### Async Test

```swift
@Test
func dataFetching() async throws {
    let service = RemoteDataService()
    let items = try await service.fetchItems()

    #expect(!items.isEmpty)
}
```

### Test with Parameters

```swift
@Test(arguments: [
    (1, 2, 3),
    (5, 10, 15),
    (-3, 7, 4)
])
func addition(a: Int, b: Int, expected: Int) {
    let result = a + b
    #expect(result == expected)
}
```

## Testing Best Practices

### Test Organization

```swift
// Group related tests in a struct
struct UserTests {
    @Test
    func userInitialization() {
        let user = User(id: UUID(), name: "Test")
        #expect(user.name == "Test")
    }

    @Test
    func userValidation() throws {
        let user = User(id: UUID(), name: "")
        #expect(throws: ValidationError.self) {
            try user.validate()
        }
    }
}
```

### Test Naming

Use clear, descriptive test names that explain what is being tested:

```swift
// ✅ Good: Clear what's being tested
@Test func emptyNameThrowsValidationError()
@Test func validUserPassesValidation()
@Test func duplicateEmailIsRejected()

// ❌ Bad: Unclear what's being tested
@Test func test1()
@Test func userTest()
@Test func checkStuff()
```

## Known Issues and Workarounds

### @available Doesn't Work with @Test

**Problem**: `@Test` macro doesn't work with availability attributes.

```swift
// ❌ Doesn't compile
@available(iOS 16, *)
@Test
func modernAPITest() {
    // Test using iOS 16+ APIs
}
```

**Workaround**: Use `#available` within the test:

```swift
// ✅ Works
@Test
func modernAPITest() {
    guard #available(iOS 16, *) else {
        Issue.record("Test requires iOS 16")
        return
    }

    // Test using iOS 16+ APIs
}
```

### Color Space Issues with NSColor

**Problem**: NSColor system colors don't compare correctly in tests without color space conversion.

```swift
// ❌ May fail unexpectedly
@Test
func systemColorTest() {
    let color = NSColor.systemBlue
    #expect(color == NSColor.systemBlue) // May fail
}
```

**Solution**: Convert to sRGB color space:

```swift
// ✅ Works reliably
@Test
func systemColorTest() throws {
    let color = try #require(NSColor.systemBlue.usingColorSpace(.sRGB))
    let expected = try #require(NSColor.systemBlue.usingColorSpace(.sRGB))
    #expect(color == expected)
}
```

### API Signature Validation

**Problem**: Package types may have different initializers than expected.

**Solution**: Always use proper initializers when testing package types:

```swift
// Check Package.swift and type definition for correct initializer
@Test
func fractionInitialization() {
    // Use the actual initializer signature
    let fraction = Fraction(numerator: 1, denominator: 2)
    #expect(fraction.value == 0.5)
}
```

### Test Dependencies

**Problem**: "No such module" errors for test dependencies.

**Solution**: Add test dependencies to Package.swift AND update imports:

```swift
// Package.swift
.testTarget(
    name: "MyPackageTests",
    dependencies: [
        "MyPackage",
        .product(name: "SomeTestHelper", package: "test-helpers")
    ]
)

// In test file
import Testing
import MyPackage
import SomeTestHelper
```

## Testing Infrastructure

### Unified Test Runner

Create a `run-all-tests.sh` script for comprehensive testing:

```bash
#!/bin/bash

echo "🧪 Running all tests..."

# Run each package test suite
cd synodic-tools && swift test && cd ..
cd gravity-well && swift test && cd ..

echo "✅ All tests complete"
```

### Pre-Push Hook Integration

Integrate testing into git workflow:

```bash
#!/bin/bash
# .git/hooks/pre-push

./run-all-tests.sh
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Push aborted."
    exit 1
fi
```

### Platform Consistency

Standardize all packages to same platform version:

```swift
// Package.swift - All packages use same platforms
platforms: [
    .iOS(.v15),
    .macOS(.v12)
]
```

## Expectations

### Basic Expectations

```swift
#expect(value == expected)
#expect(value != unexpected)
#expect(value > minimum)
#expect(value < maximum)
```

### Boolean Expectations

```swift
#expect(condition)
#expect(!condition)
```

### Optional Expectations

```swift
// Expect non-nil
#expect(optionalValue != nil)

// Require non-nil (throws if nil)
let value = try #require(optionalValue)
```

### Collection Expectations

```swift
#expect(array.isEmpty)
#expect(!array.isEmpty)
#expect(array.count == 5)
#expect(array.contains(item))
```

### Error Expectations

```swift
// Expect specific error type
#expect(throws: ValidationError.self) {
    try validateInput("")
}

// Expect any error
#expect(throws: Error.self) {
    try riskyOperation()
}

// Expect no error
#expect(throws: Never.self) {
    try safeOperation()
}
```

## Testing Async Code

### Basic Async Test

```swift
@Test
func asyncDataLoading() async throws {
    let manager = DataManager()
    await manager.loadData()

    #expect(!manager.items.isEmpty)
}
```

### Testing Concurrent Operations

```swift
@Test
func concurrentOperations() async throws {
    let manager = DataManager()

    async let operation1 = manager.fetchData(id: 1)
    async let operation2 = manager.fetchData(id: 2)

    let (result1, result2) = try await (operation1, operation2)

    #expect(result1.id == 1)
    #expect(result2.id == 2)
}
```

### Testing Actor Isolation

```swift
actor DataStore {
    var items: [Item] = []

    func add(_ item: Item) {
        items.append(item)
    }
}

@Test
func actorIsolation() async {
    let store = DataStore()
    await store.add(Item.sample)

    let items = await store.items
    #expect(items.count == 1)
}
```

## Testing ObservableObject Managers

### Testing Published Properties

```swift
@MainActor
@Test
func managerStateUpdates() async throws {
    let manager = DataManager()

    #expect(manager.items.isEmpty)

    await manager.loadItems()

    #expect(!manager.items.isEmpty)
}
```

### Testing with Mock Dependencies

```swift
@MainActor
@Test
func managerWithMockService() async throws {
    let mockService = MockDataService()
    mockService.itemsToReturn = [Item.sample]

    let manager = DataManager()
    manager.configure(service: mockService)

    await manager.loadItems()

    #expect(manager.items.count == 1)
    #expect(manager.items.first?.id == Item.sample.id)
}
```

## Test Coverage Goals

### Priority Areas

1. **Complex functionality** - Algorithms, calculations, transformations
2. **Edge cases** - Boundary conditions, empty states, maximum values
3. **Foundation types** - Core data structures and extensions
4. **Public APIs** - All publicly exposed functionality
5. **Integration points** - Service layer interactions

### What Not to Test

- Simple property access
- SwiftUI view bodies (use PreviewProvider for visual validation)
- Auto-generated code
- Third-party library internals

## Performance Testing

```swift
@Test
func performanceMeasurement() {
    let metrics = Metrics()

    metrics.measure {
        // Code to measure
        heavyComputation()
    }

    // Metrics automatically recorded
}
```

## Tags for Test Organization

```swift
@Test(.tags(.critical))
func criticalPathTest() {
    // Test critical functionality
}

@Test(.tags(.integration))
func integrationTest() {
    // Test service integration
}

@Test(.tags(.slow))
func slowTest() async {
    // Test that takes significant time
}

// Run specific tags:
// swift test --filter tag:critical
```
