#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "Zsh & Dotfiles Setup"

# --- Install packages ---
info "Installing required packages..."

# Install oh-my-posh
# Format: cmd:pkg:provider
smart_install "oh-my-posh:jandedobbeleer/oh-my-posh/oh-my-posh:brew"

# Install Nerd Font (Hack font)
if ! font_installed "Hack"; then
	info "Installing Nerd Font Hack..."
	oh-my-posh font install Hack
else
	success "Hack font already installed."
fi

# --- Clone zsh plugins repositories ---
info "Managing Zsh plugins..."

PLUGIN_DIR="$HOME/dotfiles/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

clone_or_pull "https://github.com/zsh-users/zsh-autosuggestions.git" "$PLUGIN_DIR/zsh-autosuggestions"
clone_or_pull "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$PLUGIN_DIR/zsh-syntax-highlighting"
clone_or_pull "https://github.com/zsh-users/zsh-completions.git" "$PLUGIN_DIR/zsh-completions"

# --- Symlink dotfiles ---
info "Linking configuration files..."

DOTFILES_DIR="$HOME/dotfiles"

link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
link_file "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"

success "Zsh and dotfiles setup completed!"
