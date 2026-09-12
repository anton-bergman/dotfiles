---
name: linear-pr-description
description: Generate a concise, high-quality, and structured pull request description for the current branch against its parent/base branch. Cross-references changes on the branch against the associated Linear issue (if any) using the Linear MCP server. Use when the user asks to "write PR description", "generate PR", or requests a description of current branch changes.
---

Generate a Pull Request (PR) description for the current branch.

**Core principle: describe the decision, not the diff.** The reviewer can already read the diff; they cannot read the reasoning behind it. Write only what the diff cannot show — why the change exists, which tradeoffs were accepted, what is uncertain, and what depends on it. Length scales with the size of the change and never exceeds the budget for its tier.

## Steps to Execute:

1. **Identify the Base/Parent Branch:**
   - Detect the base branch dynamically:
     1. Check if the current branch already has a remote PR using `gh pr view --json baseRefName --jq .baseRefName`.
     2. If not found, check the default remote branch using `git symbolic-ref refs/remotes/origin/HEAD` or tracking of `main`/`master`/`develop`.
     3. Fall back to local presence of `main` or `master`. If ambiguous, ask the user.

2. **Extract Linear Ticket Key (Tiered Heuristic Search):**
   - Check the following sources in order of priority:
     1. **Branch Name:** Parse for `[a-zA-Z]{2,}-\d+` (e.g. `ml-123` -> `ML-123`).
     2. **Commit History:** Scan the last 5 commit messages on the current branch (`git log <base_branch>..HEAD`) for ticket patterns.
     3. **Fallback:** If multiple keys are found, prompt the user to clarify; if none are found, proceed with degradation.

3. **Fetch Context & Handle Graceful Degradation:**
   - If a Linear ticket is identified, use the `linear` MCP `get_issue` tool with `includeRelations: true` to retrieve the title, description, objectives, and any blocking/blocked-by relations that imply a merge order.
   - If no ticket is found or the Linear MCP is unreachable, degrade gracefully: generate from the git diff/commits alone and omit the Linear reference rather than inventing one.

4. **Isolate, Measure, and Analyze the Diff:**
   - Run a three-dot diff against the resolved base branch to capture only the changes on this branch:
     ```bash
     git diff <base_branch>...HEAD
     ```
   - Measure size to select the budget tier in Step 5:
     ```bash
     git diff --shortstat <base_branch>...HEAD
     ```
   - Read the diff for **behavioural change**, not to build a file inventory.

5. **Select the Length Budget by Diff Size:**

   | Tier    | Changed lines               | Prose budget | Allowed formatting                                           |
   | ------- | --------------------------- | ------------ | ------------------------------------------------------------ |
   | Trivial | < 50                        | 400 chars    | 1-3 sentences of plain prose. No headings, no bullets.       |
   | Small   | 50-300                      | 700 chars    | Prose + max 3 bullets. No headings.                          |
   | Medium  | 300-1000                    | 1200 chars   | Prose + bullets + max 3 `**bold labels**`. No `##` headings. |
   | Large   | > 1000 lines, or > 30 files | 2500 chars   | Max 4 `##` headings.                                         |
   - Budgets count **prose only**. Fenced code blocks and URLs are excluded — but they must be _evidence_ (real API response, actual error output, measured before/after numbers), never illustrative filler.
   - Never silently exceed a tier. Exceeding the Large budget requires explicit user approval.

6. **Write the Content:**
   - **Always include:**
     - **Why:** One or two sentences of context placing the change in the wider effort ("As part of X, this is the first step…", "We need Y because Z"). This is the highest-value sentence in the description — never omit it.
     - **What changed behaviourally:** Describe the change in behaviour or mechanism once, at the level a reviewer needs to orient. Name at most the 2-3 primary modules or symbols involved.
     - **Linear reference:** `Resolves ML-123` with the full URL, when a ticket was found.
   - **Include only when warranted:**
     - **Problem / root cause:** Only when the causal chain is _not_ evident from the diff (e.g. dead ReLUs driving BatchNorm `running_var` to zero; a collision caused by sort order). If the diff makes the cause obvious, omit it. Speculative or exploratory root-cause analysis belongs in the Linear ticket — link to it instead of reproducing it.
     - **Verification**, **tradeoffs / open questions**, and **sequencing**: only with content confirmed in Step 7.
   - **Never:**
     - **Never enumerate files.** No `### Deleted (13 files)` inventories, no per-file bullet lists, no restating what the diff already renders. This is the most common failure mode.
     - **Never fabricate verification.** Do not list commands that _could_ be run (`ruff`, `pytest`) as though they were run.
     - **Never make an unmeasured claim.** No asserted throughput, latency, or quality improvement without a number or a named mechanism.
     - **Never invent uncertainties, concerns, or impact.**
     - **Never apply a fixed template.** Emit only the sections this specific change needs.
   - **Banned vocabulary:**
     - **Always delete:** significantly, comprehensive, robust, seamless, holistic, premium, crucial, culmination, high-density, best practices, state-of-the-art, "This pull request".
     - **Only with a number or named mechanism attached:** optimize(d), ensures/ensuring, improves, faster, more efficient, reduces, unified, streamlined, leverages.
   - **Voice:** Active, first-person plural where natural ("We now insert…", "This PR splits…"). Not impersonal report-speak.

7. **Source the Facts You Cannot Infer:**
   - Scan the diff for candidate tradeoffs and risks: added `TODO`/`FIXME`/`HACK`, commented-out code, broad `except Exception`, `# type: ignore` / `as any`, hardcoded values, disabled feature flags, and new logic with no corresponding test changes.
   - Then ask the user **one batched question** (any part may be answered "none"):
     1. How did you verify this — what did you actually run or observe, and how confident are you?
     2. Any tradeoffs you knowingly accepted, or anything you want the reviewer to scrutinise? (Offer the candidates found above.)
     3. Anything sequenced behind this — dependent PRs, other repos, follow-up work?
   - Include only what the user confirms, plus what the diff and Linear relations prove. If a section has no confirmed content, omit the section entirely.

8. **Self-Check, Then Output:**
   - Before rendering, verify:
     - [ ] Prose is within the tier's character budget.
     - [ ] Formatting does not exceed what the tier allows.
     - [ ] No file inventory and no per-file bullets.
     - [ ] No always-delete words; every conditional word carries a number or mechanism.
     - [ ] Every claim traces to the diff, the Linear ticket, or the user's answers.
     - [ ] A "Why" sentence is present.
     - [ ] Nothing merely restates the title or the diff.
   - If over budget, cut in this order: module/file enumeration, then restated diff mechanics, then adjectives.
   - Render the finished markdown directly, with no conversational preamble.
