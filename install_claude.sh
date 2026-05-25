#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "Claude Code Setup"

# --- Install Claude Code binary ---
# Claude Code is distributed as a Homebrew cask (native binary)
smart_install "claude:claude-code:cask"

# --- Setup Configuration ---
info "Setting up configuration files..."
DOTFILES_DIR="$HOME/dotfiles"
CLAUDE_CONFIG_DIR="$HOME/.claude"

# Ensure directory exists
mkdir -p "$CLAUDE_CONFIG_DIR"

# Link settings
link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_CONFIG_DIR/settings.json"

# Link global instructions
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_CONFIG_DIR/CLAUDE.md"

# Link skills directory
link_file "$DOTFILES_DIR/claude/skills" "$CLAUDE_CONFIG_DIR/skills"

success "Claude Code setup completed!"
info "Run 'claude' to complete the OAuth login flow."
