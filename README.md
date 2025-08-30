# dotfiles

This repository contains my personal dotfiles for configuring and automating the setup of my development environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Install Dotfiles](#install-dotfiles)
  - [Install Zsh Plugins](#install-zsh-plugins)
  - [Install Neovim](#install-neovim)
  - [Install VS Code](#install-vs-code)
  - [Install Tmux](#install-tmux)
  - [Install CLI Tools](#install-cli-tools)
- [Directory Structure](#directory-structure)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before proceeding, ensure the following are installed:

1. **Homebrew:** Install Homebrew (macOS package manager) using:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **iTerm2:** Install iTerm2 (recommended terminal for macOS):
   ```bash
   brew install --cask iterm2
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

---

### Install Neovim

To set up Neovim and its dependencies, run the Neovim installation script:

```bash
cd ~/dotfiles && ./install_nvim.sh
```

This script will:

- Install **Neovim**, **LuaRocks**, and **Ripgrep** _(required for Telescope fuzzy finding)_.
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
   cd ~/dotfiles/cli-tools && ./install_cli_tools.sh
   ```

This script will install:

- **Fastfetch:** A fast system information tool.
- **TLDR:** Simplified and community-driven man pages.

---

## Directory Structure

The repository is organized as follows:

```
dotfiles/
├── cli-tools/               # CLI tools installation scripts
├── iterm2/                  # iTerm2 configuration files
├── macos/                   # macOS-specific settings and scripts
├── nvim/                    # Neovim configuration
├── tmux/                    # Tmux configuration
├── vscode/                  # VS Code settings and extensions
├── zsh/                     # Zsh configuration and plugins
├── install_nvim.sh          # Neovim installation script
├── install_tmux.sh          # Tmux installation script
├── install_vscode.sh        # VS Code installation script
├── install_zsh.sh           # Zsh installation script
└── README.md                # Documentation
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
