#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

if [ "$IS_MAC" = true ]; then
	GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
else
	GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
fi

link_file "$DOTFILES_DIR/ghostty/config.toml" "$GHOSTTY_CONFIG_DIR/config"
