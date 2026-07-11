# Greatness Review — swiftskim

A judgment across four axes: reliability, README clarity, public adoptability, and portfolio fidelity. Written against the working tree on `develop` (post rule-registry rework, v1.0.0 tagged).

## 1. The essential model

swiftskim is one SwiftSyntax rule engine with a single-sourced identity for its 16 rules, wrapped in an opinionated orchestration layer (three config-discovering CLIs driving SwiftFormat/SwiftLint plus the engine), and delivered as many thin, skippable surfaces — CLI/Homebrew, Xcode build phase, SwiftPM library, Claude Code/Codex/Cursor hooks, pi extension — each checked by a release-gate harness.

Greatness for this project means exactly two things: **(a)** a stranger who finds the repo can get from "never heard of it" to "linting my project, with the rules I don't want turned off" in minutes, on the artifact the maintainer actually verified; **(b)** every claim any surface makes about the tool — rule list, suppression syntax, install path — is provably the same claim the engine enforces. The registry rework was built to deliver (b). The review question is how far (a) and (b) actually extend today.

## 2. Axis-by-axis judgment

### Reliability — good, one structural flaw from great

What's genuinely strong:

- **The conformance lock is real.** `Tests/SharedUtilitiesTests/RuleConformanceTests.swift` regex-extracts rule ids from `RuleRegistry.swift` and dispatch sites from `CustomRulesVisitor.swift` and asserts set equality both directions, with a count pin at 16. It's a source-scrape rather than a runtime check, but for the failure class it targets (the `prefer_zero_param_onchange` / `onchange_ignored_old_value` split-identity bug) it is exactly sufficient.
- **The harness is well designed.** `Scripts/verify-all.sh` runs every step without stopping at first failure, prints a pass/fail summary, and separates a no-network local stage from a release stage that consumes the pushed HEAD. Per-surface scripts run standalone. The Linux clean-room (`verify-consumer-linux.sh`) and the shared consumer scaffold (`Scripts/helpers/emit-spm-consumer.sh`, preventing macOS/Linux consumer drift) are above the bar for a solo tool.
- **Installs are relocatable by construction.** `Sources/SharedUtilities/ConfigDiscovery.swift` resolves bundled resources via `SWIFTSKIM_HOME` override → walk-up-from-binary marker search → honest fallback, and the engine binary via `SWIFTSKIM_ENGINE` → sibling → dev layout. No hardcoded personal paths; `verify-brew-install.sh` step 3 explicitly checks sibling co-install.
- **The known weak surfaces fail honestly.** Codex/Cursor hooks are synthetic-payload-only and fail open; this is disclosed in the README (Integration section), in `verify-agent-hooks.sh`'s header comment, and on the portfolio page. Disclosed best-effort is a reliability *feature* here, not a gap.

**The single weakest link: the release gate verifies a different artifact than the one it releases.** `verify-brew-install.sh` does `brew install --HEAD` (line 15) — it exercises the develop-HEAD build. But the formula's *default* stable path pins the `v1.0.0` tag (`homebrew-synodic/Formula/swiftskim.rb`), and the portfolio page tells the public "brew install … (tagged release)". Likewise `verify-consumer-spm.sh --remote` and the Linux clean-room pin `branch: "develop"`, and the README's SPM snippet (line 154) tells consumers to depend on `branch: "develop"` rather than `from: "1.0.0"` despite the tag existing. Net effect: **every path a public user is told to take resolves the tag or should, and no gate step ever builds the tag.** For v1.0.0 the tag presumably sits at/near the verified HEAD, so this is latent — but it becomes a real hole on the first post-tag commit, and it inverts the harness's own thesis ("a surface can't silently rot").

