# Directory Structure

## Current Organization

```
swiftlint-swiftsyntax-integration/
├── README.md                    # Main documentation
├── QUICK_START.md               # Getting started guide
├── XCODE_SETUP_GUIDE.md         # Detailed Xcode integration
├── DIRECTORY_STRUCTURE.md       # This file
├── SWIFTSYNTAX_RULES.md         # Technical implementation details
├── XCODE_INTEGRATION.md         # Integration patterns and options
├── rule-engine/                 # Core SwiftSyntax implementation
│   ├── Package.swift            # Swift Package Manager config
│   ├── Package.resolved         # Locked dependencies
│   ├── test-custom-rule.swift   # Rule implementation
│   └── .build/                  # Built executable
├── scripts/                     # Ready-to-use scripts
│   ├── setup.sh                 # One-time setup
│   ├── check-file.sh            # Check single file
│   ├── check-project.sh         # Check entire project
│   └── xcode-integration.sh     # Xcode build phase script
├── examples/                    # Usage examples
│   ├── gravity-well-example.sh  # Project-specific example
│   └── sample-output.txt        # Expected output samples
└── legacy-files/                # Deprecated/experimental files
    ├── README.md                # Legacy file documentation
    ├── swiftlint_extra_rules/   # Bazel-based implementation
    ├── *.sh                     # Old script versions
    └── *.swift                  # Alternative implementations
```

## File Purposes

### Core Files
- **rule-engine/**: The actual SwiftSyntax rule that does the work
- **scripts/**: Production-ready scripts for daily use
- **examples/**: Real-world usage examples

### Documentation
- **README.md**: Comprehensive overview and technical details
- **QUICK_START.md**: Fastest path to getting it working
- **XCODE_SETUP_GUIDE.md**: Step-by-step Xcode integration
- **SWIFTSYNTAX_RULES.md**: Implementation details and architecture

### Legacy
- **legacy-files/**: Experimental approaches and deprecated code
- Kept for reference but not needed for current implementation

## Clean State

All scattered files from development have been organized into this single directory structure. The legacy files are preserved for reference but the main directory contains only the working, production-ready solution.

## Usage Flow

1. **Start here**: `QUICK_START.md`
2. **Test it works**: `./scripts/check-file.sh`
3. **Add to Xcode**: Follow `XCODE_SETUP_GUIDE.md`
4. **Understand details**: `README.md` and `SWIFTSYNTAX_RULES.md`