#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

if [ "$IS_MAC" = false ]; then
	log_warn "Module 'macos' is only supported on macOS. Skipping."
	exit 0
fi

# Compile input source switcher if swiftc is available
if command_exists swiftc && [ -f "$DOTFILES_DIR/macos/aerospace/switch-input-source.swift" ]; then
	mkdir -p "$HOME/.local/bin"
	swiftc -O "$DOTFILES_DIR/macos/aerospace/switch-input-source.swift" \
		-o "$HOME/.local/bin/switch-input-source" 2>/dev/null || true
fi

# Symlink Configurations
link_file "$DOTFILES_DIR/macos/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
link_file "$DOTFILES_DIR/macos/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
