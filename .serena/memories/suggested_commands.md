# Suggested Commands

## Build
```bash
swift build -c release
cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine && swift build
./Scripts/build-all.sh  # Build everything
```

## Testing
```bash
swift test
swiftlintcustom-smart path/to/File.swift  # Test custom rules
```

## Code Quality
```bash
swiftformat-smart .
swiftlint-smart .
swiftlintcustom-smart .
```

## After Task Completion
1. Run quality checks: `swiftformat-smart .`, `swiftlint-smart .`, `swiftlintcustom-smart .`
2. Build: `swift build`
3. Rebuild custom rules if modified: `cd CustomRules/swiftlint-swiftsyntax-integration/rule-engine && swift build`
