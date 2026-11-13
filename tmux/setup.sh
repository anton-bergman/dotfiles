#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

# --- Plugin Management (TPM) ---
clone_or_pull "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm"

# --- Symlink Configuration ---
link_file "$DOTFILES_DIR/tmux" "$HOME/.config/tmux"

# Ensure Python utility scripts are executable
chmod +x "$DOTFILES_DIR/scripts/python/tmux_safe_copy.py" 2>/dev/null || true
