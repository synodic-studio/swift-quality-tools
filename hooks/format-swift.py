#!/usr/bin/env python3
"""SwiftSkim PostToolUse hook: format and lint edited .swift files.

Self-contained (no third-party deps). Runs on Edit/Write/MultiEdit; when the
edited file is Swift it formats it in place with swiftformat-smart, then lints
with swiftlint-smart and swiftskim. Any violations are written to stderr and the
hook exits 2, which surfaces them back to the agent as actionable feedback.

Binary resolution order (so it works however the tool was installed):
  1. On PATH (Homebrew install)
  2. <plugin root>/.build/release (source install)
  3. ~/Developer/swift-quality-tools/.build/release (legacy dev checkout)
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def find_bin(name: str) -> str | None:
    on_path = shutil.which(name)
    if on_path:
        return on_path
    root = os.environ.get("CLAUDE_PLUGIN_ROOT", "")
    candidates = []
    if root:
        candidates.append(Path(root) / ".build" / "release" / name)
    candidates.append(Path.home() / "Developer" / "swift-quality-tools" / ".build" / "release" / name)
    for candidate in candidates:
        if candidate.is_file():
            return str(candidate)
    return None


def run_tool(bin_path: str, file_path: str, cwd: str) -> tuple[int, str]:
    try:
        result = subprocess.run(
            [bin_path, file_path],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=30,
        )
        return result.returncode, (result.stdout + result.stderr).strip()
    except subprocess.TimeoutExpired:
        return 1, f"{Path(bin_path).name} timed out after 30s"


def edited_file(event: dict) -> str | None:
    tool_input = event.get("tool_input", {})
    path = tool_input.get("file_path") or tool_input.get("filePath")
    if path and path.endswith(".swift") and Path(path).is_file():
        return path
    return None


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    file_path = edited_file(event)
    if not file_path:
        return 0
    cwd = event.get("cwd") or str(Path(file_path).parent)

    # Format in place first (best effort), then lint.
    formatter = find_bin("swiftformat-smart")
    if formatter:
        run_tool(formatter, file_path, cwd)

    problems = []
    for name in ("swiftlint-smart", "swiftskim"):
        bin_path = find_bin(name)
        if not bin_path:
            continue
        code, output = run_tool(bin_path, file_path, cwd)
        if code != 0 and output:
            problems.append(output)

    if problems:
        name = Path(file_path).name
        print(
            f"SwiftSkim found quality violations in {name} that must be fixed:\n\n"
            + "\n\n".join(problems),
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
