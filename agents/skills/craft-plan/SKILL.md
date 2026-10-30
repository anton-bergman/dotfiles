---
name: craft-plan
description: Author or update a comprehensive, production-grade implementation plan directly in chat. Use on initial feature/ticket intake, or after discussion, audits, and manual review to synthesize all context into a hardened execution specification.
---

# Craft Implementation Plan

Author or update a structured, production-grade implementation plan directly in chat.

Obey ASD-STE100: write short, declarative sentences in the imperative mood. Zero conversational filler, flattery, or speculative prose.

---

## Core Invariants

1. **Grounded Reality & Symbol Anchoring:** Read target files, caller sites, schemas, and tests before writing or updating the plan. Cite verified existing symbols and signatures. Never speculate on APIs, tables, or interfaces.
2. **Context Harvesting:** Ingest the full conversation history. Incorporate all requirements, tickets, user critiques, and decisions resolved across prior turns. Never resurrect assumptions, abstractions, or scope that were rejected in earlier messages.
3. **Surgical Scope & Minimal Diffs (Karpathy Rule 3):** Touch only what is strictly required. No unsolicited refactors, adjacent cleanups, or premature abstractions (YAGNI).
4. **Zero Unrequested Formatting:**
   - NEVER schedule or invoke code formatters (`ruff format`, `prettier --write`, `stylua`, `black`).
   - NEVER reformat untouched lines, whitespace, or comments.
   - Formatting belongs exclusively to the human developer.
5. **Data & Systems Invariants:**
   - BigQuery / Data Warehouse: partition filters (`date`, `created_at`) and query `LIMIT`s are mandatory.
   - Idempotence: all operational steps must be safely re-runnable upon partial failure.
6. **Falsifiable, Isolated Verification (Karpathy Rule 4):** Every step must state an exact, isolated command to verify correctness (`pytest path/to/test.py -k test_name`, `ruff check path/to/file.py`, `shellcheck path/to/script.sh`). Blanket full-suite test runs are prohibited.

---

## Output Layout

Emit the plan directly in chat using this exact markdown structure:

```markdown
# Implementation Plan: <Feature / Fix Title>

### 1. Intent & Architectural Invariants

- **Core Intent:** <1-2 sentences on what is being solved>
- **Locked Decisions & Invariants:**
  - <Resolved decision from context, ticket, or prior discussion>
  - <Resolved decision from context, ticket, or prior discussion>
- **Strict Out-of-Scope (YAGNI):**
  - <Explicitly cut helper / abstraction / file>
  - Zero automated formatting policy.

### 2. File Modification Inventory

| File Path          | Action (`Modify` / `Create` / `Delete`) | Target Symbols & Anchors                      |
| :----------------- | :-------------------------------------- | :-------------------------------------------- |
| `path/to/file.ext` | Modify                                  | `function_name(arg: Type)` (verified in file) |

### 3. Phased Execution Sequence

<!-- Group work into logical architectural phases. Each phase contains an arbitrary number of atomic, sequential steps. -->

#### Phase 1: <Foundation / Core Domain / State>

- **Step 1:** `<file_path>` (`<exact_symbol_or_hook>`)
  - **Operation:** <Imperative instruction of exact change>
  - **Constraint:** <What NOT to touch or change>
  - **Verification:** `<isolated shell command: focused test or linter>`
- **Step 2:** `<file_path>` (`<exact_symbol_or_hook>`)
  - **Operation:** <Imperative instruction of exact change>
  - **Constraint:** <What NOT to touch or change>
  - **Verification:** `<isolated shell command: focused test or linter>`

#### Phase 2: <Integration / Callers / Surface>

- **Step 3:** `<file_path>` (`<exact_symbol_or_hook>`)
  - **Operation:** <Imperative instruction of exact change>
  - **Constraint:** <What NOT to touch or change>
  - **Verification:** `<isolated shell command: focused test or linter>`
  <!-- Add further steps in this phase as needed -->

#### Phase 3: <Test Suite & End-to-End Validation>

- **Step N:** `<test_file_path>`
  - **Operation:** <Add focused unit / regression tests covering edge cases>
  - **Verification:** `<exact test execution command>`

### 4. Blast Radius & Failure Containment

- **Failure Vector:** <What happens on edge-case / invalid input / partial failure>
- **Containment & Idempotence:** <Why data corruption or cascading failure cannot occur>

### 5. Critical Trade-offs & Status Gate

<!-- If unresolved forks remain: -->

- **Open Questions:**
  - <Decision fork 1 requiring human input or grilling>
- **STATUS:** `BLOCKED` — Address open questions above before proceeding.

<!-- If all forks are resolved: -->

- **Open Questions:** None — all decision branches resolved.
- **STATUS:** `READY TO BUILD` — Reply `build` (or press Shift+Tab) to execute.
```
