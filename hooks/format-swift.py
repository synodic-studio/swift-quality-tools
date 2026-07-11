#!/usr/bin/env python3
"""SwiftSkim post-edit hook: format and lint edited .swift files.

Self-contained (no third-party deps). It reads a hook event as JSON on stdin, finds
the Swift file(s) that were edited, formats each in place with swiftformat-smart, then
lints with swiftlint-smart and swiftskim. Any violations are written to stderr and the
hook exits 2, which every supported agent surfaces back as actionable feedback.

Works across three agents that share the same command-hook + exit-2 convention:
  - Claude Code — PostToolUse on Edit|Write|MultiEdit; path in tool_input.file_path
  - Codex CLI   — PostToolUse on apply_patch; paths parsed from the patch text
  - Cursor      — afterFileEdit; path at the top-level file_path field
See edited_files() for how each shape is recognized.

Binary resolution order (so it works however the tool was installed):
  1. On PATH (Homebrew install)
  2. <plugin root>/.build/release (source install; CLAUDE_PLUGIN_ROOT or CODEX_PLUGIN_ROOT)
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
    root = os.environ.get("CLAUDE_PLUGIN_ROOT") or os.environ.get("CODEX_PLUGIN_ROOT") or ""
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


# Codex apply_patch file headers, e.g. "*** Update File: Sources/Foo.swift".
_PATCH_MARKERS = ("*** Update File:", "*** Add File:", "*** Move to:")


def edited_files(event: dict) -> list[str]:
    """Extract edited .swift file paths from any supported hook payload shape."""
    candidates: list[str] = []
    tool_input = event.get("tool_input") or {}

    # Claude Code (Edit|Write|MultiEdit) and Cursor (afterFileEdit) name the path
    # directly, under tool_input or at the top level.
    for src in (tool_input.get("file_path"), tool_input.get("filePath"), event.get("file_path")):
        if src:
            candidates.append(src)

    # Codex apply_patch: the patch text names the files. Scan any string values in
    # tool_input (the patch is passed as a string arg) for apply-patch file headers.
    for value in tool_input.values():
        if not isinstance(value, str):
            continue
        for line in value.splitlines():
            line = line.strip()
            for marker in _PATCH_MARKERS:
                if line.startswith(marker):
                    candidates.append(line[len(marker):].strip())

    files: list[str] = []
    for path in candidates:
        if path and path.endswith(".swift") and Path(path).is_file() and path not in files:
            files.append(path)
    return files


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    files = edited_files(event)
    if not files:
        return 0
    cwd = event.get("cwd") or str(Path(files[0]).parent)

    formatter = find_bin("swiftformat-smart")
    linters = [b for b in (find_bin("swiftlint-smart"), find_bin("swiftskim")) if b]

    problems = []
    for file_path in files:
        # Format in place first (best effort), then lint.
        if formatter:
            run_tool(formatter, file_path, cwd)
        for bin_path in linters:
            code, output = run_tool(bin_path, file_path, cwd)
            if code != 0 and output:
                problems.append(output)

    if problems:
        names = ", ".join(sorted({Path(f).name for f in files}))
        print(
            f"SwiftSkim found quality violations in {names} that must be fixed:\n\n"
            + "\n\n".join(problems),
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
