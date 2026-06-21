---
name: linear-pr-review
description: Perform a comprehensive code and PR review. Cross-references changes on the branch against the direct parent branch, the corresponding GitHub PR description, and the associated Linear issue (if any). Use when the user asks to "review PR", "review pull request", or mentions a Linear ticket.
---

Perform a comprehensive code and PR review of a branch. This skill goes beyond isolated diff patches to actively investigate intent, understand architecture, map system impact, trace execution flows, and deliver a rigorous Principal-level review.

## Steps to Execute:

1. **Resolve the Target PR:**
   - Check if a PR number, URL, or branch name was directly provided in the user's prompt.
   - If not, check if the current branch has an open PR by running `gh pr view`.
   - If multiple candidates exist or no PR is active on the current branch, run `gh pr list --author @me` and `gh pr list --search "review-requested:@me"` to find relevant open PRs. Present these to the user as an interactive choice and ask them to choose or specify.

2. **Extract Linear Ticket Key (Heuristic search):**
   - Check the **branch name** (e.g. `ml-849` -> `ML-849`).
   - Check the **PR title** (e.g. `[ML-849] Align...` -> `ML-849`).
   - Check the **PR body** and **PR comments** (run `gh pr view --comments` to find references or comments posted by the Linear bot).
   - Look for keys matching the format `[a-zA-Z]{2,}-\d+` (e.g. `ML-849`).

3. **Fetch Context & Verify Intent ("The Why"):**
   - If a Linear ticket key is successfully identified, use the `linear` MCP server tools (e.g. `get_issue` or `search_issues`) to retrieve the issue's description, objectives, and acceptance criteria.
   - Read the GitHub PR summary and comments to understand the background, context, or constraints (e.g., server-side schema constraints or upstream bugs).
   - Define clearly in your own mind: **What is the core problem being solved, and what are the constraints?**

4. **Isolate Changes & Extract the Diff:**
   - Retrieve the base branch of the PR using `gh pr view --json baseRefName --jq .baseRefName`.
   - Run a **three-dot diff** against this base branch to isolate only the changes introduced on this specific branch:
     ```bash
     git diff <base_branch>...HEAD
     ```

5. **Deep Code Comprehension & Impact Analysis ("The What"):**
   - **Full-File Reading:** Do not rely on raw diff chunks. For any file containing substantial logic edits, read the surrounding code (or the entire file) using the file-reading tools to fully grasp the state machine, imports, and local context.
   - **Reference Audit (Impact Analysis):** For any modified, added, or renamed methods, interfaces, or classes, use the grep search tool to scan the rest of the codebase. Verify that no references or caller sites are broken by the signature/structural changes.
   - **Trace Dynamic Payloads:** Mentally trace a dry-run payload through the modified code paths. (e.g., Simulate an error state, a missing field, or an "Unsure" fallback value. Ensure it does not trigger silent failures, unhandled exceptions, or dynamic typing issues down the line).

6. **Audit Test Quality & Engineering Conventions:**
   - Locate the test files covering the modified code.
   - Read these tests and evaluate:
     - Do they cover actual logical boundary conditions and edge cases?
     - Are they asserting exact expected values rather than using overly broad or trivial mocks?
     - Do they follow local testing patterns (e.g., `pytest`, `pytest-asyncio`, utilizing shared fixtures)?

7. **Generate & Present the Review:**
   - Produce a structured markdown review containing:
     - **Summary of Intent & Changes:** Clear, high-level summary of the problem, why these specific changes were made, and how they solve it.
     - **Requirements & Alignment Check:** Rigorous assessment against the GitHub description and Linear criteria. Explicitly call out any gaps, omissions, or partial implementations.
     - **Downstream Impact & Safety Check:** Confirm whether reference analysis and dynamic dry-runs surfaced any risks, regressions, or caller breakages.
     - **Code Quality, Logic, & Conventions Feedback:** Constructive feedback detailing files and lines, indicating where code can be simplified, made more performant, or more compliant with local styling.
     - **Testing Integrity:** Critique of test coverage and assertions.
     - **Conclusion & Recommendation:** Clear, actionable verdict (e.g., Approve, Approve with minor notes, or Request changes).
