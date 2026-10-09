#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

header "Tmux Setup"

# --- Install packages ---
info "Installing Tmux..."
# Format: cmd:pkg:provider
smart_install "tmux:tmux:brew" "tmux:tmux:apt"

# --- Plugin Management ---
info "Managing Tmux Plugin Manager (TPM)..."
clone_or_pull "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm"

# --- Symlink dotfiles ---
info "Linking configuration..."
link_file "$HOME/dotfiles/tmux" "$HOME/.config/tmux"

# Ensure Python utility scripts are executable
chmod +x "$HOME/dotfiles/scripts/python/tmux_safe_copy.py" 2>/dev/null || true

success "Tmux setup completed!"
