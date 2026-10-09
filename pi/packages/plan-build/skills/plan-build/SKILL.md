---
name: plan-build
description: Plan/Build workflow mode control. ACTIVATE whenever the user says "plan" (produce an implementation plan only, make NO changes) or "build" (execute changes). Use for plan-first workflows, feature implementation, refactoring, or any task where the user wants to approve a plan before changes are made.
---

# Plan / Build Mode

The user controls the workflow with two keywords or the `Shift+Tab` keyboard shortcut:

- **plan** (or Shift+Tab) — you are in PLAN mode: only produce a plan, never change anything.
- **build** (or Shift+Tab / "ok, go") — you are in BUILD mode: execute the plan and make changes.

A companion extension enforces this mechanically: in plan mode, `write`/`edit` tool calls and mutating `bash` commands are blocked. The mode is sticky until the user says **build** (or explicitly approves the plan, e.g. "ok, go", or presses Shift+Tab).

## When the user says "plan"

Produce a structured implementation plan. Do NOT modify, create, or delete files. Do NOT run mutating commands (installs, migrations, git write operations, shell redirects, etc.). Read-only inspection (`ls`, `cat`/`grep`, `git status`/`diff`/`log`, `php artisan route:list`, etc.) is allowed.

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
