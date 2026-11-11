---
name: pr-review
description: >-
  Interactive, grill-me-style PR workflow that steps through code or feedback one unit at a time. Auto-detects the right mode: (1) Fresh Co-Review of a PR file-by-file in topological order, (2) Delta Re-Review auditing prior comment resolutions + net-new commits, (3) Author Feedback Triage investigating incoming review comments on your PR one by one, or (4) Self-Review of your own PR. Use when the user asks to "review PR", "review pull request", "co-review", "re-review", "triage review", "address review comments", or mentions reviewing a PR/Linear ticket.
---

Pair-review a pull request or triage incoming review feedback with the user **one logical unit or thread at a time**, `grill-me` style.

**Core Interaction Rules:**

1. **Never dump a monolithic review wall-of-text.** Walk through the PR interactively, stopping after each unit or finding for the user's decision.
2. **Explore before speaking.** If a question or edge case can be verified by reading the full file, grepping callers, or checking tests, check the codebase first.
3. **`Alt+C` (`copy-code`) Determinism:** The user has `Alt+C` bound to copy the **last fenced code block** of your message. Whenever you propose a GitHub inline comment, suggestion, or thread reply, present **at most one finding per turn** and place the ready-to-paste markdown comment inside the **final fenced code block** (` ````markdown ... ```` `) of your message.
4. **Zero-Write Git & GitHub Invariant:** Never run `git checkout` or submit/stage reviews on GitHub. If the PR branch is not checked out locally, inspect via `gh pr diff`, `gh api`, and read-only git commands (`git show origin/<branch>:<path>`).

---

## Phase 1: Resolve PR, Context & Auto-Detect Mode

1. **Resolve Target PR & Viewer:**
   - Use the PR number/URL/branch from the prompt, or detect via `gh pr view`. If none is active on the current branch, list candidates via `gh pr list --author "@me" --limit 5` and `gh pr list --search "review-requested:@me" --limit 5` and ask the user to choose.
   - Fetch viewer login (`gh api user --jq .login`) and repo `owner/name`.

2. **Harvest PR State & Review Threads:**
   - Run `gh pr view <pr> --json number,title,body,author,baseRefName,headRefName,headRefOid,commits,statusCheckRollup,url`.
   - Extract any Linear ticket key (`[a-zA-Z]{2,}-\d+`) from branch, title, or body and fetch ticket requirements via the `linear` MCP `get_issue` tool (`includeRelations: true`). Degrade gracefully if absent.
   - Query reviews and review threads via GraphQL:
     ```bash
     gh api graphql -f query='
       query($owner:String!, $repo:String!, $pr:Int!) {
         repository(owner:$owner, name:$repo) {
           pullRequest(number:$pr) {
             reviews(last:30) {
               nodes { author { login } state submittedAt commit { oid } body }
             }
             reviewThreads(first:100) {
               nodes {
                 isResolved
                 isOutdated
                 path
                 line
                 comments(first:20) {
                   nodes { author { login } body createdAt commit { oid } }
                 }
               }
             }
           }
         }
       }' -f owner="<owner>" -f repo="<repo>" -F pr=<pr_number>
     ```

