#!/bin/bash
# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "Ghostty Setup"

# --- Install Ghostty ---
# Format: cmd:pkg:provider
smart_install "ghostty:ghostty:brew"

# --- Symlink dotfiles ---
info "Linking configuration..."

if [ "$IS_MAC" = true ]; then
	GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
else
	# Ghostty on Linux usually looks in ~/.config/ghostty
	GHOSTTY_CONFIG_DIR="$HOME/.config/ghostty"
fi

link_file "$HOME/dotfiles/ghostty/config.toml" "$GHOSTTY_CONFIG_DIR/config"

success "Ghostty setup completed!"
