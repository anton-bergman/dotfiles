# INSTRUCTIONS.md

This repository contains personal dotfiles and configurations for a macOS-centric development environment. These guidelines are intended for agentic coding assistants to ensure consistency, safety, and idiomatic development within this codebase.

## Project Structure

- `agents/`: The Agnostic Agent Core. Contains universal skills, global instructions, and the single-source-of-truth MCP server definitions.
- `nvim/`: Neovim configuration (Lua-based, using Lazy.nvim).
- `zsh/`: Zsh configuration, including plugins and custom functions.
- `macos/`: macOS-specific configurations (AeroSpace, SketchyBar, Raycast).
- `tmux/`: Tmux configuration.
- `vscode/`: VS Code settings and extension lists.
- `scripts/`: Utility scripts (Python, Bash).
- `yazi/`: Yazi file manager configuration and plugins.
- `opencode/`: Base configuration templates and plugins for the OpenCode AI assistant.
- `claude/`: Base configuration templates for the Claude Code AI assistant.
- `install_*.sh`: Installation scripts for various components.

## Build and Installation

There is no traditional "build" step. Installation and updates are handled via shell scripts that create symbolic links and install dependencies.

- **Initial Setup:** Run the relevant `./install_<component>.sh` script.
- **Dependency Management:**
  - **Homebrew:** Primary package manager for macOS.
  - **Mise:** Used for managing tool versions (see `mise/config.toml`).
  - **Lazy.nvim:** Manages Neovim plugins.
  - **TPM:** Manages Tmux plugins.
  - **Pyenv/Venv:** Manages Python versions and virtual environments (specifically for Neovim/Molten).

## Agent Configuration & The Agnostic Core

This repository uses an "Agnostic Agent Core" to share skills and MCP servers across different AI clients (Claude Code, OpenCode, Cursor).

- **Skills:** Add new markdown-based skills to `agents/skills/`.
- **MCP Servers:** Define new servers ONLY in `agents/mcp.json` using the standard `mcpServers` schema.
- **Compilation:** The `opencode/opencode.json` and `claude/settings.json` files are **TEMPLATES**. If you modify `agents/mcp.json`, you MUST run `./install_opencode.sh` or `./install_claude.sh` to compile and link the configurations dynamically. Never manually edit `~/.config/opencode/opencode.json` to add an MCP server.

## Linting and Formatting

We use specific tools to maintain code quality. Agents should run these tools after making changes.

### Lua (Neovim & SketchyBar)

- **Tool:** `stylua`
- **Command:** `stylua <path_to_file>`
- **Convention:** Use **tabs** for indentation (4-space width).

### Python

- **Tool:** `ruff`
- **Command:** `ruff check <path_to_file>` (linting) and `ruff format <path_to_file>` (formatting).
- **Convention:** Adhere to PEP 8. Use type hints for function signatures.

### Shell (Zsh & Bash)

- **Tool:** `shellcheck`
- **Command:** `shellcheck <path_to_file>`
- **Convention:** Use local variables within functions. Prefer `[[ ]]` over `[ ]` in Zsh.

### JSON, YAML, Markdown

- **Tool:** `prettier`
- **Command:** `prettier --write <path_to_file>`
- **Indentation:** 2 spaces (except where 4 is established).

## Testing and Verification

There are no automated test suites for the core dotfiles. Verification must be performed manually by reloading the affected application.

- **Neovim:** Restart Neovim or run `:source %` on the modified config file. Use `:Lazy check` to verify plugin status.
- **Zsh:** Run `source ~/.zshrc` or open a new terminal session.
- **SketchyBar:** Run `sketchybar --reload`.
- **Tmux:** Run `tmux source-file ~/.config/tmux/tmux.conf`.

### Running Single Tests (Submodules)

External plugins like `zsh-syntax-highlighting` have their own test suites.

- **ZSH Syntax Highlighting:** `cd zsh/plugins/zsh-syntax-highlighting && make test`
- **ZSH Autosuggestions:** `cd zsh/plugins/zsh-autosuggestions && make test`

## Code Style Guidelines

### General Principles

- **Modularity:** Keep configurations modular. Break down large files into smaller, reusable modules (e.g., `nvim/lua/plugins/` contains one file per major plugin).
- **Idempotency:** Installation and setup scripts should be idempotent (safe to run multiple times).
- **Descriptive Naming:** Use clear, descriptive names for variables and functions (e.g., `colors`, `settings`, `load_plugins`).

### Lua Style (Neovim & SketchyBar)

- **Indentation:** Use **tabs**.
- **Modularity:** Use `require()` to load modules. Avoid global variables; use `local` instead.
- **Plugin Configs:** When adding a new plugin to Neovim, create a new file in `nvim/lua/plugins/`.
- **SketchyBar:** Define items in `macos/sketchybar/items/` and colors in `colors.lua`. Use the `helpers` directory for C-based event providers.

### Shell Style

- **Safety:** Start scripts with `set -e` (exit on error) and `set -u` (unset variables).
- **Portability:** While these are Zsh dotfiles, use POSIX-compliant syntax in `lib/` or shared scripts where possible.
- **Paths:** Always use absolute paths or resolve them relative to the dotfiles root using `$(dirname "$0")` or similar.

### VS Code & Extension Management

- **Extensions:** Maintain the list of required extensions in `vscode/vscode-extensions.txt`.
- **Settings:** Prefer modifying `vscode/settings.jsonc` (JSON with comments) and symlinking to the VS Code user directory.

### Error Handling

- **Minimalism:** Since this is configuration code, error handling is often minimal.
- **Robustness:** Ensure scripts check for the existence of commands (e.g., `if command -v brew >/dev/null; then ...`) before executing them.
- **Messaging:** Provide clear feedback in installation scripts about what is being installed or changed.

### Comments

- **Why, not What:** Focus on explaining _why_ a certain configuration is needed, especially if it addresses a non-obvious bug or specific workflow requirement.
- **Header Blocks:** Use descriptive headers in long configuration files to separate sections.

## Safety and Security

- **Secrets:** NEVER commit API keys, tokens, or personal information. Use `.env` files (ignored by git) or a secure secret manager.
- **Destructive Actions:** Be extremely cautious with `rm -rf`. Always verify the path before deletion.
- **System Changes:** Warn the user before making significant changes to macOS system settings (e.g., `defaults write`).

## Interaction Guidelines for Agents

- **Grep First:** Before modifying a configuration, grep the codebase to see how similar settings are handled elsewhere.
- **Symbolic Links:** When "installing" a new file, ensure it is placed in the `~/dotfiles` directory and symlinked to its destination in `~/.config/` or `$HOME`.
- **Plugin Management:** When adding Neovim plugins, update `nvim/lua/plugins/` and ensure any external dependencies are added to `install_nvim.sh`.
- **Agent Tooling:** When asked to create/modify a skill or MCP tool, make changes ONLY in the `agents/` directory, and then execute `./install_opencode.sh` and/or `./install_claude.sh` to compile them into the target environment.
- **Testing:** Since automated tests are limited, describe how you verified your changes (e.g., "I reloaded Neovim and confirmed the new keymap is active").
- **Consistency:** If a file uses 2-space indentation (common in JSON/YAML), maintain it. If it uses tabs (common in Lua), use tabs.
