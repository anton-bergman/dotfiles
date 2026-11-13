import type {
	ExtensionAPI,
	ExtensionContext,
} from "@earendil-works/pi-coding-agent";

function isToolCallEventType(
	toolName: string,
	event: { toolName: string },
): boolean {
	return event.toolName === toolName;
}

type Mode = "plan" | "build";

const MODE_RE = /^(plan|build)\b/i;

const PLAN_PROMPT = `

## PLAN MODE (active)
The user asked for a plan. The environment is in a protected read-only state until they approve it.

### Execution Invariants:
1. ZERO FILE WRITES: Do not create, edit, rename, or delete workspace files (tools 'write', 'edit', 'rename' are blocked).
2. ZERO GIT MUTATIONS: Do not alter git index, commits, branches, or worktree state.
3. ZERO REMOTE MUTATIONS: Do not execute cloud DDL/DML, infrastructure mutations, or mutating MCP actions.

### Computational Inspection IS EXPLICITLY AUTHORIZED:
- You are actively encouraged to run non-mutating ad-hoc scripts (e.g. python3 -c "...", node -e "...", bun -e "...") to analyze data, parse tensors, or inspect runtime environments.
- You are authorized to run read-only database queries (e.g. analytical query with SELECT) and passive cloud reads (aws/gcloud/az describe/list/get).
- Never refuse an ad-hoc calculation, data inspection, or read-only query because you are in plan mode. Execute the inspection and use the findings to author an accurate plan.

When planning is complete, prompt the user to say "build" (or press Shift+Tab) to proceed to implementation.`;

const BUILD_PROMPT = `

## BUILD MODE (active)
The user approved the plan / said "build". Execute the agreed plan now:
- Make the changes described in the plan, in order.
- Run the relevant tests and verify the work.
- Report what was changed and what tests were run.`;

/**
 * Masks single-quoted and double-quoted string literals with an inert placeholder.
 * Handles escaped quotes correctly so comparisons (> or >=) inside Python/Node/SQL
 * strings are never mistaken for shell redirections or mutating keywords.
 */
export function maskStringLiterals(cmd: string): string {
	return cmd
		.replace(/'(\\.|[^'\\])*'/g, "'__STR__'")
		.replace(/"(\\.|[^"\\])*"/g, '"__STR__"');
}

/**
 * Splits a compound command line into individual pipeline/command stages
 * by unquoted delimiters (; && || |).
 */
export function splitPipelineStages(cmd: string): string[] {
	const stages: string[] = [];
	let current = "";
	let inSingleQuote = false;
	let inDoubleQuote = false;
	let escaped = false;

	for (let i = 0; i < cmd.length; i++) {
		const ch = cmd[i];

		if (escaped) {
			current += ch;
			escaped = false;
			continue;
		}

		if (ch === "\\") {
			current += ch;
			escaped = true;
			continue;
		}

		if (ch === "'" && !inDoubleQuote) {
			inSingleQuote = !inSingleQuote;
			current += ch;
			continue;
		}

		if (ch === '"' && !inSingleQuote) {
			inDoubleQuote = !inDoubleQuote;
			current += ch;
			continue;
		}

		if (!inSingleQuote && !inDoubleQuote) {
			if (ch === ";") {
				if (current.trim()) stages.push(current.trim());
				current = "";
				continue;
			}
			if (ch === "&" && cmd[i + 1] === "&") {
				if (current.trim()) stages.push(current.trim());
				current = "";
				i++;
				continue;
			}
			if (ch === "|" && cmd[i + 1] === "|") {
				if (current.trim()) stages.push(current.trim());
				current = "";
				i++;
				continue;
			}
			if (ch === "|" && cmd[i + 1] !== "|") {
				if (current.trim()) stages.push(current.trim());
				current = "";
				continue;
			}
		}

		current += ch;
	}

	if (current.trim()) {
		stages.push(current.trim());
	}

	return stages;
}

