#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_THEMES_DIR="$OPENCODE_CONFIG_DIR/themes"

mkdir -p "$OPENCODE_THEMES_DIR"

# Ensure agents central directory is linked
link_file "$DOTFILES_DIR/agents" "$HOME/.config/agents"

# Compile global AGENTS.md for OpenCode (truly optional local guidelines)
rm -f "$OPENCODE_CONFIG_DIR/AGENTS.md"
if [ -f "$DOTFILES_DIR/agents/GUIDELINES.local.md" ]; then
	cat "$DOTFILES_DIR/agents/GUIDELINES.md" "$DOTFILES_DIR/agents/GUIDELINES.local.md" >"$OPENCODE_CONFIG_DIR/AGENTS.md"
else
	cp "$DOTFILES_DIR/agents/GUIDELINES.md" "$OPENCODE_CONFIG_DIR/AGENTS.md"
fi

rm -f "$OPENCODE_CONFIG_DIR/opencode.json"

# Compile and write main configuration with merged MCPs
python3 - <<EOF
import json
import os
import re

dotfiles_dir = os.path.expanduser("~/dotfiles")
opencode_config_dir = os.path.expanduser("~/.config/opencode")

# Load template config and strip comments
with open(os.path.join(dotfiles_dir, "opencode/opencode.json"), "r") as f:
    lines = f.readlines()
    clean_lines = [re.sub(r'(?<!:)\/\/.*', '', line) for line in lines]
    config = json.loads("".join(clean_lines))

# Load central MCP servers
with open(os.path.join(dotfiles_dir, "agents/mcp.json"), "r") as f:
    mcp_data = json.load(f)

# Translate mcpServers to OpenCode mcp format
opencode_mcp = {}
for name, mcp_server in mcp_data.get("mcpServers", {}).items():
    server_type = mcp_server.get("type")
    
    if server_type in ("remote", "sse", "http") or "url" in mcp_server:
        opencode_mcp[name] = {
            "type": "remote",
            "url": mcp_server.get("url"),
            "enabled": True
        }
        if "headers" in mcp_server:
            opencode_mcp[name]["headers"] = mcp_server.get("headers")
    else:
        opencode_mcp[name] = {
            "type": "local",
            "command": [mcp_server.get("command")] + mcp_server.get("args", []),
            "enabled": True
        }

config["mcp"] = opencode_mcp

os.makedirs(opencode_config_dir, exist_ok=True)
with open(os.path.join(opencode_config_dir, "opencode.json"), "w") as f:
    json.dump(config, f, indent=2)
EOF

# Link theme
link_file "$DOTFILES_DIR/opencode/my-theme.json" "$OPENCODE_THEMES_DIR/my-theme.json"

# Link plugins directory
link_file "$DOTFILES_DIR/opencode/plugins" "$OPENCODE_CONFIG_DIR/plugins"

# Link skills directory from central hub
link_file "$DOTFILES_DIR/agents/skills" "$OPENCODE_CONFIG_DIR/skills"

# Link custom commands
if [ -L "$OPENCODE_CONFIG_DIR/commands" ]; then
	rm "$OPENCODE_CONFIG_DIR/commands"
fi
mkdir -p "$OPENCODE_CONFIG_DIR/commands"

if [ -d "$DOTFILES_DIR/agents/commands" ]; then
	for cmd in "$DOTFILES_DIR/agents/commands"/*.md; do
		[ -e "$cmd" ] && link_file "$cmd" "$OPENCODE_CONFIG_DIR/commands/$(basename "$cmd")"
	done
fi
