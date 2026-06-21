# dotfiles

This repository contains my personal dotfiles for configuring and automating the setup of my development environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Install Dotfiles](#install-dotfiles)
  - [Install Zsh Plugins](#install-zsh-plugins)
  - [Install Python Lab](#install-python-lab)
  - [Install Neovim](#install-neovim)
  - [Install VS Code](#install-vs-code)
  - [Install OpenCode](#install-opencode)
  - [Install Claude Code](#install-claude-code)
  - [Install Ghostty](#install-ghostty)
  - [Install Tmux](#install-tmux)
  - [Install CLI Tools](#install-cli-tools)
  - [Install Wallpapers](#install-wallpapers)
- [Directory Structure](#directory-structure)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before proceeding, ensure the following are installed:

1. **Homebrew:** Install Homebrew (macOS package manager) using:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

---

## Installation

### Install Dotfiles

1. Clone this repository into your home directory:

   ```bash
   git clone https://github.com/anton-bergman/dotfiles.git ~/dotfiles
   ```

2. Follow the individual installation steps for each component (e.g., Zsh, Neovim, VS Code, Tmux, CLI tools) as outlined below.

---

### Install Zsh Plugins

To set up Zsh plugins, run the Zsh installation script:

```bash
cd ~/dotfiles && ./install_zsh.sh
```

This script will:

- Install **Oh-My-Posh** and the **Hack Nerd Font**.
- Clone and set up the following Zsh plugins:
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
  - `zsh-completions`
- Set up symbolic links for `.zshrc`.
- Set up symbolic links for `.vimrc` (basic Vim configuration).
- Load custom functions from `functions.zsh`.

---

### Install Python Lab

To set up the persistent Python Lab environment (used for testing and data utilities), run the installation script:

```bash
cd ~/dotfiles && ./install_python_lab.sh
```

This script will:

- Install **uv** (managed by **Mise**) for ultra-fast package management.
- Initialize the lab project in `~/dotfiles/scripts/python/` with core data science and utility packages (`pandas`, `rich`, `httpx`, etc.).
- Set up symbolic links to make the environment accessible at `~/.virtualenvs/lab`.
- Enable the `py` command for a pre-configured **IPython** shell and rapid script execution.

---

### Install Neovim

To set up Neovim and its dependencies, run the Neovim installation script:

```bash
cd ~/dotfiles && ./install_nvim.sh
```

This script will:

- Install **Neovim**, **LuaRocks**, **Ripgrep** _(required for Telescope fuzzy finding)_, and **ImageMagick** _(required for image.nvim plugin)_.
- Set up symbolic links for Neovim configuration.
- Configure **Lazy.nvim** as the plugin manager with pre-installed plugins for LSP, autocompletion, syntax highlighting, and more.

To start Neovim:

```bash
nvim
```

To update plugins inside Neovim:

```bash
:Lazy sync
```

---

### Install VS Code

To set up VS Code, run the VS Code installation script:

```bash
cd ~/dotfiles && ./install_vscode.sh
```

This script will:

- Install VS Code (if not already installed).
- Install extensions listed in `vscode/vscode-extensions.txt`.
- Set up symbolic links for VS Code settings.

---

### Install OpenCode

OpenCode is an AI-powered coding assistant CLI. To set up OpenCode configuration, run the installation script:

```bash
cd ~/dotfiles && ./install_opencode.sh
```

This script will:

- Install **OpenCode** via Homebrew (if not already installed).
- Generate a dynamic `opencode.json` configuration file by merging the base template (`opencode/opencode.json`) with universal MCP servers (`agents/mcp.json`).
- Set up symbolic links for universal agent skills and instructions from the `agents/` directory.
- Install OpenCode plugins if `package.json` exists in `~/.config/opencode/`.

---

### Install Claude Code

Claude Code is Anthropic's AI-powered coding assistant CLI. To set up Claude Code configuration, run the installation script:

```bash
cd ~/dotfiles && ./install_claude.sh
```

This script will:

- Install **Claude Code** via Homebrew cask (if not already installed).
- Generate a Claude-compatible `mcp.json` file by extracting only local MCP servers from the universal `agents/mcp.json`.
- Set up symbolic links for Claude Code settings (`settings.json`).
- Set up symbolic links for universal agent skills and global instructions (`agents/INSTRUCTIONS.md`).

**Note:** After installation, run `claude` once to complete the OAuth login flow.

---

### Install Ghostty

Ghostty is a modern, GPU-accelerated terminal emulator. To set up Ghostty, run the installation script:

```bash
cd ~/dotfiles && ./install_ghostty.sh
```

This script will:

- Install **Ghostty** via Homebrew.
- Set up symbolic links for Ghostty configuration (`config.toml`).

---

### Install Tmux

To set up Tmux run the Tmux installation script:

```bash
cd ~/dotfiles && ./install_tmux.sh
```

This script will:

- Install Tmux and the Tmux Plugin Manager (TPM).
- Set up symbolic links for Tmux configuration.

---

### Install CLI Tools

To install additional CLI tools:

1. Run the CLI tools installation script:
   ```bash
   cd ~/dotfiles && ./install_cli_tools.sh
   ```

This script will install:

- **Fastfetch:** A fast system information tool.
- **TLDR:** Simplified and community-driven man pages.
- **Btop:** A modern, interactive terminal resource monitor.
- **Fzf:** A general-purpose command-line fuzzy finder.
- **Lazygit:** A simple terminal UI for git commands.
- **VisiData:** A terminal spreadsheet viewer and data analyzer.

---

### Install Wallpapers

To set up desktop wallpapers:

1. Run the wallpaper installation script:
   ```bash
   cd ~/dotfiles && ./install_wallpapers.sh
   ```

**Note:** Wallpapers are not included in the repository due to copyright restrictions. They are downloaded from their original sources for personal use only.

---

## Directory Structure

The repository is organized as follows:

```
dotfiles/
├── agents/                  # Agnostic Agent Core: universal skills, MCP servers, and global instructions
├── claude/                  # Claude Code base configuration templates
├── ghostty/                 # Ghostty terminal configuration
├── git/                     # Global Git configuration (gitconfig, gitignore_global)
├── iterm2/                  # iTerm2 configuration profiles and themes
├── lib/                     # Shared shell utility functions (utils.sh)
├── macos/                   # macOS-specific settings and scripts
│   ├── aerospace/           # AeroSpace window manager config
│   ├── raycast/             # Raycast scripts and setup
│   ├── simple-bar/          # Simple-Bar configuration
│   └── sketchybar/          # SketchyBar configuration
├── mise/                    # Global tool version manager (mise) configuration
├── nvim/                    # Neovim configuration (Lazy.nvim setup)
├── opencode/                # OpenCode base configuration templates and plugins
├── scripts/                 # Utility scripts (e.g., Python Lab and data tools)
├── tmux/                    # Tmux configuration
├── vim/                     # Basic Vim configuration (.vimrc)
├── vscode/                  # VS Code settings and extension lists
├── wallpapers/              # Desktop wallpapers (downloaded, gitignored)
├── zsh/                     # Zsh configuration, plugins, and custom functions
├── install_claude.sh        # Claude Code installation script
├── install_cli_tools.sh     # CLI tools installation script (btop, fzf, fastfetch, etc.)
├── install_ghostty.sh       # Ghostty terminal installation script
├── install_nvim.sh          # Neovim installation script
├── install_opencode.sh      # OpenCode installation script
├── install_python_lab.sh    # Python Lab installation script
├── install_tmux.sh          # Tmux installation script
├── install_vscode.sh        # VS Code installation script
├── install_wallpapers.sh    # Wallpaper installation script
├── install_zsh.sh           # Zsh installation script
├── README.md                # Main documentation and installation guide
└── TODO.md                  # Personal task list and roadmap
```

---

## Troubleshooting

- **Permission Issues:** Ensure all scripts have executable permissions:

  ```bash
  chmod +x ~/dotfiles/*.sh ~/dotfiles/cli-tools/*.sh
  ```

- **Missing Dependencies:** Verify Homebrew and required tools are installed.

- **Symbolic Link Issues:** Remove existing conflicting files or directories before running the scripts:
  ```bash
  rm -rf ~/.config/nvim ~/.config/tmux ~/.zshrc
  ```

---
