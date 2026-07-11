// Deterministic verification that the swiftskim pi extension registers its tools
// and that they work against the real swiftskim binary.
//
// It loads the extension's default export with a stub ExtensionAPI (capturing
// registerTool and providing `exec` via child_process), then invokes each tool's
// execute() and asserts on the output — no interactive agent loop, so it's
// repeatable. The `import type` lines in tools.ts are erased by Node's TS support.
//
// Run:  node pi/verify-extension.mjs
// Env:  SWIFTSKIM_BIN — path to the swiftskim binary (defaults to `swiftskim` on PATH)

import { spawn } from "node:child_process";
import { mkdtempSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import assert from "node:assert/strict";
import extension from "./tools.ts";

const tools = {};
const pi = {
	registerTool(def) {
		tools[def.name] = def;
	},
	exec(bin, args, opts = {}) {
		return new Promise((resolve, reject) => {
			const child = spawn(bin, args, { cwd: opts.cwd });
			let stdout = "";
			let stderr = "";
			child.stdout.on("data", (d) => (stdout += d));
			child.stderr.on("data", (d) => (stderr += d));
			child.on("error", reject);
			child.on("close", () => resolve({ stdout, stderr }));
		});
	},
};

// 1. The extension loads and registers both tools under their expected names.
extension(pi);
assert.ok(tools.swiftskim_lint, "swiftskim_lint not registered");
assert.ok(tools.swiftskim_list_rules, "swiftskim_list_rules not registered");
console.log("✅ extension imported; both tools registered");

const work = mkdtempSync(join(tmpdir(), "swiftskim-pi-"));
try {
	const ctx = { cwd: work };

	// 2. list_rules surfaces the rule registry.
	const list = await tools.swiftskim_list_rules.execute("t", {}, undefined, null, ctx);
	const listText = list.content[0].text;
	assert.ok(listText.includes("16 total"), `list-rules missing '16 total':\n${listText}`);
	console.log("✅ swiftskim_list_rules reports 16 rules");

	// 3. lint flags a real violation on bad input.
	writeFileSync(
		join(work, "BadView.swift"),
		[
			"import SwiftUI",
			"struct BadView: View {",
			"    var body: some View {",
			"        Group {",
			'            Text("hi")',
			"        }",
			"    }",
			"}",
			"",
		].join("\n"),
	);
	const lint = await tools.swiftskim_lint.execute("t", { path: "BadView.swift" }, undefined, null, ctx);
	const lintText = lint.content[0].text;
	assert.ok(lintText.includes("no_group_body"), `lint missing no_group_body:\n${lintText}`);
	console.log("✅ swiftskim_lint flags no_group_body on bad input");

	// 4. the path-safety guard rejects paths escaping the project dir.
	const esc = await tools.swiftskim_lint.execute("t", { path: "../escape" }, undefined, null, ctx);
	assert.ok(
		esc.content[0].text.startsWith("Error:"),
		`expected path-escape error, got: ${esc.content[0].text}`,
	);
	console.log("✅ swiftskim_lint rejects a path escaping the project dir");

	console.log("🎉 pi extension verification passed");
} finally {
	rmSync(work, { recursive: true, force: true });
}
