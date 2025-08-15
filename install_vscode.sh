#!/bin/bash

# Exit immediately if any command fails
set -e

echo "Starting VS Code installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}


# ---------- Install VS Code ----------
if ! command_exists code; then
    echo "Installing VS Code..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install --cask visual-studio-code
	else
        echo "Unsupported OS: $OSTYPE. Cannot install VS Code automatically."
        exit 1
    fi
else
    echo "VS Code is already installed."
fi


# ---------- Install extensions ----------
echo -e "\nInstalling VS Code extensions..."

VSCODE_EXT_FILE="$HOME/dotfiles/vscode/vscode-extensions.txt"

if [ -f "$VSCODE_EXT_FILE" ]; then
	# Install all VS Code extensions from the list, ignoring empty lines and lines starting with #
	grep -vE '^\s*(#|$)' "$VSCODE_EXT_FILE" | xargs -n 1 code --install-extension
else
    echo "No vscode-extensions.txt file found at $VSCODE_EXT_FILE. Skipping extension installation."
fi


# ---------- Symlink settings ----------
echo -e "\nSetting up VS Code settings..."

# Detect VS Code user settings directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    VSCODE_USER_DIR="$HOME/.config/Code/User"
else
    echo "Unsupported OS type: $OSTYPE. Cannot link VS Code settings."
    exit 1
fi

mkdir -p "$VSCODE_USER_DIR"

# Link settings.json
if [ -f "$HOME/dotfiles/vscode/settings.jsonc" ]; then
    ln -sf "$HOME/dotfiles/vscode/settings.jsonc" "$VSCODE_USER_DIR/settings.json"
else
    echo "settings.jsonc not found in ~/dotfiles/vscode. Skipping settings link."
fi

echo "VS Code setup completed!"
