#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "OpenCode Setup"

# --- Install OpenCode binary ---
# Using the explicit tap spec: cmd:pkg:provider
# OpenCode is currently only supported on macOS via this script
smart_install "opencode:opencode-ai/opencode/opencode:brew"

# --- Setup Configuration ---
info "Setting up configuration files..."
DOTFILES_DIR="$HOME/dotfiles"
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_THEMES_DIR="$OPENCODE_CONFIG_DIR/themes"
OPENCODE_MCP_DIR="$OPENCODE_CONFIG_DIR/mcp"
OPENCODE_PLUGINS_DIR="$DOTFILES_DIR/opencode/plugins"

# --- Manage OpenCode Plugins ---
info "Managing OpenCode plugins..."
clone_or_pull "https://github.com/DietrichGebert/ponytail.git" "$OPENCODE_PLUGINS_DIR/ponytail" "main"

# Ensure directories exist
mkdir -p "$OPENCODE_THEMES_DIR"

# Ensure agents central directory is linked
link_file "$DOTFILES_DIR/agents" "$HOME/.config/agents"

# Remove existing config if it is a symlink or file to prevent writing through symlink
rm -f "$OPENCODE_CONFIG_DIR/opencode.json"

# Compile and write main configuration with merged MCPs
info "Generating merged opencode.json configuration..."
python3 - <<EOF
import json
import os

dotfiles_dir = os.path.expanduser("~/dotfiles")
opencode_config_dir = os.path.expanduser("~/.config/opencode")

# Load template config and strip comments
with open(os.path.join(dotfiles_dir, "opencode/opencode.json"), "r") as f:
    import re
    lines = f.readlines()
    clean_lines = []
    for line in lines:
        line = re.sub(r'(?<!:)\/\/.*', '', line)
        clean_lines.append(line)
    config = json.loads("".join(clean_lines))

# Load central MCP servers
with open(os.path.join(dotfiles_dir, "agents/mcp.json"), "r") as f:
    mcp_data = json.load(f)

# Translate mcpServers to OpenCode mcp format
opencode_mcp = {}
for name, mcp_server in mcp_data.get("mcpServers", {}).items():
    if mcp_server.get("type") == "remote":
        opencode_mcp[name] = {
            "type": "remote",
            "url": mcp_server.get("url"),
            "headers": mcp_server.get("headers", {}),
            "oauth": False,
            "enabled": True
        }
    else:
        opencode_mcp[name] = {
            "type": "local",
            "command": [mcp_server.get("command")] + mcp_server.get("args", []),
            "enabled": True
        }

config["mcp"] = opencode_mcp

# Write the final file
os.makedirs(opencode_config_dir, exist_ok=True)
with open(os.path.join(opencode_config_dir, "opencode.json"), "w") as f:
    json.dump(config, f, indent=2)
EOF

# Link theme
link_file "$DOTFILES_DIR/opencode/my-theme.json" "$OPENCODE_THEMES_DIR/my-theme.json"

# Link plugins directory
link_file "$DOTFILES_DIR/opencode/plugins" "$OPENCODE_CONFIG_DIR/plugins"

# Link Ponytail custom commands to global user commands
link_file "$DOTFILES_DIR/opencode/plugins/ponytail/.opencode/command" "$OPENCODE_CONFIG_DIR/commands"

# Link Ponytail configuration
link_file "$DOTFILES_DIR/opencode/ponytail/config.json" "$HOME/.config/ponytail/config.json"

success "OpenCode setup completed!"