Secondary, smaller: the gate is manual discipline. There is no CI by policy (owner's global setup) and, as far as the repo shows, nothing binds "tag/push a release" to "verify-all --release passed" — the portfolio's "a release refuses to ship until all of them pass" describes a habit, not a mechanism. Acceptable for a solo shop; worth knowing it's a habit. Also, `RuleRegistry.swift`'s doc comment says the README table and CLAUDE.md list "are all expected to derive from (or be verified against) this array," but the conformance test only checks the dispatcher — the doc lists are unverified (and see the next axis for the consequence).

### README clarity — good bones, stale in the one place accuracy matters most

The structure is right: "What it is (and isn't)" owns the opinionated-orchestrator identity up front, honestly names the SwiftFormat/SwiftLint hard dependency, and correctly carves out the style-neutral engine/library as the separable novel part. The bring-your-own-rule section with a compilable `Rule` example is the best part of the file. The Codex/Cursor caveats are candid.

Three defects, in order of severity:

1. **The "Suppressing a rule" section teaches the legacy prefix as the primary one.** README lines 160–170 present `swiftlintcustom:` as *the* directive prefix, complete with the design rationale. `DirectiveParser.swift` (line 20) is unambiguous: `swiftskim` is primary, `swiftlintcustom` is the legacy alias. The README is even internally inconsistent — line 148 ("Your rule id participates in `swiftskim:disable`") uses the new prefix. The portfolio page documents this correctly; the repo's own front door does not. A new user copying the README example writes legacy syntax on day one. AGENTS.md carries the same stale prefix (internal, lower stakes).
2. **Installation omits Homebrew entirely.** README "Installation" offers only clone-and-build, while a working formula exists and the portfolio advertises `brew install synodic-studio/synodic/swiftskim` as the primary path. The marketing page has better install instructions than the repo.
3. **A small overclaim:** "The help text and this README derive from that registry" (lines 45–47). The `--list-rules` output does; the README's grouped rule list (lines 107–113) is a hand-maintained copy that no test checks. It happens to match `RuleRegistry.all` today. Stating the drift-proofing is broader than it is undercuts the project's most distinctive claim.

Weakest link: defect 1 — it's the exact failure mode (documented identity diverging from enforced identity) the whole rework existed to kill, resurfacing in prose instead of code.

### Public adoptability — short of great, and the gaps are decisions, not code volume

What works for a stranger: prerequisites are honest (SwiftFormat, SwiftLint, the Swift 6.1 floor with its SE-0439 rationale in both README and `Package.swift`'s header comment); config discovery means zero path setup; the two-threshold `swiftskim:` config block means the two most-contested numbers are tunable without forking; the engine-as-library escape hatch serves people who reject the house style entirely.

What blocks a stranger:

1. **No config-level per-rule opt-out.** The only rule filter is the `--only-rules` CLI allowlist (`Sources/SwiftLintCustomSmart/main.swift` line 28; engine `main.swift` line 18). A non-author adopter will accept perhaps 12 of the 16 rules and reject a few wholesale — `preview_required`, `prefer_swift_testing`, and `single_modifier_per_line` are strong house taste. Their options today: pass a 12-item allowlist on every invocation (and keep it synced across CLI, Xcode phase, and agent hook), or sprinkle suppression comments per violation forever. Thresholds got first-class config treatment; rule selection didn't. Whether this is a deliberate "the 16 are a package deal" stance or an accident is undecided — and undecided is the problem. (Flagging the gap, not prescribing the mechanism.)
2. **The easiest install path is hidden** (README defect 2 above) and the documented SPM dependency is a moving branch rather than the tagged version — a public consumer pinning `branch: "develop"` gets whatever lands next, which is the opposite of what a version tag was created to offer.
3. Minor: adopting only the AST engine via CLI still rides in a toolkit whose README leads with the SwiftFormat/SwiftLint pairing; the "(and isn't)" section mitigates this well enough.

Weakest link: gap 1. Everything else on this axis is documentation; this one is a product stance.

### Portfolio fidelity — great; it currently outruns the repo

`synodic-co/content/english/swiftskim.md` is accurate against the code to an unusual degree: the 16-rule list matches `RuleRegistry.all` summaries; the suppression section documents `swiftskim:` primary with `swiftlintcustom:` legacy — *correct where the README is wrong*; the registry-bug story (`prefer_zero_param_onchange`) matches the conformance test's own doc comment; "106 tests" matches the actual `@Test` count (verified: 106); the verification paragraph describes exactly what the scripts do, including the best-effort Codex/Cursor caveat. The "What to take from this" closer earns its place — three genuinely portable patterns, stated as engineering lessons rather than self-praise.

Two soft spots, neither disqualifying: "a release refuses to ship until all of them pass" implies enforcement where there is discipline (inference from repo contents — no hook/CI binds the gate to a release), and the brew line advertises the tagged path the gate never exercises (the axis-1 flaw, faithfully mirrored). The portfolio's only real problem is that it makes promises the repo's front door and gate haven't caught up to.

## 3. The gap to greatness

Ranked by the cost of leaving them, highest first:

1. **The verified artifact and the shipped artifact are different objects.** Stakes: the first post-1.0 commit makes the public brew/SPM stable path silently unverified — the exact rot class the harness was built to kill, on the highest-traffic surface. Options: (a) add tag-pinned variants to the release stage (`brew install` without `--HEAD`; a consumer pinned `from: "1.0.0"`), or (b) declare HEAD the only supported public path and strip the tag story from the portfolio and formula. Either is coherent; the current split is not.
2. **The README contradicts the code on suppression and hides the best install path.** Stakes: every new adopter learns the legacy directive prefix and takes the hardest install route; the project's signature claim (docs can't drift) is falsified by its own front door. This is the cheapest fix in the whole review — a single doc pass syncing README (and AGENTS.md) to `DirectiveParser.swift`, the formula, and the tag — and until it lands, both axes 2 and 3 are capped.
3. **The per-rule opt-out stance is undecided.** Stakes: this is the difference between "opinionated tool a stranger can adopt" and "author's tool a stranger can visit." If the 16-as-package-deal is the position, one README paragraph saying so (and pointing at `--only-rules` + the library) converts the gap into a stated opinion. If it isn't the position, this is the one place real code is missing. Cost of leaving it: silent — adopters don't file issues, they just leave.
4. **Codex/Cursor live smoke.** Stakes: low — the caveat is disclosed everywhere, the hook fails open, Claude Code and pi are verified. One live session each would upgrade "best-effort" to "verified"; leaving it costs only the italics.

Item 3 deliberately outranks nothing above it: greatness on the adoption axis is gated by items 1–2 first, because today an adopter can't even reach the point where rule selection is their blocker without tripping over the install and directive docs.

## 4. Verdict

**Good — one deliberate doc pass and one gate fix from great on three of four axes.** The engineering substance is already at the target: the registry invariant is real and tested, the harness design is better than most funded tools ship, config discovery makes installs genuinely self-standing, and the portfolio page is that rare thing, marketing that's more accurate than the README.

The two things that matter next, in order: **(1)** make the release gate exercise the tagged artifact the public is told to install (or explicitly renounce the tag) — this is the only gap that compounds with every future commit; **(2)** one synchronization pass bringing README/AGENTS.md up to the code and formula — primary `swiftskim:` prefix, Homebrew install, `from: "1.0.0"` SPM guidance, and honest scoping of the "derives from the registry" claim. Both are small; together they close the loop the project's own thesis demands — that what it documents, what it verifies, and what it ships are the same thing. Decide the per-rule opt-out stance whenever the next adopter conversation forces it; write the decision down either way.
