import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

function copyToClipboard(text: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const proc = spawn("pbcopy");
    proc.stdin.write(text);
    proc.stdin.end();
    proc.on("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`pbcopy failed with code ${code}`));
    });
    proc.on("error", reject);
  });
}

function extractLastCodeBlock(markdown: string): string | null {
  // Matches any fenced code block ```[lang]\n...\n```
  const matches = [...markdown.matchAll(/```(?:\w+)?\n([\s\S]*?)```/g)];
  if (matches.length > 0) {
    const lastMatch = matches[matches.length - 1];
    return lastMatch ? lastMatch[1].trim() : null;
  }
  return null;
}

export default function (pi: ExtensionAPI) {
  const copyLatestCode = async (ctx: ExtensionContext) => {
    const entries = ctx.sessionManager.getEntries();

    // Search backwards for the latest assistant message
    let lastAssistantText: string | null = null;
    for (let i = entries.length - 1; i >= 0; i--) {
      const entry = entries[i];
      if (entry.type === "message" && entry.message.role === "assistant") {
        const content = entry.message.content;
        if (typeof content === "string") {
          lastAssistantText = content;
          break;
        } else if (Array.isArray(content)) {
          // Content is an array of parts
          const textParts = content
            .filter((p): p is { type: "text"; text: string } => p.type === "text")
            .map((p) => p.text);
          if (textParts.length > 0) {
            lastAssistantText = textParts.join("\n");
            break;
          }
        }
      }
    }

    if (!lastAssistantText) {
      ctx.ui.notify("No assistant message found to copy from", "warning");
      return;
    }

    const codeBlock = extractLastCodeBlock(lastAssistantText);
    const toCopy = codeBlock || lastAssistantText.trim();

    try {
      await copyToClipboard(toCopy);
      if (codeBlock) {
        ctx.ui.notify("Copied code block to clipboard", "info");
      } else {
        ctx.ui.notify("Copied message text to clipboard", "info");
      }
    } catch (err) {
      ctx.ui.notify(`Failed to copy: ${String(err)}`, "error");
    }
  };

  // Register Alt+C global shortcut
  pi.registerShortcut("alt+c", {
    description: "Copy latest assistant code block to clipboard",
    handler: copyLatestCode,
  });

  // Register /copy-code command
  pi.registerCommand("copy-code", {
    description: "Copy latest assistant code block to clipboard",
    handler: async (_args, ctx) => {
      await copyLatestCode(ctx);
    },
  });
}
