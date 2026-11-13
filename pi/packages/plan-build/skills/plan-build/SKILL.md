---
name: plan-build
description: Plan/Build workflow mode control. ACTIVATE whenever the user says "plan" (produce an implementation plan only, make NO changes) or "build" (execute changes). Use for plan-first workflows, feature implementation, refactoring, or any task where the user wants to approve a plan before changes are made.
---

# Plan / Build Mode

The user controls the workflow with two keywords or the `Shift+Tab` keyboard shortcut:

- **plan** (or Shift+Tab) — you are in PLAN mode: only produce a plan, protect state against mutations.
- **build** (or Shift+Tab) — you are in BUILD mode: execute the plan and make changes.

A companion extension enforces this mechanically: in plan mode, `write`/`edit`/`rename` tool calls, mutating MCP actions, and state-modifying `bash` commands are blocked. The mode is sticky until the user says **build** (or presses Shift+Tab).

## When the user says "plan"

Produce a structured implementation plan.

### State Protection Invariants

- Do NOT create, modify, or delete workspace files (`write`, `edit`, `rename`, `rm`, unquoted shell redirects `>`).
- Do NOT mutate Git state (`git commit`, `git push`, `git merge`, `git checkout`, `git reset`, `git rebase`).
- Do NOT execute remote mutations (SQL DDL/DML, cloud infrastructure updates via AWS/GCP/Azure/K8s, mutating MCP calls).

### Computational Inspection IS EXPLICITLY AUTHORIZED

- You ARE ACTIVELY ENCOURAGED to run non-mutating ad-hoc scripts to analyze data, parse schemas, or inspect runtime environments.
- You ARE AUTHORIZED to run read-only database queries and passive cloud reads (`aws`/`gcloud`/`az` `describe`/`list`/`get`).
- Never refuse an ad-hoc calculation, data inspection, or read-only query because you are in plan mode. Execute the inspection and use the findings to author an accurate plan.

Use this plan format consistently:

```markdown
# Implementation Plan: <short title>

## Goal

<what we're building and why>

## Steps

1. <ordered, concrete step> — <what it touches and why>

## Files

- <path> — create/modify — <what changes>

## Tests

- <test file / command> — <what it verifies>

## Risks / Open Questions

- <anything uncertain, decisions needed>
```

End the plan by telling the user to say **"build"** (or press `Shift+Tab`) to proceed.

## When the user says "build"

Execute: make the changes described in the plan, run the relevant tests, and verify the work. Work through plan steps in order. Report what was done and what tests were run.
