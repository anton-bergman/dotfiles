---
name: stage-pr-review
description: Conduct a comprehensive code review cross-referencing Linear tickets, PR descriptions, and the entire codebase, then stage findings as private draft comments on GitHub. Never submits or publishes the review—leaves all final review control to the user. Use when user asks to "stage review", "stage PR review", "review PR as draft", or mentions staging review comments.
---

Perform a comprehensive code review of a pull request and stage all inline feedback as **private draft comments** on GitHub.

The agent acts as an autonomous Staff/Principal reviewer, investigating the "Why" (Linear + PR description), auditing the "What" (full-file reading, caller references, test coverage), and staging comments into a **PENDING review** on GitHub.

**CRITICAL INVARIANT:** You MUST NEVER submit or publish the review. You must NEVER run `gh pr review --approve`, `gh pr review --comment`, `gh pr review --request-changes`, or call any submit mutation. Your ONLY action is staging draft comments via `gh_draft_review.py`. The human user reviews your drafts and submits the review.

---

## Execution Workflow

### 1. Resolve the Target PR

- Check if a PR number, URL, or branch name was provided in the prompt.
- If not provided, check the current branch's open PR via `gh pr view --json number,baseRefName,headRefOid,url`.
- If multiple candidates exist or no branch PR is open, list candidate PRs using `gh pr list --limit 10` and prompt the user to choose.

### 2. Ingest Existing Drafts & Context

1. **Check Existing Draft Reviews:**
   - Run `python3 "$HOME/dotfiles/scripts/python/gh_draft_review.py" status <pr_number>`.
   - If `has_pending` is true, read the existing comments and IDs into context.
   - When re-running a review, you will reconcile against these existing drafts rather than starting from scratch.

2. **Extract Linear Ticket Key:**
   - Scan branch name, PR title, and PR body for ticket patterns matching `[a-zA-Z]{2,}-\d+` (e.g. `ENG-123`, `ML-849`).
   - If found, call the `linear` MCP server tools (`get_issue`) to fetch the ticket description, requirements, and acceptance criteria.
   - If no Linear ticket is found or Linear MCP is unavailable, proceed gracefully using the PR description as the source of truth.

3. **Read PR Metadata:**
   - Run `gh pr view <pr> --json title,body,comments` to understand background context, trade-offs, and implementation rationale described by the author.

### 3. Deep Codebase Audit ("The What & The Blast Radius")

1. **Isolate Changes:**
   - Resolve base branch (e.g. `origin/main` or PR base ref).
   - Inspect 3-dot diff: `git diff <base_branch>...HEAD` (or `gh pr diff <pr_number>`).
2. **Full-File Reading:**
   - Do not rely solely on diff chunks. For any file with substantial logic modifications, read the entire file (or surrounding functions) using file-reading tools to understand local state machines, error paths, and invariants.
3. **Reference & Caller Audit (Impact Analysis):**
   - For modified, renamed, or deleted functions, types, schemas, or interfaces, use `grep` across the entire codebase.
   - Verify that all caller sites handle new return types, altered signatures, or newly introduced error states.
4. **Test Suite Integrity:**
   - Inspect test files covering the changed paths.
   - Verify boundary conditions, error handling, mock fidelity, and realistic assertions.

### 4. Synthesize & Reconcile Review Findings

Focus strictly on high-signal feedback:

- Correctness bugs, race conditions, edge-case crashes, memory/resource leaks.
- Architectural regressions, leaky abstractions, or contract violations with existing callers.
- Unhandled downstream caller impact.
- Concrete test gaps.

#### Re-evaluation Rules when Drafts Already Exist:

- **Keep (Default):** If an existing draft accurately points out a valid issue, leave it alone. Do not add it to the payload.
- **Update:** If an existing draft can be significantly improved (clearer reasoning, better ` ```suggestion ```` block), include it in `"update"`with its`id`.
- **Remove (High Confidence Threshold):**
  - _Hard Rule:_ ONLY mark an existing comment for removal if you have **irrefutable evidence** that the issue does not exist or has already been fixed in code.
  - _Fallback:_ If there is any ambiguity or doubt, **leave the comment** and let the human reviewer decide.
- **Add:** Stage newly discovered bugs in `"add"`. (Duplicate additions on the same line are automatically skipped).

#### Comment Coordinate Schema:

- Single-line comment: `line` and `side` (`"RIGHT"` or `"LEFT"`).
- Multi-line comment (pure addition or deletion): `startLine`, `line`, and `side` (`"RIGHT"` or `"LEFT"`).
- Cross-side replacement comment: when deleted code was replaced by new code in the same hunk, span across them using `startSide: "LEFT"`, `startLine: <old_line>`, `side: "RIGHT"`, `line: <new_line>`.

### 5. Stage Draft Comments via CLI

Format findings into a reconciliation delta JSON object and pipe into `gh_draft_review.py`:

````bash
python3 "$HOME/dotfiles/scripts/python/gh_draft_review.py" stage <pr_number> --stdin << 'EOF'
{
  "add": [
    {
      "filePath": "src/services/auth.ts",
      "startLine": 40,
      "line": 45,
      "side": "RIGHT",
      "comment": "Refactor nested callback to use async/await with mutex locking to avoid race condition:\n\n```suggestion\nconst token = await this.mutex.runExclusive(async () => {\n  return await this.refreshToken();\n});\n```"
    },
    {
      "filePath": "src/api/client.ts",
      "startSide": "LEFT",
      "startLine": 20,
      "side": "RIGHT",
      "line": 24,
      "comment": "Replacement of HTTP client removes default retry configuration. Ensure retry policy is preserved."
    }
  ],
  "update": [
    {
      "id": 4006047702,
      "comment": "Refined: consider verifying null check on user profile before destructuring."
    }
  ],
  "remove": [
    {
      "id": 4006049571,
      "reason": "Verified that commit a1b2c3d already added the required timeout parameter."
    }
  ]
}
EOF
````

_Note on Option A Routing:_

- Lines inside active diff hunks are placed as inline review comments.
- Observations on unchanged callers or outside diff hunks are automatically routed into the Pending Review's top-level summary body.

### 6. Deliver Terminal Report

Output a clean, high-density summary to the user:

```markdown
✓ Staged <N> draft review comments on PR #<pr_number> (All Private & Pending):

- `path/to/file:line` [Severity]: Short summary of finding.
- ...

👉 Review and submit your drafts here: https://github.com/<owner>/<repo>/pull/<pr*number>/files
*(Drafts are private to you. No notifications have been sent. Submit or edit directly in GitHub.)\_
```
