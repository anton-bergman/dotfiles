---
description: "Review a PR against its Linear ticket, PR description, and full codebase, then stage draft inline comments on GitHub. Never submits or publishes the review. Usage: /stage-review [pr_number]"
---

# stage-review

Audit the pull request and stage private draft review comments on GitHub using the `stage-pr-review` skill.

**CRITICAL INVARIANT:** You MUST NEVER submit the review or publish comments. Do NOT run `gh pr review --approve`, `--comment`, `--request-changes`, or call any submit mutation. Your ONLY action is staging draft comments via `gh_draft_review.py`. The human user reviews your drafts and submits the review.

## Steps to Execute:

1. **Resolve Target PR:**
   - If a PR number or URL is given in the prompt, use it.
   - Otherwise, detect the current branch's PR via `gh pr view --json number,url,headRefOid`.
   - If not in a PR branch, ask the user which PR to review.

2. **Load & Execute the `stage-pr-review` Skill:**
   - Read Linear ticket details (via `linear` MCP if a ticket pattern is present in branch/title/body).
   - Read PR title, description, and author notes via `gh pr view`.
   - Compute 3-dot diff (`git diff <base>...HEAD`) and grep caller sites across the codebase.
   - Synthesize findings into structured JSON.

3. **Stage Draft Review:**
   - Pipe the findings into the staging script:
     ```bash
     python3 "$HOME/dotfiles/scripts/python/gh_draft_review.py" stage <pr_number> --stdin
     ```
   - If an existing pending review exists, it will attach to it; otherwise it creates a new PENDING review.

4. **Report Summary:**
   - Present the user with a categorized summary of findings (High, Med, Low).
   - Provide the direct GitHub diff URL (`https://github.com/<owner>/<repo>/pull/<id>/files`) where they can inspect, edit, and submit the review.
