#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"
ensure_base_ready

header "Tmux Setup"

# --- Install packages ---
info "Installing Tmux..."
host_install_id "tmux"

# --- Plugin Management ---
info "Managing Tmux Plugin Manager (TPM)..."
clone_or_pull "https://github.com/tmux-plugins/tpm.git" "$HOME/.tmux/plugins/tpm"

# --- Symlink dotfiles ---
info "Linking configuration..."
link_file "$HOME/dotfiles/tmux" "$HOME/.config/tmux"

# Ensure Python utility scripts are executable
chmod +x "$HOME/dotfiles/scripts/python/tmux_safe_copy.py" 2>/dev/null || true

success "Tmux setup completed!"
