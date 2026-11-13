#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

# --- Install Extensions ---
VSCODE_EXT_FILE="$DOTFILES_DIR/vscode/vscode-extensions.txt"
if [ -f "$VSCODE_EXT_FILE" ] && command_exists code; then
	grep -vE '^\s*(#|$)' "$VSCODE_EXT_FILE" | xargs -n 1 code --install-extension 2>/dev/null || true
fi

# --- Symlink Settings ---
if [ "$IS_MAC" = true ]; then
	VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
else
	VSCODE_USER_DIR="$HOME/.config/Code/User"
fi

link_file "$DOTFILES_DIR/vscode/settings.jsonc" "$VSCODE_USER_DIR/settings.json"
