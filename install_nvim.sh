#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise/etc are ready
ensure_base_ready

header "Neovim Setup"

# --- Install Host System Dependencies ---
info "Installing host system dependencies..."
host_install_id "luarocks"
host_install_id "imagemagick"

# --- Symlink dotfiles ---
info "Linking configuration..."
link_file "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

success "Neovim setup completed!"
