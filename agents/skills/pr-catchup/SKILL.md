---
name: pr-catchup
description: Build a fast, comprehensive read-only state briefing of any pull request (yours or a teammate's, unreviewed or mid-flight). Synthesizes Linear intent, diff topology, CI health, review timeline, commits since last review, and unresolved vs. resolved review threads. Use when the user asks to "catch up on PR", "PR status", "brief me on PR", "what is the state of this PR", or "pr-catchup".
---

Deliver a high-density, read-only situational briefing of a pull request so the user understands its exact intent, architecture, review history, and current blockers in under 30 seconds.

**Core Invariant:** This skill is strictly read-only. Never run `git checkout` or mutate git/GitHub state. Do not enter a multi-turn file-by-file review here—give the complete radar snapshot in one turn and end with the recommended next action.

---

## Execution Steps

### 1. Resolve Target PR & Viewer Identity

1. If a PR number, URL, or branch was passed in the prompt, target that PR.
2. Otherwise, check the current branch via `gh pr view --json number,url`.
3. If no PR is attached to the current branch, list active candidates via `gh pr list --author "@me" --limit 5` and `gh pr list --search "review-requested:@me" --limit 5`, present them as a numbered choice, and wait for the user to pick.
4. Resolve viewer identity and repo coordinates:
   ```bash
   gh api user --jq .login
   gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
   ```

### 2. Single-Pass Context & Thread Harvest

Fetch PR state, commits, checks, reviews, and thread resolution status in parallel:

1. **PR Metadata, Commits & Checks:**
   ```bash
   gh pr view <pr> --json number,title,body,state,isDraft,author,baseRefName,headRefName,headRefOid,additions,deletions,changedFiles,commits,statusCheckRollup,reviewDecision,url
   ```
2. **Review Threads & Resolution State (GraphQL):**
   ```bash
   gh api graphql -f query='
     query($owner:String!, $repo:String!, $pr:Int!) {
       repository(owner:$owner, name:$repo) {
         pullRequest(number:$pr) {
           reviews(last:20) {
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
3. **Linear Ticket Context ("The Why"):**
   - Scan `headRefName`, `title`, and `body` for a Linear key matching `[a-zA-Z]{2,}-\d+` (e.g. `ML-849`).
   - If found, call the `linear` MCP `get_issue` tool (`includeRelations: true`) to fetch objectives, acceptance criteria, and blocking relations. Degrade gracefully if no ticket exists or MCP is unavailable.
4. **Diff Topology:**
   - Inspect changed file stats via `gh pr diff <pr> --name-only` (or `git diff --stat origin/<baseRefName>...origin/<headRefName>` if fetched locally) and read key hunks as needed to summarize the behavioral change accurately.

### 3. Temporal & Delta Calculation

Compute where the PR stands in time:

- Identify the latest non-pending review (overall and specifically by `@me` if `@me != author`).
- Compare the review's `commit.oid` against `commits` on the PR to determine **how many commits were pushed after the last review** (and what those post-review commits changed).
- Partition `reviewThreads` into **Unresolved** (`isResolved == false`) and **Resolved** (`isResolved == true`).

---

## Output Format

Emit a clean, high-density briefing using this structure:

```markdown
# PR #<number>: <Title>

**Author:** `@<author>` | **Role:** <Author / Reviewer> | **State:** <OPEN/DRAFT> | **Review:** `<reviewDecision or PENDING>` | **CI:** <PASSING / FAILING (name failing checks) / PENDING>
**Branch:** `<headRefName>` → `<baseRefName>` (`+<additions> / -<deletions>` across `<N>` files)
**Links:** [GitHub PR](url) | [Linear <KEY>](linear_url_if_any)

### 1. Intent & Behavioral Summary

- **The Why:** <1-2 sentences synthesizing the Linear ticket goal and problem solved>
- **What Changed:** <2-3 sentences explaining the core mechanism/architectural change—not a file list>
- **Alignment Check:** <Confirm whether the diff fulfills Linear acceptance criteria, noting any visible gaps>

### 2. Diff Topology

- **Schemas / Types / Models:** `<files or "None">`
- **Core Logic / Services:** `<files>`
- **Boundaries (Routers / CLI / UI):** `<files or "None">`
- **Tests & Config:** `<files or "None">`

### 3. Review Timeline & Post-Review Activity

- **Reviews Submitted:** <e.g., `@alice` requested changes at `a1b2c3d` (3 commits ago); `@you` have not reviewed yet>
- **Post-Review Delta:** <If commits landed after the last review, summarize what those commits changed in 1-2 bullets; otherwise "No new commits since last review.">

### 4. Open Threads & Blockers (<unresolved_count> Unresolved / <resolved_count> Resolved)

- **`path/to/file:line`** (`@<reviewer>`): <1-line summary of the concern and whether a fix landed in a later commit>
- _(If 0 unresolved threads: "None — all review threads resolved.")_

---

**Recommended Next Move:** <1 sentence tailored to state — e.g.:

- "You haven't reviewed this PR yet. Run `pr-review` to start a file-by-file Co-Review."
- "<N> commits landed since your last review. Run `pr-review` to audit your <M> prior threads and walk the delta."
- "Your PR has <N> unresolved comments. Run `pr-review` to investigate and triage them one by one.">
```
