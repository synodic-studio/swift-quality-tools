#!/bin/bash
# swiftskim live demo — a four-beat walkthrough for a screen share.
#
# The thesis: custom static-analysis rules encoded as a reusable, installable
# package, with a post-edit hook that enforces them on every agent edit.
# Quality built in by design, not caught in review.
#
# BEATS
#   1. The ruleset is data, and it is green on real code.
#      swiftskim --list-rules (count computed live) + swiftskim on this repo's
#      own source. Ends on: N rules, M files checked, 0 violations, exit 0.
#   2. The same engine on ordinary SwiftUI code that has problems.
#      Writes FeedView.swift, lints it. Ends on: rule ids, line numbers,
#      a computed AST nesting depth, exit 1. The numbers moved from beat 1.
#   3. Why this cannot be regex.
#      grep and swiftskim disagree on the same file, in swiftskim's favour:
#      grep hits the comment and the string literal and the VStack that is
#      fine; the AST rule hits exactly the one that is broken.
#      Ends on: grep count vs violation count, and the one line number.
#   4. Packaged, installed, and enforced automatically.
#      Feeds a real Claude Code PostToolUse event into hooks/format-swift.py:
#      the formatter rewrites the file in place (diff shown), the linter blocks
#      the edit with exit 2 and the text the agent receives. Fix it, same event
#      again, exit 0. Ends on: exit 2 -> exit 0.
#
# USAGE
#   Scripts/demo.sh                    # live: one beat per keypress
#   Scripts/demo.sh --auto             # start to finish, no interaction
#   Scripts/demo.sh --local            # use ./.build/release, not the installed binaries
#   Scripts/demo.sh --workdir DIR      # where the demo writes its Swift files
#   Scripts/demo.sh --cleanup          # delete the demo workspace
#   Scripts/demo.sh -h                 # this header
#
# The demo writes Swift files into a scratch workspace (default
# "$TMPDIR/swiftskim-demo") and touches nothing else. It never writes inside
# this repo. --cleanup refuses to delete a directory this script did not create.
#
# OFFLINE / HOSTILE VENUE
#   Nothing here touches the network. --local points every beat (including the
#   hook) at ./.build/release instead of the Homebrew install, so a laptop with
#   a working checkout and no brew still runs the whole deck.
#
# FIRST-RUN CHECKLIST (do these before the live run, not during)
#   - brew install swiftformat swiftlint         # the wrappers shell out to both
#   - brew install synodic-studio/synodic/swiftskim   (or ./Scripts/build-all.sh, then --local)
#   - python3 on PATH                            # the post-edit hook is a python script
#   - widen the terminal to >= 100 columns       # rule summaries wrap below that
#   - if the terminal is dark-on-light, check the dim grey prompts are readable
#
# Run it once with --auto, then --cleanup, so the first live run is not the first run.

# Deliberately no `set -e`. A beat that fails should print its failure and let
# the rest of the deck run; a dead demo mid-screen-share is worse than a red one.
# Do not "fix" this.

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

AUTO=""
LOCAL=""
CLEANUP=""
WORKDIR=""

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
    case "$1" in
        --auto) AUTO=1 ;;
        --local) LOCAL=1 ;;
        --cleanup) CLEANUP=1 ;;
        --workdir) WORKDIR="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown flag: $1 (try -h)" >&2; exit 2 ;;
    esac
    shift
done

# ---------------------------------------------------------------- presentation

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
    G=$'\033[32m'; Y=$'\033[33m'; C=$'\033[36m'; M=$'\033[35m'
else
    B=""; D=""; R=""; G=""; Y=""; C=""; M=""
fi

beat() {
    printf '\n\n%s%s────────────────────────────────────────────────────────────────%s\n' "$C" "$B" "$R"
    printf '%s%s  %s%s\n' "$C" "$B" "$1" "$R"
    printf '%s%s────────────────────────────────────────────────────────────────%s\n' "$C" "$B" "$R"
}

# run "<command string>" — print the command, then run exactly that string, so
# what is on screen and what executed cannot diverge.
run() {
    printf '\n%s%s$ %s%s\n' "$G" "$B" "$1" "$R"
    eval "$1"
}

# run_capture "<command string>" — same, but keeps the output in $OUT and returns
# the command's exit code. Every number this demo quotes is grepped back out of
# $OUT, so the figures on screen come from the run the audience just watched
# rather than from a second, hidden invocation.
OUT=""
run_capture() {
    printf '\n%s%s$ %s%s\n' "$G" "$B" "$1" "$R"
    OUT="$(eval "$1" 2>&1)"
    local rc=$?
    [ -n "$OUT" ] && printf '%s\n' "$OUT"
    return $rc
}

