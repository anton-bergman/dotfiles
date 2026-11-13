# dotfiles

Like most dotfiles, this is an ongoing exercise in convincing myself that tweaking terminal configs counts as productive engineering. It's my daily driver setup for macOS and Linux, built to be predictable, modular and honest about what it does. It uses **Mise** for portable runtimes, a simple host manifest (`packages.psv`) and an orchestrator that sets up the whole workflow without the usual headaches.

---

## Overview

The repository manages complete, self-contained environments for:

- **Shell & Terminal:** Zsh (plugins, completions), Starship prompt, Hack Nerd Font, and Ghostty.
- **Editor:** Modular Neovim (Lazy.nvim, LSPs, treesitter, image.nvim) and VS Code settings sync.
- **Multiplexer:** Tmux with TPM (Tmux Plugin Manager) and native system clipboard synchronization.
- **AI Coding Agents:** Agnostic Agent Core managing shared skills, guidelines, and MCP servers across **Pi**, **Claude Code**, and **OpenCode**.
- **Package Management:** Single declarative registry in `mise/config.toml` (Node, Python, uv, Bun, CLI utilities) paired with `packages.psv` for OS casks, fonts, and native C-libraries.

---

## Quick Start

On a fresh machine, clone the repository into your home directory:

```bash
git clone https://github.com/anton-bergman/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`./install.sh` verifies prerequisites. If **Mise** or **Homebrew** (macOS) are missing, it prompts to install them automatically before provisioning.

---

## Usage

Everything runs through `./install.sh`:

```bash
# Set up all active modules (fresh machine or full sync)
./install.sh

# Target a specific tool or composite group
./install.sh nvim             # Sync Neovim, its host dependencies and config
./install.sh tmux             # Sync Tmux, TPM plugins and config
./install.sh agents           # Sync Pi, Claude Code and OpenCode together

# Keep things up to date across Mise, Homebrew and Git plugins
./install.sh upgrade          # Upgrade everything across the entire system
./install.sh upgrade nvim     # Upgrade only Neovim and its C-libraries
./install.sh upgrade agents   # Upgrade all AI agent harnesses

# See what's active, dormant or available
./install.sh list
```

---

## Machine-Specific Profiles

Default active modules are configured in `install.sh`. To customize which modules install on a specific machine (e.g. a minimal headless server vs. a personal MacBook) without modifying git:

Create `.active_modules` in the repository root:

```bash
# ~/dotfiles/.active_modules
zsh
tmux
nvim
fnox
pi
```

`./install.sh` automatically detects this file and provisions only your selected profile.

---

## Diagnostics & Troubleshooting

- **Execution Logs:** Every run appends full sub-command outputs to `/tmp/dotfiles-install.log`.
- **Verbose Output:** Pass `-v` to stream raw command outputs in real-time:
  ```bash
  ./install.sh -v nvim
  ```
- **Error Diagnostics:** If an installation fails, the runner halts and replays the exact failure output directly on the screen.
- **Permissions:** Ensure scripts have executable permissions:
  ```bash
  chmod +x ~/dotfiles/install.sh ~/dotfiles/*/setup.sh
  ```
