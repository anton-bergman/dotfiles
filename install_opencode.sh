#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "OpenCode Setup"

# --- Install OpenCode binary ---
# Using the explicit tap spec: cmd:pkg:provider
# OpenCode is currently only supported on macOS via this script
smart_install "opencode:opencode-ai/opencode/opencode:brew"

# --- Setup Configuration ---
info "Setting up configuration files..."
DOTFILES_DIR="$HOME/dotfiles"
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_THEMES_DIR="$OPENCODE_CONFIG_DIR/themes"

# Ensure directories exist
mkdir -p "$OPENCODE_THEMES_DIR"

# Link main configuration
link_file "$DOTFILES_DIR/opencode/opencode.json" "$OPENCODE_CONFIG_DIR/opencode.json"

# Link theme
link_file "$DOTFILES_DIR/opencode/my-theme.json" "$OPENCODE_THEMES_DIR/my-theme.json"

success "OpenCode setup completed!"
