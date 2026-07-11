// Pi extension for swiftskim: lint Swift with the swiftskim AST rules.
//
// Registers two tools a pi coding agent can call:
//   - swiftskim_lint:       run the custom SwiftSyntax rules on a file/dir
//   - swiftskim_list_rules: list all rule ids and summaries
//
// The swiftskim binary is resolved from SWIFTSKIM_BIN (if set) else assumed on
// PATH (Homebrew install: `brew install synodic-studio/synodic/swiftskim`).
// All exec calls use argv arrays, so shell metacharacters are inert; paths are
// contained to the project directory and rule ids are allowlisted.

import type {
	AgentToolResult,
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import * as path from "path";

function ok(text: string): AgentToolResult {
	return { content: [{ type: "text", text }] };
}

function swiftskimBin(): string {
	return process.env.SWIFTSKIM_BIN || "swiftskim";
}

// Comma-separated snake_case rule ids only.
const RULES_RE = /^[a-z_]+(,[a-z_]+)*$/;

function safeProjectPath(cwd: string, rel: string): string {
	if (path.isAbsolute(rel)) throw new Error(`Absolute paths not allowed: ${rel}`);
	const resolved = path.resolve(cwd, rel);
	const base = cwd.endsWith(path.sep) ? cwd : cwd + path.sep;
	if (resolved !== cwd && !resolved.startsWith(base)) {
		throw new Error(`Path escapes project directory: ${rel}`);
	}
	return resolved;
}

export default function extension(pi: ExtensionAPI) {
	const exec = (args: string[], cwd: string, signal?: AbortSignal) =>
		pi.exec(swiftskimBin(), args, { cwd, signal, timeout: 60_000 });

	pi.registerTool({
		name: "swiftskim_lint",
		label: "Lint Swift (swiftskim)",
		description:
			"Run swiftskim's custom SwiftSyntax rules on a Swift file or directory. " +
			"Reports SwiftUI structure and general Swift hygiene violations that " +
			"text-pattern linters cannot express. Non-zero output means violations.",
		parameters: {
			type: "object",
			properties: {
				path: {
					type: "string",
					description: "Swift file or directory to lint, relative to project root",
				},
				only_rules: {
					type: "string",
					description:
						"Optional comma-separated rule ids to run (e.g. skimmable_body,no_group_body)",
				},
			},
			required: ["path"],
		} as any,
		async execute(
			_id: string,
			params: { path: string; only_rules?: string },
			signal: AbortSignal | undefined,
			_update: unknown,
			ctx: ExtensionContext,
		): Promise<AgentToolResult> {
			try {
				const target = safeProjectPath(ctx.cwd, params.path);
				const args = [target];
				if (params.only_rules) {
					if (!RULES_RE.test(params.only_rules)) {
						throw new Error(`Invalid rule ids: ${params.only_rules}`);
					}
					args.push("--only-rules", params.only_rules);
				}
				const r = await exec(args, ctx.cwd, signal);
				const out = (r.stdout + r.stderr).trim();
				return ok(out || "No violations found.");
			} catch (e: any) {
				return ok(`Error: ${e.message}`);
			}
		},
	});

	pi.registerTool({
		name: "swiftskim_list_rules",
		label: "List swiftskim rules",
		description: "List every swiftskim rule id with its one-line summary.",
		parameters: { type: "object", properties: {} } as any,
		async execute(
			_id: string,
			_params: Record<string, never>,
			signal: AbortSignal | undefined,
			_update: unknown,
			ctx: ExtensionContext,
		): Promise<AgentToolResult> {
			try {
				const r = await exec(["--list-rules"], ctx.cwd, signal);
				return ok((r.stdout + r.stderr).trim());
			} catch (e: any) {
				return ok(`Error: ${e.message}`);
			}
		},
	});
}
