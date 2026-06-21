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

# Ensure agents central directory is linked
link_file "$DOTFILES_DIR/agents" "$HOME/.config/agents"

# Link settings
link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_CONFIG_DIR/settings.json"

# Link global instructions
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_CONFIG_DIR/CLAUDE.md"

# Link skills directory from central hub
link_file "$DOTFILES_DIR/agents/skills" "$CLAUDE_CONFIG_DIR/skills"

# Remove existing config if it is a symlink or file to prevent writing through symlink
rm -f "$CLAUDE_CONFIG_DIR/mcp.json"

# Compile and write Claude-compatible mcp.json (local servers only)
info "Generating filtered mcp.json for Claude Code..."
python3 - <<EOF
import json
import os

dotfiles_dir = os.path.expanduser("~/dotfiles")
claude_config_dir = os.path.expanduser("~/.claude")

with open(os.path.join(dotfiles_dir, "agents/mcp.json"), "r") as f:
    mcp_data = json.load(f)

filtered_mcp = {"mcpServers": {}}
for name, server in mcp_data.get("mcpServers", {}).items():
    if server.get("type") != "remote":
        filtered_mcp["mcpServers"][name] = server

os.makedirs(claude_config_dir, exist_ok=True)
with open(os.path.join(claude_config_dir, "mcp.json"), "w") as f:
    json.dump(filtered_mcp, f, indent=2)
EOF

success "Claude Code setup completed!"
info "Run 'claude' to complete the OAuth login flow."
