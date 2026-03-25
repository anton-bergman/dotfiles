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

success "Tmux setup completed!"