export interface MutationCheckResult {
	blocked: boolean;
	reason?: string;
}

const POSIX_FILE_MUTATIONS =
	/\b(rm|mv|cp|touch|mkdir|rmdir|chmod|chown|ln|unlink|truncate|dd|tee)\b/;
const IN_PLACE_EDITORS = /\b(sed\s+-i|perl\s+-pi)\b/;
const PACKAGE_MANAGERS =
	/\b(npm|pnpm|yarn|bun|npx|pip|pip3|uv|poetry|cargo)\s+(install|add|remove|uninstall|ci|init|create)\b/;
const COMPOSER_PHP =
	/\b(composer\s+(require|remove|install|update|dump-autoload)|php\s+artisan\s+(make|migrate|db:seed|db:wipe|db:drop|db:create|tinker))\b/;

const GIT_MUTATION_VERBS =
	/\bgit\s+(add|commit|push|pull|rebase|reset|restore|clean|checkout|switch|stash(\s+(push|pop|apply|drop|clear))?|branch\s+(-[dD]|--delete|-m|-M|--move))\b/;
// git merge is blocked unless it is merge-base or merge-tree
const GIT_MERGE_BARE = /\bgit\s+merge(?!\s*-(base|tree))\b/;

const SQL_CLI = /\b(bq|psql|mysql|clickhouse|duckdb|snowsql)\b/;
const SQL_DML_DDL =
	/\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|MERGE|TRUNCATE|GRANT|REVOKE)\b/i;

const CLOUD_INFRA_CLIS = /\b(aws|gcloud|az|kubectl|helm|terraform|pulumi|gh)\b/;
const CLOUD_WRITE_VERBS =
	/\b(create|apply|delete|destroy|drop|put|update|patch|set|deploy|terminate|restart|start|stop|run)\b/i;
const DRY_RUN_PATTERN =
	/(?:^|\s)(--dry-run(=[a-zA-Z_-]+)?|--dry_run|-n)(?:\s|$)/;

const HTTP_FILE_DOWNLOAD = /\b(curl|wget)\s+.*(--output|-o|-O)\b/;
const HTTP_MUTATION_METHODS =
	/\bcurl\s+.*(-X\s*(POST|PUT|DELETE|PATCH)|-d|--data|--json)\b/;

/**
 * Checks a single pipeline stage for state mutations across the 5 generalized categories.
 */
