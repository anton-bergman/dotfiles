---
name: onboard
description: Build a comprehensive structural, dependency, and architectural map of the current workspace. Use when the user asks you to investigate a new project, onboard, or get a 10x engineering overview.
---

Perform a highly structured, token-efficient architectural onboarding of the current workspace. Follow these steps sequentially:

1. **Identify Project Specifications & Dependencies:**
   - Scan the root directory for configuration files (e.g., `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `requirements.txt`).
   - Read these files to identify the language runtime, framework version, dependencies, test framework, and linter settings.

2. **Map Codebase Topology:**
   - Find active source, test, configuration, and documentation directories.
   - Map key entry points, routers, models, and utility handlers.
   - Ignore standard directories (`node_modules`, `.git`, `dist`, etc.) to conserve token space.

3. **Verify Local Developer Guidelines:**
   - Look for standard onboarding files such as `CLAUDE.md`, `AGENTS.md`, `README.md`, or `CONTRIBUTING.md`.
   - Read these files to pinpoint exact formatting, linting, building, and verification workflows.

4. **Construct the Mental Model:**
   - Synthesize this information into a precise mental model of the project's data flow, architecture patterns, and conventions.

5. **Deliver a Ultra-Concise Summary:**
   - DO NOT output large file dumps or chatty prose.
   - Output a clean, high-density markdown summary of:
     - **Stack & Specs:** Runtime, primary frameworks, test suites, and linters.
     - **Architecture:** Key directories, entry points, and design patterns.
     - **Guidelines:** The exact commands used to build, test, and lint the project.
     - **Active Tasks (if any):** Note any `TODO.md` or issues currently visible.
