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

# Ensure local guidelines exist
if [ ! -f "$DOTFILES_DIR/agents/GUIDELINES.local.md" ]; then
	info "Creating agents/GUIDELINES.local.md from example..."
	cp "$DOTFILES_DIR/agents/GUIDELINES.local.example" "$DOTFILES_DIR/agents/GUIDELINES.local.md"
fi

# Link settings
link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_CONFIG_DIR/settings.json"

# Link global instructions
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_CONFIG_DIR/CLAUDE.md"

# Link skills directory from central hub
link_file "$DOTFILES_DIR/agents/skills" "$CLAUDE_CONFIG_DIR/skills"

# Compile and merge MCP servers into ~/.claude.json
info "Merging MCP servers from agents/mcp.json into ~/.claude.json..."
python3 - <<EOF
import json
import os

dotfiles_dir = os.path.expanduser("~/dotfiles")
claude_json_path = os.path.expanduser("~/.claude.json")

# Load central MCP servers
with open(os.path.join(dotfiles_dir, "agents/mcp.json"), "r") as f:
    mcp_data = json.load(f)

# Load existing ~/.claude.json if present
claude_data = {}
if os.path.exists(claude_json_path):
    try:
        with open(claude_json_path, "r") as f:
            claude_data = json.load(f)
    except Exception:
        claude_data = {}

# Format servers for Claude Code
claude_servers = {}
for name, s in mcp_data.get("mcpServers", {}).items():
    server = dict(s)
    # Claude uses "http" transport instead of "remote"
    if server.get("type") == "remote" or ("url" in server and "command" not in server):
        server["type"] = "http"
    claude_servers[name] = server

claude_data["mcpServers"] = claude_servers

with open(claude_json_path, "w") as f:
    json.dump(claude_data, f, indent=2)
EOF

success "Claude Code setup completed!"
info "Run 'claude' to complete the OAuth login flow."
