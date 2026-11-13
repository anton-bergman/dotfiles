#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

# --- Symlink Configuration ---
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