function checkStageMutation(rawStage: string): MutationCheckResult {
	const stage = rawStage.trim();
	if (!stage) return { blocked: false };

	// Subshell unwrapping: recursively evaluate bash -c "<subcmd>", sh -c "<subcmd>", etc.
	// Supports optional leading environment variable assignments (e.g. FOO=1 bash -c "...")
	const subshellMatch = stage.match(
		/^(?:(?:[a-zA-Z_][a-zA-Z0-9_]*=.*?\s+)*)(?:bash|sh|zsh)\s+-c\s+(['"])([\s\S]*)\1$/,
	);
	if (subshellMatch) {
		return checkCommandMutation(subshellMatch[2]);
	}

	const masked = maskStringLiterals(stage);

	// Category 1: Shell Redirections & Local Filesystem
	// Strip safe output silencing to /dev/null and fd redirects (2>&1, 1>&2, >&-, <&-)
	const withoutNull = masked
		.replace(/(?:&>|&>>|\d*>|\d*>>|>|>>)\s*\/dev\/null/g, "")
		.replace(/\d*>&[0-9-]/g, "")
		.replace(/\d*<&[0-9-]/g, "");

	// Match any file redirect: >, >>, &>, &>>, 1>, 2> targeting a file
	if (/(?:&>|&>>|\d*>|\d*>>|>|>>)\s*(?!\/dev\/null)[^\s;&|]/.test(withoutNull)) {
		return {
			blocked: true,
			reason:
				"PLAN MODE: Shell file redirection ('>' or '&>') is blocked. File modifications are prohibited in plan mode.",
		};
	}

	if (
		POSIX_FILE_MUTATIONS.test(masked) ||
		IN_PLACE_EDITORS.test(masked) ||
		/\bee\b/.test(masked)
	) {
		return {
			blocked: true,
			reason:
				"PLAN MODE: Filesystem modification command is blocked. Modifying files is prohibited in plan mode.",
		};
	}

	if (PACKAGE_MANAGERS.test(masked) || COMPOSER_PHP.test(masked)) {
		return {
			blocked: true,
			reason:
				"PLAN MODE: Package manager install/remove command is blocked in plan mode.",
		};
	}

	// Category 2: Git Repository State
	if (GIT_MUTATION_VERBS.test(masked) || GIT_MERGE_BARE.test(masked)) {
		return {
			blocked: true,
			reason:
				"PLAN MODE: Git mutation command is blocked. Only read-only operations (git status, diff, log, merge-base) are allowed.",
		};
	}

	// Category 3: SQL / Data Warehouse DDL & DML
	if (SQL_CLI.test(masked) && SQL_DML_DDL.test(stage)) {
		if (!DRY_RUN_PATTERN.test(stage)) {
			return {
				blocked: true,
				reason:
					"PLAN MODE: SQL DDL/DML mutation is blocked. Read-only queries (SELECT, EXPLAIN) are allowed.",
			};
		}
	}

	// Category 4: HTTP / Network Mutations
	if (HTTP_FILE_DOWNLOAD.test(masked)) {
		return {
			blocked: true,
			reason: "PLAN MODE: File download via curl/wget is blocked in plan mode.",
		};
	}
	if (HTTP_MUTATION_METHODS.test(stage)) {
		return {
			blocked: true,
			reason:
				"PLAN MODE: Mutating HTTP method/payload is blocked. Only read-only requests (GET/HEAD) are allowed.",
		};
	}

	// Category 5: Cloud & Infrastructure CLIs
	if (CLOUD_INFRA_CLIS.test(masked)) {
		const isDryRun = DRY_RUN_PATTERN.test(stage);
		if (!isDryRun) {
			// Check GitHub CLI specifically
			if (
				/\bgh\b/.test(masked) &&
				/\bgh\s+.*\b(create|close|merge|comment|delete|edit|ready)\b/.test(
					masked,
				)
			) {
				return {
					blocked: true,
					reason:
						"PLAN MODE: GitHub CLI mutation is blocked. Read commands (gh pr/issue view, list, status) are allowed.",
				};
			}
			// General cloud CLI check
			if (CLOUD_WRITE_VERBS.test(masked)) {
				return {
					blocked: true,
					reason:
						"PLAN MODE: Cloud/infrastructure mutation verb is blocked. Read/inspect verbs (list, get, describe, show, diff) are allowed.",
				};
			}
		}
	}

	return { blocked: false };
}

/**
 * Checks a full bash command line by splitting into pipeline stages and testing each.
 */
export function checkCommandMutation(command: string): MutationCheckResult {
	const stages = splitPipelineStages(command);
	for (const stage of stages) {
		const result = checkStageMutation(stage);
		if (result.blocked) {
			return result;
		}
	}
	return { blocked: false };
}

export function isMcpMutationTool(toolName: string): boolean {
	if (!toolName.startsWith("mcp__")) return false;
	const parts = toolName.split("__");
	const action = parts[parts.length - 1] || "";
	return (
		/^(create|upsert|insert|update|delete|drop|alter|post|patch|put|remove|destroy|apply|publish)/i.test(
			action,
		) ||
		/_(create|upsert|insert|update|delete|drop|alter|post|patch|put|remove|destroy|apply|publish)$/i.test(
			action,
		)
	);
}

export function isMutatingCommand(command: string): boolean {
	return checkCommandMutation(command).blocked;
}

export default function(pi: ExtensionAPI) {
	let mode: Mode = "plan";

	const updateUI = (ctx: ExtensionContext) => {
		ctx.ui.setStatus(
			"plan-build",
			mode === "plan" ? "PLAN MODE" : "BUILD MODE",
		);
	};

	const setMode = (next: Mode, ctx: ExtensionContext) => {
		mode = next;
		updateUI(ctx);
		ctx.ui.notify(
			mode === "plan"
				? "PLAN MODE: planning only, no changes"
				: "BUILD MODE: changes allowed",
			"info",
		);
	};

	const detectMode = (prompt?: string): Mode | null => {
		if (!prompt || typeof prompt !== "string") return null;
		const match = prompt.trim().match(MODE_RE);
		if (!match) return null;
		return match[1].toLowerCase() === "plan" ? "plan" : "build";
	};

	// Initialize mode and restore state on session start
	pi.on("session_start", (_event, ctx) => {
		mode = "plan";

		for (const entry of ctx.sessionManager.getEntries()) {
			if (
				entry.type === "custom" &&
				entry.customType === "plan_build_mode" &&
				typeof (entry.data as { mode?: Mode })?.mode === "string"
			) {
				mode = (entry.data as { mode: Mode }).mode;
			}
		}

		updateUI(ctx);
	});

	pi.on("before_agent_start", async (event, ctx) => {
		const detected = detectMode(event.prompt);
		let modeChanged = false;

		if (detected) {
			modeChanged = mode !== detected;
			mode = detected;
			updateUI(ctx);
			pi.appendEntry({ mode }, "plan_build_mode");
		}

		if (mode === "plan") {
			return { systemPrompt: event.systemPrompt + PLAN_PROMPT };
		}
		if (modeChanged) {
			return { systemPrompt: event.systemPrompt + BUILD_PROMPT };
		}
		return undefined;
	});

	pi.on("tool_call", async (event, _ctx) => {
		if (mode !== "plan") return undefined;

		// Block native file-writing tools
		if (
			isToolCallEventType("write", event) ||
			isToolCallEventType("edit", event) ||
			isToolCallEventType("rename", event)
		) {
			return {
				block: true,
				reason:
					'PLAN MODE: file changes are blocked. Say "build" (or press Shift+Tab) to allow changes.',
			};
		}

		// Block mutating MCP tools
		if (isMcpMutationTool(event.toolName)) {
			return {
				block: true,
				reason: `PLAN MODE: MCP mutation tool '${event.toolName}' is blocked. Remote state modifications are prohibited in plan mode.`,
			};
		}

		// Check bash command lines
		if (isToolCallEventType("bash", event)) {
			const check = checkCommandMutation(event.input.command);
			if (check.blocked) {
				return {
					block: true,
					reason:
						check.reason ||
						'PLAN MODE: mutating command blocked. Say "build" (or press Shift+Tab) to allow changes.',
				};
			}
		}

		return undefined;
	});

	// Shift+Tab global shortcut toggle
	pi.registerShortcut("shift+tab", {
		description: "Toggle Plan/Build mode",
		handler: async (ctx) => {
			const next = mode === "plan" ? "build" : "plan";
			setMode(next, ctx);
			pi.appendEntry({ mode: next }, "plan_build_mode");
		},
	});

	// Slash commands
	pi.registerCommand("plan", {
		description: "Switch to PLAN mode (planning only, no changes)",
		handler: async (_args, ctx) => {
			setMode("plan", ctx);
			pi.appendEntry({ mode: "plan" }, "plan_build_mode");
		},
	});

	pi.registerCommand("build", {
		description: "Switch to BUILD mode (changes allowed)",
		handler: async (_args, ctx) => {
			setMode("build", ctx);
			pi.appendEntry({ mode: "build" }, "plan_build_mode");
		},
	});

	pi.registerCommand("plan-toggle", {
		description: "Toggle between PLAN and BUILD modes",
		handler: async (_args, ctx) => {
			const next = mode === "plan" ? "build" : "plan";
			setMode(next, ctx);
			pi.appendEntry({ mode: next }, "plan_build_mode");
		},
	});
}
