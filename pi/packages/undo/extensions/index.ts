import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function(pi: ExtensionAPI) {
	pi.registerCommand("undo", {
		description: "Rewind conversation by N user turns without losing files",
		handler: async (args, ctx) => {
			// 1. Handle active streaming / pending messages safely
			if (!ctx.isIdle()) {
				ctx.abort();
				await ctx.waitForIdle();
			}

			// 2. Parse optional step argument
			const steps = Math.max(1, parseInt(args.trim() || "1", 10) || 1);
			const branch = ctx.sessionManager.getBranch();

			// 3. Find user message entries in the active branch
			const userEntries = branch.filter(
				(entry) => entry.type === "message" && entry.message.role === "user",
			);

			if (userEntries.length === 0) {
				ctx.ui.notify("No user messages to undo", "warning");
				return;
			}

			const targetIndex = userEntries.length - steps;
			if (targetIndex < 0) {
				ctx.ui.notify(
					`Cannot undo ${steps} turn(s); session only has ${userEntries.length} user turn(s)`,
					"warning",
				);
				return;
			}

			const targetUserEntry = userEntries[targetIndex];
			// Destination is the entry immediately preceding the target user question
			const destinationId = targetUserEntry.parentId;

			if (!destinationId) {
				ctx.ui.notify("Cannot undo past session root", "warning");
				return;
			}

			// 4. Extract prompt text to restore into editor
			let promptText = "";
			const content = targetUserEntry.message.content;
			if (typeof content === "string") {
				promptText = content;
			} else if (Array.isArray(content)) {
				promptText = content
					.filter((c: any) => c.type === "text")
					.map((c: any) => c.text)
					.join("\n");
			}

			// 5. Navigate tree non-destructively without branch summarization
			const result = await ctx.navigateTree(destinationId, {
				summarize: false,
			});
			if (!result.cancelled) {
				if (promptText) {
					ctx.ui.setEditorText(promptText);
				}
				ctx.ui.notify(
					`Undid ${steps} turn(s); prompt restored to editor`,
					"info",
				);
			}
		},
	});
}
