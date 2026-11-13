#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

PI_CONFIG_DIR="$HOME/.pi/agent"
PI_EXTENSIONS_DIR="$PI_CONFIG_DIR/extensions"
PI_PROMPTS_DIR="$PI_CONFIG_DIR/prompts"

mkdir -p "$PI_CONFIG_DIR"
mkdir -p "$PI_EXTENSIONS_DIR"
mkdir -p "$PI_PROMPTS_DIR"

# Ensure agents central directory is linked
link_file "$DOTFILES_DIR/agents" "$HOME/.config/agents"

# Compile global AGENTS.md for Pi (truly optional local guidelines)
rm -f "$PI_CONFIG_DIR/AGENTS.md"
if [ -f "$DOTFILES_DIR/agents/GUIDELINES.local.md" ]; then
	cat "$DOTFILES_DIR/agents/GUIDELINES.md" "$DOTFILES_DIR/agents/GUIDELINES.local.md" >"$PI_CONFIG_DIR/AGENTS.md"
else
	cp "$DOTFILES_DIR/agents/GUIDELINES.md" "$PI_CONFIG_DIR/AGENTS.md"
fi

# Link root Pi configuration files (*.json, *.yaml, *.yml)
for cfg in "$DOTFILES_DIR/pi"/*.json "$DOTFILES_DIR/pi"/*.yaml "$DOTFILES_DIR/pi"/*.yml; do
	[ -e "$cfg" ] || continue
	link_file "$cfg" "$PI_CONFIG_DIR/$(basename "$cfg")"
done

# Compile Pi-compatible mcp.json (removes client-specific keys like 'type')
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

# Link extension-scoped configurations
rm -f "$PI_EXTENSIONS_DIR/guardrails.ts"
if [ -d "$DOTFILES_DIR/pi/extensions" ]; then
	for ext_dir in "$DOTFILES_DIR/pi/extensions"/*; do
		[ -d "$ext_dir" ] || continue
		ext_name=$(basename "$ext_dir")
		mkdir -p "$PI_EXTENSIONS_DIR/$ext_name"
		for cfg in "$ext_dir"/*; do
			[ -e "$cfg" ] || continue
			link_file "$cfg" "$PI_EXTENSIONS_DIR/$ext_name/$(basename "$cfg")"
		done
	done
fi

# Reconcile declared Pi packages from settings.json
python3 - <<'EOF'
import json
import os
import subprocess

def extract_pkg_name(spec: str) -> str:
    clean = spec
    if clean.startswith("npm:"):
        clean = clean[4:]
    if clean.startswith("@"):
        parts = clean.split("@")
        return f"@{parts[1]}"
    return clean.split("@")[0]

settings_path = os.path.expanduser("~/dotfiles/pi/settings.json")
npm_pkg_path = os.path.expanduser("~/.pi/agent/npm/package.json")

try:
    if os.path.exists(settings_path):
        with open(settings_path) as f:
            data = json.load(f)
        declared_packages = data.get("packages", [])
        declared_names = {extract_pkg_name(p) for p in declared_packages}

        if os.path.exists(npm_pkg_path):
            try:
                with open(npm_pkg_path) as f:
                    npm_data = json.load(f)
                installed_deps = npm_data.get("dependencies", {})
                for installed in installed_deps.keys():
                    if installed not in declared_names:
                        subprocess.run(["pi", "remove", f"npm:{installed}"], check=False)
            except Exception:
                pass

        external_pkgs = [p for p in declared_packages if p.startswith("npm:") or p.startswith("git:")]
        for pkg in external_pkgs:
            subprocess.run(["pi", "install", pkg], check=False)
except Exception:
    pass
EOF

# Link skills directory
link_file "$DOTFILES_DIR/agents/skills" "$PI_CONFIG_DIR/skills"

# Link Agnostic Commands to Pi prompts
if [ -d "$DOTFILES_DIR/agents/commands" ]; then
	for cmd in "$DOTFILES_DIR/agents/commands"/*.md; do
		[ -e "$cmd" ] && link_file "$cmd" "$PI_PROMPTS_DIR/$(basename "$cmd")"
	done
fi
