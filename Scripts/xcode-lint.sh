#!/bin/bash
#
# Xcode Build Phase Linting Script
# Run SwiftLint and custom SwiftSyntax rules to show warnings in Xcode
#
# Note: SwiftFormat runs on edit via Claude Code hooks, not in build phase
#
# Usage: Add to Xcode Build Phase:
#   "${HOME}/Developer/swiftskim/Scripts/xcode-lint.sh"
#

TOOLS_DIR="${HOME}/Developer/swift-quality-tools/.build/release"

# SwiftLint
if [ -f "${TOOLS_DIR}/swiftlint-smart" ]; then
    "${TOOLS_DIR}/swiftlint-smart" "${SRCROOT}" || true
else
    echo "warning: swiftlint-smart not found at ${TOOLS_DIR}"
fi

# Custom SwiftLint Rules
if [ -f "${TOOLS_DIR}/swiftskim" ]; then
    # Run WITHOUT XCODE_VERSION_ACTUAL to get terminal-format output
    # Then parse and re-echo in Xcode format
    TMPFILE="${TMPDIR:-/tmp}/swiftlint-custom-$$.txt"

    # Unset XCODE_VERSION_ACTUAL to force terminal output format
    # (Subprocess output is suppressed by Xcode sandbox, so we parse and re-echo)
    (unset XCODE_VERSION_ACTUAL && "${TOOLS_DIR}/swiftskim" "${SRCROOT}" > "$TMPFILE" 2>&1)

    # Parse the terminal output and re-echo in Xcode format
    if [ -f "$TMPFILE" ]; then
        CURRENT_FILE=""

        # Read line by line, stripping ANSI color codes
        while IFS= read -r line; do
            # Strip ANSI color codes
            clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')

            # Check if this is a file path line (ends with .swift: and not indented)
            if [[ "$clean_line" =~ ^([^[:space:]].*\.swift):$ ]]; then
                CURRENT_FILE="${SRCROOT}/${BASH_REMATCH[1]}"
            # Check if this is a violation line (starts with spaces and bullet)
            elif [[ "$clean_line" =~ ^[[:space:]]+•[[:space:]]\[([^\]]+)\] ]]; then
                RULE_ID="${BASH_REMATCH[1]}"

                # Try to extract line number and message
                if [[ "$clean_line" =~ Line[[:space:]]([0-9]+):[[:space:]](.*) ]]; then
                    LINE_NUM="${BASH_REMATCH[1]}"
                    MESSAGE="${BASH_REMATCH[2]}"
                else
                    # No line number (some rules don't provide it)
                    LINE_NUM="1"
                    # Extract message after rule ID
                    if [[ "$clean_line" =~ \[[^\]]+\][[:space:]](.*) ]]; then
                        MESSAGE="${BASH_REMATCH[1]}"
                    else
                        MESSAGE="Violation detected"
                    fi
                fi

                # Echo in Xcode format
                if [ -n "$CURRENT_FILE" ]; then
                    echo "${CURRENT_FILE}:${LINE_NUM}: warning: [${RULE_ID}] ${MESSAGE}"
                fi
            fi
        done < "$TMPFILE"

        rm -f "$TMPFILE"
    fi
else
    echo "warning: swiftskim not found at ${TOOLS_DIR}"
fi
