#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

CLAUDE_CONFIG_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_CONFIG_DIR"

# Ensure agents central directory is linked
link_file "$DOTFILES_DIR/agents" "$HOME/.config/agents"

# Link settings
link_file "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_CONFIG_DIR/settings.json"

# Link global instructions
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_CONFIG_DIR/CLAUDE.md"

# Link skills directory from central hub
link_file "$DOTFILES_DIR/agents/skills" "$CLAUDE_CONFIG_DIR/skills"

# Compile and merge MCP servers into ~/.claude.json
python3 - <<EOF
import json
import os

dotfiles_dir = os.path.expanduser("~/dotfiles")
claude_json_path = os.path.expanduser("~/.claude.json")

with open(os.path.join(dotfiles_dir, "agents/mcp.json"), "r") as f:
    mcp_data = json.load(f)

claude_data = {}
if os.path.exists(claude_json_path):
    try:
        with open(claude_json_path, "r") as f:
            claude_data = json.load(f)
    except Exception:
        claude_data = {}

claude_servers = {}
for name, s in mcp_data.get("mcpServers", {}).items():
    server = dict(s)
    if server.get("type") == "remote" or ("url" in server and "command" not in server):
        server["type"] = "http"
    claude_servers[name] = server

claude_data["mcpServers"] = claude_servers

with open(claude_json_path, "w") as f:
    json.dump(claude_data, f, indent=2)
EOF
