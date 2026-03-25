#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise/etc are ready
ensure_base_ready

header "Neovim Setup"

# --- Install Neovim & Core Dependencies ---
info "Installing core dependencies..."

# Linux-Specific Repository Setup
if [ "$IS_LINUX" = true ]; then
	# Ensures we get the latest stable version on Ubuntu/Debian
	add_apt_repo "ppa:neovim-ppa/stable"
fi

# Core tools
# Format: cmd:pkg:provider
smart_install "nvim:neovim:brew" "nvim:neovim:apt"
smart_install "luarocks:luarocks:brew" "luarocks:luarocks:apt"
smart_install "rg:ripgrep:brew" "rg:ripgrep:apt"
smart_install "magick:imagemagick:brew" "magick:imagemagick:apt"
smart_install "node:node:mise" # Node.js (Required for many LSPs)

# --- Symlink dotfiles ---
info "Linking configuration..."
link_file "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

success "Neovim setup completed!"
