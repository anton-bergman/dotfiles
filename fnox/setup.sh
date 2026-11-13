#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

link_file "$DOTFILES_DIR/fnox/config.toml" "$HOME/.config/fnox/config.toml"
