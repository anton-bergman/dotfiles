---
name: plan-audit
description: Rigorously stress-test and red-team an implementation plan against the actual codebase before writing code. Delivers a high-density vulnerability assessment, prunes over-engineering, hardens the execution steps, and surfaces the top 1-2 critical tradeoff decisions. Use when the user asks to "audit my plan", "review plan", "stress-test plan", or "critique implementation".
---

Rigorously stress-test a proposed implementation plan before any code is written.

Act as an adversarial Staff/Principal Engineer: assume the plan contains hidden assumptions, edge-case blindspots, or unnecessary abstractions until proven otherwise. Every critique must be grounded in the actual codebase, not theoretical best practices.

## Workflow

### 1. Ingest & Ground in the Codebase

- Read the proposed plan and isolate: target files, new dependencies, state changes, and verification steps.
- **Never critique in a vacuum.** Use file-reading and search tools (`grep`, `glob`, `read`) to verify:
  - Do the referenced files, functions, and interfaces exist as assumed?
  - Does the codebase already have an existing utility, helper, or standard library feature that solves this? (Ponytail / YAGNI / DRY).
  - Who are the upstream and downstream callers of the components being modified?

### 2. Adversarial Stress-Testing

Audit the plan across four critical failure vectors:

1. **Codebase Reality & Abstraction Creep:** Are we building unnecessary wrappers, generic abstractions, or configuration nobody asked for? Can this be done with fewer moving parts or fewer files?
2. **Failure Modes & Blast Radius:** What happens on partial failure, network blip, or invalid input? Is there data loss or silent state corruption? How is recovery handled?
3. **State, Concurrency & Lifecycle:** Are there race conditions, stale cache reads, memory/resource leaks, or unhandled asynchronous edge cases?
4. **Verification Rigor:** Does the plan contain concrete, falsifiable checks, or vague "write tests" promises? What specific command proves this change works end-to-end?

### 3. Deliver the Output

Emit a high-density, structured review adhering strictly to the sections below:

---

### Architectural Verdict

- **[APPROVED]** / **[NEEDS HARDENING]** / **[RETHINK APPROACH]**
- 1–2 sentences summarizing the biggest architectural risk or strongest validation.

### Vulnerability & Blindspot Matrix

| Severity                     | Component                | Risk / Failure Mode     | Concrete Remediation       |
| :--------------------------- | :----------------------- | :---------------------- | :------------------------- |
| **High** / **Med** / **Low** | `path/to/file` or symbol | What will break and why | Exact change to prevent it |

### Scope & YAGNI Pruning (What to Cut)

- Explicitly call out unnecessary files, premature abstractions, or over-engineered helpers that can be deleted or omitted from the plan. If the plan is already minimal, state "None — scope is minimal."

### Hardened Execution Sequence

A refined, step-by-step implementation order with dependencies resolved, failure guards added, and exact verification commands attached to each phase.

### Critical Tradeoff Questions (Max 1–2)

Surface **only the single highest-risk fork in the decision tree** that cannot be resolved by exploring the codebase (e.g., performance vs. consistency, user-facing error behavior, or migration strategy). Include your recommended choice for each.
