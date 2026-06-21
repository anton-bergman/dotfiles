---
name: linear-pr-description
description: Generate a concise, high-quality, and structured pull request description for the current branch against its parent/base branch. Cross-references changes on the branch against the associated Linear issue (if any) using the Linear MCP server. Use when the user asks to "write PR description", "generate PR", or requests a description of current branch changes.
---

Generate a premium, clear, and structured Pull Request (PR) description for the current branch. The description must align perfectly with the size and impact of the changes, be completely free of unnecessary filler words, and remain highly readable for reviewers.

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
   - If a Linear ticket is identified, use the `linear` MCP server `get_issue` tool to retrieve the issue's title, description, and key objectives.
   - If no ticket is found or the Linear MCP is unreachable, degrade gracefully: generate the description based solely on the git diff/commits and replace the Linear reference with a placeholder.

4. **Isolate and Analyze the Diff:**
   - Run a three-dot diff against the resolved base branch to capture only the changes on this branch:
     ```bash
     git diff <base_branch>...HEAD
     ```
   - Analyze files modified, added, and deleted.

5. **Generate an Adaptive PR Description:**
   - Match the description's complexity to the scale of the diff:
     - **Small Diff (< 50 lines / 1-2 files):** Output an ultra-compact summary (1-2 sentences for the "Why", 1-2 bullets for the "What", 1 line for verification).
     - **Medium/Large Diff:** Output a complete, high-density template:
       - **Overview / Intent:** Explanation of "Why" (incorporating Linear context if available).
       - **Changes Introduced:** Categorized bullets (e.g., `Features`, `Refactoring`, `Tests`, `Configuration`). Only show categories that have changes.
       - **Testing & Verification:** Contextually infer exact commands based on changed files (e.g., if python files changed, suggest running `ruff`; if tests were touched, list those specific test suites).
       - **Linear Ticket Link:** Reference the ticket (e.g., `Resolves ML-123`).

6. **Output:**
   - Render the finished markdown directly without conversational filler.
