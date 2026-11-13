---
name: pr-description
description: >-
  Write or refresh a Pull Request title and description from uncommitted edits, local or pushed branches, or an existing PR. Use when asked to draft, write, or update a PR description/body, summarize changes for a PR, or run pr-description.
---

Draft or refresh a Pull Request title and description that orients a reviewer in under 30 seconds.

## Invariants & Gotchas

1. **Complement the Diff:** Reviewers already see `Files changed`. Write only what the diff cannot show on its own: _why_ this change exists now, the core design or behavioral mechanism, non-obvious tradeoffs, and rollout risk. Cut any sentence a reviewer could learn by skimming file names or obvious hunks.
2. **Read-Only by Default:** Never run `git add`, `git commit`, `git push`, `git checkout`, `gh pr create`, or `gh pr edit` unless the user explicitly asks to create or update the PR on GitHub (if explicitly asked, pass `--body-file` to avoid backtick escaping bugs, and default new PRs to `--draft` unless told the work is complete).
3. **`Alt+C` (`copy-code`) Fence Safety:** `Alt+C` extracts the **last** fenced block via `/```(?:\w+)?\n([\s\S]*?)```/g`:
   - Render the **PR Title** _above_ the fence (never in a trailing code block) and place the full PR body inside the **final ` ```markdown ... ``` ` block**.
   - Never nest triple-backtick (` ``` `) fences inside that ` ```markdown ` block—doing so prematurely closes the regex and truncates the clipboard. Format any internal call tree, diff sketch, or command snippet with **4-space indentation** (valid GitHub Markdown code block) or inline `` `code` ``.

---

## Workflow

### 1. Capture Net State (Zero-Write)

1. **Check PR, Base & Conventions:**
   - If given a PR `#number`, URL, or remote branch, inspect via `gh pr view <target> --json number,title,body,state,baseRefName,headRefName,url`. Otherwise check the current branch (`gh pr view ... 2>/dev/null`) and `git status --short`.
   - Resolve `<base>` if no PR exists: remote default (`git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null`, e.g. `origin/main`), stacked parent branch if branched off an active feature ref, or local `main`/`master`.
   - Check `git log -n 8 --oneline` for the repo's title style (`<Verb> <what>` vs. Conventional Commits `feat(scope): <what>`) and check for `.github/pull_request_template.md` (or `.github/PULL_REQUEST_TEMPLATE/`).
2. **Extract the True Net Diff:**
   - **Local workspace (committed, staged, unstaged, or mixed):** Diff merge-base directly against the working tree so committed and uncommitted edits unify in one view, then read any untracked source/test files:
     ```bash
     git diff "$(git merge-base <base> HEAD)" --stat
     git diff "$(git merge-base <base> HEAD)"
     git ls-files --others --exclude-standard
     ```
     _Scope guard:_ If `git status --short` mixes unrelated local scratch/config edits with the feature (or the user asked for staged changes only), scope to `git diff --cached` or ask which files belong in the PR.
   - **Remote / unchecked-out target:** Inspect via `gh pr diff <target>` or `git diff <base>...origin/<branch>` without switching branches.
   - **Existing PR refresh:** Read the existing `title` and `body`, preserve valid ticket links and human-authored checklists, drop incremental changelog sediment ("also added", "updated after review"), and describe the **current full net state** as if written fresh.

### 2. Reconstruct Intent, Blast Radius & Missing Facts

1. **Read Beyond Hunks:** When hunks leave behavioral impact unclear, read surrounding functions and grep callers for changed signatures, schemas, or error contracts. Note one-way doors (migrations, public contract changes, state mutations).
2. **Source _The Why_ (Priority Order):**
   - **Session history first:** If the change was planned, debugged, or built in this conversation, mine prior turns for the real motivation, rejected alternatives, and exact verification commands actually run.
   - **Linear MCP second:** Scan prompt, branch, commits, and PR metadata for `[a-zA-Z]{2,}-\d+` keys (e.g. `ML-849`). Fetch `get_issue` (`includeRelations: true`) for problem context, acceptance criteria, and blocking/stacked issue relations. Degrade silently if absent or unreachable.
   - **Git history third:** Check `git log <base>..HEAD` for commit rationale.
3. **Ambiguity Gate (Fast-Path Default):**
   - When _The Why_ is clear, emit the finished PR title and description immediately in **one turn**—no boilerplate questionnaires.
   - Pause with **at most one compact question** _only_ if motivation cannot be grounded from session/Linear/git (never invent a plausible _Why_) or if high-risk rollout/migration tradeoffs require human confirmation.

### 3. Scale Proportionally to Size & Archetype

Measure net logic lines changed (ignoring lockfiles, snapshots, renames, generated files) **before drafting**.

**Size gates the _How_, never a non-obvious _Why_.** A 2-line race-condition fix earns a full root-cause paragraph; a 40-line mechanical config change earns two sentences total. If the repo has a PR template, satisfy its required sections concisely at the matching depth; otherwise scale structure by tier:

| Tier       | Net Logic Lines         | Structure & Depth                                                                                                                                                                                                             |
| :--------- | :---------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Micro**  | `< 50` (1 concern)      | 1–4 sentences of plain prose (`Why` + 1-sentence `How` + ticket ref). Zero headings, zero fluff.                                                                                                                              |
| **Small**  | `50–250`                | Tight `Why` + concise `How` (short paragraph or 2–3 mechanism bullets) + ticket ref. Bold lead-ins at most; avoid `##` headings.                                                                                              |
| **Medium** | `250–800`               | `Why` + `How` + only earned supporting sections (`Verification`, `Rollout & Risk`, or `Reviewer Focus`).                                                                                                                      |
| **Large**  | `> 800` or multi-domain | Up to 4 `##` sections (`Why`, `Architecture / How`, `Verification & Rollout`, `Reviewer Focus` / `Follow-ups`). Add a compact 4-space indented call/state/data-flow sketch only when it clarifies topology faster than prose. |

Adapt emphasis to the change archetype:

- **Bugfix:** User/system symptom → root cause (if non-obvious from diff) → invariant restored.
- **Feature:** Capability unlocked and why now → core boundary/design choice → deliberate out-of-scope follow-ups.
- **Refactor:** Structural friction or coupling removed → behavioral equivalence (or intentional contract shift).
- **Infra / Data / Schema:** Operational driver → **one-way vs. two-way door** (migration order, backfill, rollback safety).

### 4. Prose & Evidence Standards

- **Title:** Match the repo's convention (`<Verb> <what> [in/for <context>]` or `type(scope): <what>`). Name the behavioral change, not the file (`Exclude .worktrees from Telescope searches`, not `Update telescope.lua`).
- **Problem-First Openers:** Open directly with the problem, broken invariant, or component (`"Secondary checkouts under .worktrees/ polluted Telescope..."`). Avoid meta-openers (`"This PR..."`, `"This change..."`, `"In this pull request..."`).
- **Mechanism Over Inventory:** Describe the design across boundaries, naming at most 2–3 key symbols. Omit per-file tours (`In foo.py...`) and commit-by-commit chronology.
- **Concrete Specificity Over Slop:** Anchor claims in exact symbols, error types, thresholds, or measured numbers (`p50 45ms → 3ms`, `catch ServiceUnavailable`). Strip empty intensifiers (`comprehensive`, `robust`, `seamless`, `significantly`, `holistic`, `crucial`, `streamlined`, `leverages`).
- **Honest Verification:** Cite test runs, queries, or benchmarks **only** when executed in this session or confirmed by the user. Omit verification rather than listing hypothetical commands.
- **Durable Context & Linear Semantics:** Inline enough context that `git log` stands alone in 6 months. Use `Fixes TEAM-123` / `Resolves TEAM-123` **only** when merging completes the issue; use `Part of TEAM-123` (or `Ref TEAM-123`) for partial/stacked steps so Linear does not prematurely auto-close active issues. Include the Linear URL when known.

---

## Output Format

Verify every sentence passes the Complement-the-Diff test and contains zero nested ` ``` ` fences inside the final block, then output with no conversational preamble:

**Title:** `<Suggested PR Title>`
**Scope:** `<state summary vs base>` (`+<add> / -<del>`, `<N>` files) · `<Micro / Small / Medium / Large>`

```markdown
<Ready-to-paste PR description>
```
