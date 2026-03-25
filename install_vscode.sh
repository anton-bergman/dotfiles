#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "VS Code Setup"

# --- Install VS Code ---
# Use the explicit spec model: cmd:pkg:provider
smart_install "code:visual-studio-code:cask" "code:code:apt"

# --- Install extensions ---
VSCODE_EXT_FILE="$HOME/dotfiles/vscode/vscode-extensions.txt"

if [ -f "$VSCODE_EXT_FILE" ]; then
	info "Installing VS Code extensions..."
	# Install all VS Code extensions from the list, ignoring empty lines and lines starting with #
	grep -vE '^\s*(#|$)' "$VSCODE_EXT_FILE" | xargs -n 1 code --install-extension
else
	warn "No vscode-extensions.txt file found at $VSCODE_EXT_FILE. Skipping extension installation."
fi

# --- Symlink settings ---
info "Setting up VS Code settings..."

# Detect VS Code user settings directory using vars from utils.sh
if [ "$IS_MAC" = true ]; then
	VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
	VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

# Link settings.jsonc
# link_file handles backup of existing real files
link_file "$HOME/dotfiles/vscode/settings.jsonc" "$VSCODE_USER_DIR/settings.json"

success "VS Code setup completed!"