# Anything the operator has to do or say, in a voice that cannot be mistaken
# for tool output.
cue() {
    printf '\n%s%s   %s%s\n' "$Y" "$B" "$1" "$R"
    printf '%s%s   %s%s\n' "$Y" "$D" "$2" "$R"
}

warn() { printf '%s%s!! %s%s\n' "$Y" "$B" "$1" "$R" >&2; }

fact() { printf '\n%s%s   %s%s\n' "$M" "$B" "$1" "$R"; }

# Every prompt says what the key does. "[any key]" leaves the operator guessing.
advance() {
    [ -n "$AUTO" ] && return 0
    printf '\n%s   [ %s ]%s' "$D" "$1" "$R"
    read -n 1 -s -r _ <&3
    printf '\r%*s\r' $((${#1} + 12)) ""
}

# ---------------------------------------------------------------- workspace

: "${TMPDIR:=/tmp}"
DEFAULT_WORKDIR="${TMPDIR%/}/swiftskim-demo"
WORKDIR="${WORKDIR:-$DEFAULT_WORKDIR}"
MARKER=".swiftskim-demo-workspace"

# --cleanup must never be able to reach a directory someone works in. It deletes
# only a directory this script created and stamped, and never a root or a home.
do_cleanup() {
    case "$WORKDIR" in
        ""|"/"|"$HOME"|"$HOME/"|"$REPO"|"$REPO"/*)
            echo "refusing to clean up '$WORKDIR'" >&2; exit 2 ;;
    esac
    if [ ! -d "$WORKDIR" ]; then
        echo "nothing to clean: $WORKDIR does not exist"; exit 0
    fi
    if [ ! -f "$WORKDIR/$MARKER" ]; then
        echo "refusing to clean up '$WORKDIR': no $MARKER stamp, this script did not create it" >&2
        exit 2
    fi
    rm -rf "$WORKDIR"
    echo "removed $WORKDIR"
    exit 0
}

[ -n "$CLEANUP" ] && do_cleanup

# ---------------------------------------------------------------- preflight

if [ -n "$LOCAL" ]; then
    if [ ! -x "$REPO/.build/release/swiftskim" ]; then
        echo "--local needs a release build. Fix: ./Scripts/build-all.sh" >&2
        exit 1
    fi
    PATH="$REPO/.build/release:$PATH"
    export PATH
fi

PREFLIGHT_FAIL=0
for tool in swiftskim swiftformat-smart swiftlint-smart; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        warn "missing '$tool' on PATH"
        PREFLIGHT_FAIL=1
    fi
done
if [ "$PREFLIGHT_FAIL" = "1" ]; then
    echo "Fix: brew install synodic-studio/synodic/swiftskim   (or: ./Scripts/build-all.sh && $0 --local)" >&2
    exit 1
fi

HOOK="$REPO/hooks/format-swift.py"
HOOK_OK=1
if ! command -v python3 >/dev/null 2>&1; then
    warn "no python3 — beat 4 (the post-edit hook) will be skipped"
    HOOK_OK=0
elif [ ! -f "$HOOK" ]; then
    warn "no $HOOK — beat 4 (the post-edit hook) will be skipped"
    HOOK_OK=0
fi

# The payoff is a workspace that did not exist a minute ago. A leftover from the
# last run silently destroys that, so refuse now rather than on the last slide.
if [ -d "$WORKDIR" ]; then
    echo "demo workspace already exists: $WORKDIR" >&2
    echo "Fix: $0 --cleanup" >&2
    exit 1
fi

if [ -z "$AUTO" ]; then
    if (exec 3</dev/tty) 2>/dev/null; then
        exec 3</dev/tty
    else
        warn "No terminal to read keypresses from, so every beat would run at once."
        warn "Run it from a terminal, or use --auto to run the whole thing."
        exit 1
    fi
fi

mkdir -p "$WORKDIR" || exit 1
touch "$WORKDIR/$MARKER"

printf '%s%sswiftskim — custom AST lint rules, packaged and enforced on every agent edit%s\n' "$B" "$C" "$R"
# Shown repo-relative when it is a local build, so a screen share never carries
# the operator's home directory.
SWIFTSKIM_BIN="$(command -v swiftskim)"
printf '%s  binary    %s%s\n' "$D" "${SWIFTSKIM_BIN#"$REPO"/}" "$R"
printf '%s  workspace %s%s\n' "$D" "$WORKDIR" "$R"
printf '%s  hook      %s%s\n' "$D" "$([ "$HOOK_OK" = 1 ] && echo "hooks/format-swift.py" || echo "unavailable — beat 4 skipped")" "$R"

advance "press to start beat 1"

# ================================================================ BEAT 1
beat "1 · The ruleset is data. And it is green on real code."

cd "$REPO" || exit 1

run_capture "swiftskim --list-rules"
RULE_COUNT="$(printf '%s\n' "$OUT" | grep -c '^  [a-z]')"

fact "$RULE_COUNT rules, counted off that output just now — not off a README."

cue "These are rules SwiftLint and SwiftFormat cannot express." \
    "They are structural: what a View's body may contain, and in what order."

advance "press to lint this repo's own source with its own rules"

run_capture "swiftskim ."
BEAT1_EXIT=$?
BEAT1_FILES="$(printf '%s\n' "$OUT" | grep -o '[0-9][0-9]* files checked' | head -1)"
BEAT1_COUNT="$(printf '%s\n' "$OUT" | grep -c '•')"

fact "${BEAT1_FILES:-files checked}, $BEAT1_COUNT violations, exit $BEAT1_EXIT. Remember those numbers."

advance "press to go to beat 2 — the same engine on code that has problems"

# ================================================================ BEAT 2
beat "2 · Ordinary SwiftUI code, linted live."

cd "$WORKDIR" || exit 1

cat > FeedItem.swift <<'SWIFT'
import Foundation

struct FeedItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
}
SWIFT

cat > FeedView.swift <<'SWIFT'
import SwiftUI

struct FeedView: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Recent") {
                    ForEach(items) { item in
                        HStack {
                            Text(item.title)
                            Spacer()
                            Text(item.subtitle)
                        }
                    }
                }
                Section("Archive") {
                    Text("Nothing archived yet")
                }
            }
            .searchable(text: $query)
            .navigationTitle("Feed")
        }
    }

    let items: [FeedItem] = []
}
SWIFT

run "cat -n FeedView.swift"

cue "Nothing exotic. This is the SwiftUI you get from any of us on a Tuesday." \
    "It compiles. Review would pass it. Watch what the engine says."

advance "press to lint it"

run_capture "swiftskim FeedView.swift"
BEAT2_EXIT=$?
BEAT2_COUNT="$(printf '%s\n' "$OUT" | grep -c '•')"
BEAT2_RULES="$(printf '%s\n' "$OUT" | grep -o '\[[a-z_]*\]' | sort -u | tr -d '[]' | tr '\n' ' ' | sed 's/ *$//')"
BEAT2_DEPTH="$(printf '%s\n' "$OUT" | grep -o 'nesting level [0-9]*' | tail -1)"

fact "$BEAT2_COUNT violations, exit $BEAT2_EXIT. Beat 1 was $BEAT1_COUNT and exit $BEAT1_EXIT."
fact "Rules that fired: ${BEAT2_RULES:-none}"
fact "'$BEAT2_DEPTH' is a tree depth. Nothing counted braces to get that."

advance "press to prove the rule ids are real filter keys, not decoration"

run "swiftskim --only-rules excessive_nesting FeedView.swift"

advance "press to go to beat 3 — why this cannot be a regex"

# ================================================================ BEAT 3
beat "3 · Why this cannot be regex."

cat > TagList.swift <<'SWIFT'
import SwiftUI

/// Renders the tag chips. A VStack { Text(...) } with a single child is a violation.
struct TagList: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
            }
        }
    }
}

struct EmptyTags: View {
    let placeholder = "VStack { Text(\"no tags\") }"

    var body: some View {
        VStack {
            Text(placeholder)
        }
    }
}

#Preview { TagList(tags: ["swift", "ast"]) }
SWIFT

run_capture "grep -n 'VStack' TagList.swift"
GREP_HITS="$(printf '%s\n' "$OUT" | grep -c .)"
# The three innocent hits, located rather than asserted.
LINE_COMMENT="$(grep -n '^///.*VStack' TagList.swift | cut -d: -f1)"
LINE_STRING="$(grep -n 'let placeholder' TagList.swift | cut -d: -f1)"
LINE_FOREACH="$(grep -n 'VStack(alignment' TagList.swift | cut -d: -f1)"

cue "$GREP_HITS textual hits. A text-pattern linter has to guess at all $GREP_HITS." \
    "One is a doc comment. One is inside a string literal. One is a real VStack that is fine."

advance "press to run the AST rule on the same file"

run_capture "swiftskim --only-rules stack_minimum_children TagList.swift"
BEAT3_EXIT=$?
BEAT3_COUNT="$(printf '%s\n' "$OUT" | grep -c '•')"
BEAT3_LINE="$(printf '%s\n' "$OUT" | grep -o 'Line [0-9]*' | head -1)"

fact "grep: $GREP_HITS hits. swiftskim: $BEAT3_COUNT violation at $BEAT3_LINE (exit $BEAT3_EXIT)."
fact "Lines $LINE_COMMENT and $LINE_STRING were skipped: a comment and a string literal. It parsed, it did not match."
fact "Line $LINE_FOREACH passed because that VStack's single child is a ForEach — variadic."

cue "That last one is the part you cannot regex at any price." \
    "'How many views does this produce' is a question about the tree, not the text."

advance "press to go to beat 4 — the packaging, and the part that makes it stick"

# ================================================================ BEAT 4
beat "4 · Installed as a package. Enforced on every agent edit."

cd "$REPO" || exit 1

run "cat .claude-plugin/marketplace.json"
run "cat hooks/hooks.json"

cue "That matcher is the whole argument. Every Edit, Write, MultiEdit and apply_patch." \
    "Not a CI job that fails an hour later. The edit itself does not land clean."

advance "press to see the file an agent is about to hand that hook"

if [ "$HOOK_OK" = "0" ]; then
    warn "beat 4 skipped: python3 or hooks/format-swift.py unavailable"
else
    # The real hook is invoked exactly as hooks.json declares it, via
    # $CLAUDE_PLUGIN_ROOT — so the command on screen is the shipped one.
    export CLAUDE_PLUGIN_ROOT="$REPO"
    cd "$WORKDIR" || exit 1

    cat > Badge.swift <<'SWIFT'
import SwiftUI
struct Badge : View {
    let count : Int
    var body : some View {
        Group {
            Text("\(count)")
        }
    }
}
#Preview { Badge(count: 3) }
SWIFT
    cp Badge.swift Badge.as-written.txt

    run "cat -n Badge.swift"

    cue "Pretend an agent just wrote that file. Sloppy spacing, and a Group body." \
        "The hook now gets the same JSON event Claude Code would send it."

    advance "press to send the PostToolUse event to the hook"

    EVENT="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"Badge.swift"},"cwd":"%s"}' "$WORKDIR")"
    printf '%s\n' "$EVENT" > event.json
    run "cat event.json"

    # Reason: single-quoted on purpose — run_capture prints this string and then
    # evals it, so what the audience sees is hooks.json's command verbatim.
    # shellcheck disable=SC2016
    run_capture 'python3 "$CLAUDE_PLUGIN_ROOT/hooks/format-swift.py" < event.json'
    HOOK_EXIT_BAD=$?
    HOOK_RULE="$(printf '%s\n' "$OUT" | grep -o '\[[a-z_]*\]' | sort -u | tr -d '[]' | tr '\n' ' ' | sed 's/ *$//')"

    fact "hook exit $HOOK_EXIT_BAD. Claude Code reads exit 2 as 'fix this and try again'."

    advance "press to see what the hook did to the file on its way past"

    run "diff -u Badge.as-written.txt Badge.swift"

    fact "The formatter fixed what is mechanical, in place, silently."
    fact "The linter refused the rest: ${HOOK_RULE:-the rule that fired} is a structural choice, not a typo."

    cue "So the split is the point. Anything decidable gets fixed without asking." \
        "Anything that is a design decision comes back to the author as a blocking error."

    advance "press to fix the Group body and re-send the identical event"

    cat > Badge.swift <<'SWIFT'
import SwiftUI

struct Badge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .monospacedDigit()
    }
}

#Preview { Badge(count: 3) }
SWIFT

    run "cat -n Badge.swift"
    # Reason: single-quoted on purpose — run_capture prints this string and then
    # evals it, so what the audience sees is hooks.json's command verbatim.
    # shellcheck disable=SC2016
    run_capture 'python3 "$CLAUDE_PLUGIN_ROOT/hooks/format-swift.py" < event.json'
    HOOK_EXIT_GOOD=$?

    fact "Same event, same hook, exit $HOOK_EXIT_GOOD. Silent. The edit lands."
    fact "exit $HOOK_EXIT_BAD -> exit $HOOK_EXIT_GOOD is the whole loop."
fi

advance "press for the close"

# ================================================================ CLOSE
cd "$REPO" || exit 1

SURFACES="$(sed -n '/^## Integration/,/^## Development/p' README.md | grep -c '^- \*\*')"
beat "So: $RULE_COUNT rules, one registry, $SURFACES delivery surfaces."

run "grep -n 'brew install synodic' README.md"
run "sed -n '/^## Integration/,/^## Development/p' README.md | grep -o '^- \*\*[^*]*\*\*'"

fact "Rule identity is single-sourced in RuleRegistry.swift, and a test asserts the registry and the engine's dispatch sites agree — so an id cannot drift."

cue "Everything on this screen is in the repo and runs in half a second." \
    "Clone it, point it at your own SwiftUI, and it will have opinions immediately."

printf '\n%s  workspace left at %s — clear it with: Scripts/demo.sh --cleanup%s\n\n' "$D" "$WORKDIR" "$R"
