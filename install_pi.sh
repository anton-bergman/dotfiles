#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "Pi Setup"

# --- Install Pi CLI binary ---
# Using the Homebrew formula from homebrew-core: pi-coding-agent
smart_install "pi:pi-coding-agent:brew"

# --- Setup Configuration ---
info "Setting up configuration files..."
DOTFILES_DIR="$HOME/dotfiles"
PI_CONFIG_DIR="$HOME/.pi/agent"
PI_EXTENSIONS_DIR="$PI_CONFIG_DIR/extensions"
PI_PROMPTS_DIR="$PI_CONFIG_DIR/prompts"

# Ensure directories exist
mkdir -p "$PI_CONFIG_DIR"
mkdir -p "$PI_EXTENSIONS_DIR"
mkdir -p "$PI_PROMPTS_DIR"

# Ensure agents central directory is linked
link_file "$DOTFILES_DIR/agents" "$HOME/.config/agents"

# Ensure local guidelines exist
if [ ! -f "$DOTFILES_DIR/agents/GUIDELINES.local.md" ]; then
	info "Creating agents/GUIDELINES.local.md from example..."
	cp "$DOTFILES_DIR/agents/GUIDELINES.local.example" "$DOTFILES_DIR/agents/GUIDELINES.local.md"
fi

# Compile global AGENTS.md for Pi
info "Compiling global AGENTS.md for Pi..."
rm -f "$PI_CONFIG_DIR/AGENTS.md"
cat "$DOTFILES_DIR/agents/GUIDELINES.md" "$DOTFILES_DIR/agents/GUIDELINES.local.md" > "$PI_CONFIG_DIR/AGENTS.md"

# Link all root Pi configuration files (*.json, *.yaml, *.yml)
info "Linking Pi root configuration files..."
for cfg in "$DOTFILES_DIR/pi"/*.json "$DOTFILES_DIR/pi"/*.yaml "$DOTFILES_DIR/pi"/*.yml; do
	[ -e "$cfg" ] || continue
	filename=$(basename "$cfg")

	# Exclude permissions.json as it has its own target path in extensions
	[ "$filename" = "permissions.json" ] && continue

	link_file "$cfg" "$PI_CONFIG_DIR/$filename"
done

# Compile Pi-compatible mcp.json (removes client-specific keys like 'type')
info "Generating Pi-compatible mcp.json..."
rm -f "$PI_CONFIG_DIR/mcp.json"
python3 - <<EOF
import json
import os

dotfiles_dir = os.path.expanduser("~/dotfiles")
pi_config_dir = os.path.expanduser("~/.pi/agent")

with open(os.path.join(dotfiles_dir, "agents/mcp.json"), "r") as f:
    data = json.load(f)

clean_servers = {}
for name, server in data.get("mcpServers", {}).items():
    s = dict(server)
    s.pop("type", None)
    clean_servers[name] = s

with open(os.path.join(pi_config_dir, "mcp.json"), "w") as f:
    json.dump({"mcpServers": clean_servers}, f, indent=2)
EOF

# Link permissions configuration
info "Linking Pi permissions..."
rm -f "$PI_EXTENSIONS_DIR/guardrails.ts"

mkdir -p "$PI_EXTENSIONS_DIR/pi-permission-system"
link_file "$DOTFILES_DIR/pi/permissions.json" "$PI_EXTENSIONS_DIR/pi-permission-system/config.json"

# Reconcile declared Pi packages dynamically from settings.json (Bidirectional Sync)
info "Reconciling declared Pi packages from settings.json..."
python3 - << 'EOF'
import json
import os
import subprocess

def extract_pkg_name(spec: str) -> str:
    # Handles "npm:@scope/name@version", "npm:name@version", "@scope/name", "name"
    clean = spec
    if clean.startswith("npm:"):
        clean = clean[4:]
    if clean.startswith("@"):
        parts = clean.split("@")
        # parts[0] is "", parts[1] is "scope/name", optional parts[2] is "version"
        return f"@{parts[1]}"
    return clean.split("@")[0]

settings_path = os.path.expanduser("~/dotfiles/pi/settings.json")
npm_pkg_path = os.path.expanduser("~/.pi/agent/npm/package.json")

try:
    with open(settings_path) as f:
        data = json.load(f)
    declared_packages = data.get("packages", [])
    declared_names = {extract_pkg_name(p) for p in declared_packages}

    # 1. Prune orphaned packages not present in settings.json
    if os.path.exists(npm_pkg_path):
        try:
            with open(npm_pkg_path) as f:
                npm_data = json.load(f)
            installed_deps = npm_data.get("dependencies", {})
            for installed in installed_deps.keys():
                if installed not in declared_names:
                    print(f"Pruning undeclared package: npm:{installed}")
                    subprocess.run(["pi", "remove", f"npm:{installed}"], check=False)
        except Exception as err:
            print(f"Notice: Could not inspect installed npm dependencies: {err}")

    # 2. Ensure all external npm packages are installed
    external_pkgs = [p for p in declared_packages if p.startswith("npm:") or p.startswith("git:")]
    if external_pkgs:
        print(f"Reconciling declared packages: {', '.join(external_pkgs)}")
        for pkg in external_pkgs:
            subprocess.run(["pi", "install", pkg], check=True)
    else:
        print("No external npm packages to install.")
except Exception as e:
    print(f"Warning: Failed to reconcile packages: {e}")
EOF

# Link skills directory from central hub
link_file "$DOTFILES_DIR/agents/skills" "$PI_CONFIG_DIR/skills"

# Link Agnostic Commands to Pi prompts
info "Linking Agnostic Commands as Pi prompts..."
for cmd in "$DOTFILES_DIR/agents/commands"/*.md; do
	[ -e "$cmd" ] && link_file "$cmd" "$PI_PROMPTS_DIR/$(basename "$cmd")"
done

success "Pi setup completed!"