3. **Select Workflow Mode (4-Way Auto-Detection):**
   Unless the user explicitly requested a specific mode in their prompt:
   - **Mode 1 — Fresh Co-Review:** `@me != author` AND `@me` has no prior submitted review on this PR.
   - **Mode 2 — Delta Re-Review:** `@me != author` AND `@me` has at least one prior submitted review (anchor at `@me`'s latest review `commit.oid`).
   - **Mode 3 — Author Feedback Triage:** `@me == author` AND there is `>= 1` unresolved review thread (or actionable reviewer comment) from a teammate.
   - **Mode 1 (Self-Review Variant):** `@me == author` AND there are `0` unresolved review threads.

---

## Mode 1: Fresh Co-Review (and Self-Review)

Step through the PR together in dependency order. Maintain an in-memory **Approved Review Ledger** of comments the user decides to keep.

### Step 1: Orientation & Step 0 Boilerplate Sweep

In your first message:

1. **Briefing Header (3–4 lines):** State the PR's "Why" (Linear alignment), CI status, and the **Topological Walkthrough Plan** listing the numbered logical units you will step through:
   - Order units by dependency topology: **(1) Schemas / Types / Models → (2) Core Domain / Services → (3) Boundaries / Routers / UI / CLI → (4) Standalone Tests/Config**.
   - **Pair each implementation file with its corresponding test file** in the same logical unit (e.g., `Unit 2: src/pricer.py + tests/test_pricer.py`).
2. **Step 0 — Boilerplate Sweep:** Sweep all zero-logic changes (`__init__.py` exports, lockfiles, pure renames, formatting/config) into a 1-bullet summary so they never waste a dedicated turn.
3. **Immediately present Unit 1** (or ask to begin if Step 0 surfaced an issue).

### Step 2: The Unit-by-Unit Co-Review Loop

For the current Logical Unit (`[Unit k/N]`):

1. **Silent Grounded Audit (Before Responding):**
   - Read the full modified file(s) (or surrounding functions), not just the diff hunk.
   - Grep caller sites across the codebase for any changed signatures, return types, or error states.
   - Audit for correctness bugs, unhandled edge cases, race conditions, complected concerns (`simple-by-construction`), and test coverage gaps.
2. **Present the Unit:**
   - **Role & Change:** 1–3 sentences on what changed behaviorally in this unit and whether callers/tests are sound.
   - **If Clean:** State `Verdict: LGTM (callers & tests verified)` and ask: _"Questions on Unit k, or move to Unit k+1?"_
   - **If Findings Exist (One Finding at a Time):**
     - State how many findings exist in this unit (e.g., `Finding 1 of 2 in Unit k`).
     - Explain the issue concisely (`[BUG]`, `[EDGE CASE]`, `[DESIGN / COMPLECTING]`, or `[TEST GAP]`) and your recommended fix.
     - Place the exact location header (`📍 path/to/file:line`) followed by the ready-to-paste GitHub comment as the **final fenced code block** of your message:

       ````markdown
       <Concise explanation of the issue and why it matters>

       ```suggestion
       <exact replacement code if applicable>
       ```
       ````

     - Ask: _"Keep this comment (`Alt+C` to copy), tweak it, or skip?"_

3. **Advance:** When the user approves, tweaks, or skips the finding, record approved comments in the **Review Ledger** and present the next finding in the current unit (or advance to `Unit k+1`).

### Step 3: Final Review Ledger

Once the last unit is complete, output:

1. Clickable review link: `https://github.com/<owner>/<repo>/pull/<number>/files`
2. All approved comments from the session listed in order with their `path/to/file:line` coordinates.
3. A **final fenced code block** at the very bottom containing the concise **Top-Level Review Verdict Summary** (`Approve`, `Approve with minor notes`, or `Request changes`) so one last `Alt+C` copies the summary body.

---

## Mode 2: Delta Re-Review ("What Changed Since My Last Review?")

When you previously reviewed this PR at `<last_review_sha>`:

### Phase A: Prior Thread Resolution Audit

1. Identify all review threads where `@me` participated (plus any other unresolved threads if relevant).
2. Inspect the current code at each thread's file/line and the commits since `<last_review_sha>`.
3. Classify each prior comment:
   - `[RESOLVED CLEANLY]` — Fixed properly with no regressions.
   - `[PARTIAL / NEW ISSUE]` — Fix is incomplete or introduced a new edge case.
   - `[UNADDRESSED]` — Still open and untouched in code.
4. **Fast-Forward Clean Resolutions:** Summarize all `[RESOLVED CLEANLY]` threads in a single compact list at the start.
5. **Grill Remaining Threads One-by-One:** If any thread is `[PARTIAL / NEW ISSUE]` or `[UNADDRESSED]`, step through them one at a time with a recommended follow-up reply in the **final fenced code block** (`Alt+C` ready).

### Phase B: Net-New Delta Walkthrough (`<last_review_sha>..HEAD`)

1. Isolate changes introduced after your last review:
   - Inspect commits and diff between `<last_review_sha>` and `<headRefOid>` (via `git diff <last_review_sha>..<headRefOid>` or `gh api repos/{owner}/{repo}/compare/<last_review_sha>...<headRefOid>`).
2. If zero net-new logic changes exist outside the audited threads, skip straight to the **Final Review Ledger** and overall verdict.
3. Otherwise, group the newly modified files into **Topological Units** and run the **Mode 1 Unit-by-Unit Co-Review Loop** strictly on the `<last_review_sha>..HEAD` delta.

---

## Mode 3: Author Feedback Triage ("Grill Incoming Reviews on My PR")

When `@me` authored the PR and reviewers left comments/threads:

### Step 1: Overview of Incoming Feedback

Emit a brief header listing the total number of unresolved threads/comments and who reviewed the PR, then immediately present **Thread 1 of M**.

### Step 2: One-Thread-at-a-Time Investigation & Triage Loop

For the current unresolved thread (`[Thread k/M]`):

1. **Silent Grounded Investigation (Before Responding):**
   - Read the target file, surrounding logic, upstream/downstream callers, and tests.
   - Determine whether the reviewer's claim holds up against the actual codebase.
2. **Present the Triage Card:**
   - **Reviewer & Location:** `@<reviewer>` on `path/to/file:line`
   - **Their Comment:** Quoted concisely.
   - **Grounded Assessment:** Classify as one of:
     - `[VALID — FIX]` (Reviewer caught a real bug, edge case, or cleaner structure)
     - `[NUANCE / TRADEOFF]` (Reviewer has a valid point, but there is a concrete tradeoff to weigh)
     - `[INVALID / PUSHBACK]` (Codebase already guarantees this invariant or reviewer misread the flow — cite exact file/line proof)
   - **Recommendation:**
     - If recommending a **code fix**: state the exact surgical change to make and ask: _"Queue this fix, handle differently, or push back?"_
     - If recommending a **reply / pushback** (or when the user asks for a reply): place the ready-to-paste GitHub reply in the **final fenced code block** (`Alt+C` ready).

### Step 3: Post-Triage Execution Handoff

Once all threads have been triaged with the user, output a consolidated **Triage Action Plan**:

1. **Queued Code Fixes:** Numbered list of agreed file modifications + verification commands (pytest / ruff / shellcheck). Ask the user if they want to execute the fixes now (or invoke `craft-plan` if complex).
2. **Replies to Post:** Summary of any pushback/clarification replies decided during triage.
