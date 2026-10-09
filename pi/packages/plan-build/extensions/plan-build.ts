import {
  isToolCallEventType,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

type Mode = "plan" | "build";

const MODE_RE = /^(plan|build)\b/i;
const APPROVAL_RE =
  /^(ok|okay|k|kk|go|yes|yep|yeah|sure|agreed|approved|proceed|do it|go ahead|let'?s? do it|build it|sounds? good|looks? good|perfect|great)[.,!]?\s*(go|let'?s? go|do it|proceed|ahead|build)?[.,!]?$/i;
const APPROVAL_MAX_LEN = 30;

const PLAN_PROMPT = `

## PLAN MODE (active)
The user asked for a plan and the conversation is read-only until they approve it.
- Produce a structured implementation plan: goal, ordered steps, files to create/modify, tests to write/update, risks, open questions.
- Do NOT create, edit, or delete any files. Do NOT run mutating commands (installs, migrations, git write operations, shell redirects, etc.).
- Read-only inspection is allowed: ls, cat/grep/read, git status/diff/log, etc.
- If the user's message approves the plan or says to proceed ("ok", "go", "ok, go", "proceed", "sounds good"), switch to executing the plan instead.
- Otherwise end by telling the user to say "build" (or press Shift+Tab) to proceed.`;

const BUILD_PROMPT = `

## BUILD MODE (active)
The user approved the plan / said "build". Execute the agreed plan now:
- Make the changes described in the plan, in order.
- Run the relevant tests and verify the work.
- Report what was changed and what tests were run.`;

const MUTATION_PATTERNS: RegExp[] = [
  /\b(rm|mv|cp|touch|mkdir|rmdir|chmod|chown|ln|unlink|truncate|dd)\b/,
  /\b(npm|pnpm|yarn|bun|npx)\s+(install|add|remove|uninstall|ci|init|create)\b/,
  /\bcomposer\s+(require|remove|install|update|dump-autoload)\b/,
  /\bphp\s+artisan\s+(make|migrate|db:seed|db:wipe|db:drop|db:create|tinker)\b/,
  /\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|restore|clean|switch|stash\s+(pop|apply|drop)|branch\s+-[dD])\b/,
  /\b(curl|wget)\s+(--output|-o|-O)\b/,
  /\b(sed\s+-i|perl\s+-pi|tee)\b/,
  /\bee\b/,
  /(^|[;&|])\s*>+[^&]|\s>+[^&]/,
];

function isMutatingCommand(command: string): boolean {
  return MUTATION_PATTERNS.some((pattern) => pattern.test(command));
}

export default function (pi: ExtensionAPI) {
  let mode: Mode = "plan";

  const updateUI = (ctx: ExtensionContext) => {
    ctx.ui.setStatus("plan-build", mode === "plan" ? "PLAN MODE" : "BUILD MODE");
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

  const detectMode = (prompt: string): Mode | null => {
    const match = prompt.trim().match(MODE_RE);
    if (!match) return null;
    return match[1].toLowerCase() === "plan" ? "plan" : "build";
  };

  const isApproval = (prompt: string): boolean => {
    const trimmed = prompt.trim();
    return trimmed.length <= APPROVAL_MAX_LEN && APPROVAL_RE.test(trimmed);
  };

  // Initialize mode and restore state on session start
  pi.on("session_start", (_event, ctx) => {
    // Default to 'plan' as configured, unless restored from entries
    mode = "plan";

    // Inspect session entries for previously saved mode state
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
    } else if (mode === "plan" && isApproval(event.prompt)) {
      modeChanged = true;
      mode = "build";
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

    if (isToolCallEventType("bash", event) && isMutatingCommand(event.input.command)) {
      return {
        block: true,
        reason:
          'PLAN MODE: mutating command blocked. Say "build" (or press Shift+Tab) to allow changes.',
      };
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
