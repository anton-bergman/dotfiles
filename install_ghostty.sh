#!/bin/bash

# Exit immediately if any command fails
set -e

echo "Starting Ghostty installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# ---------- Install Ghostty ----------
if ! command_exists ghostty; then
    echo "Ghostty not found. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - install via brew
        if ! command_exists brew; then
            echo "Homebrew is not installed. Please install Homebrew first."
            exit 1
        fi
        brew install ghostty
    else
        echo "Unsupported OS: $OSTYPE. Cannot install Ghostty automatically."
        exit 1
    fi
else
    echo "Ghostty is already installed."
fi

# ---------- Symlink config ----------
echo -e "\nSetting up Ghostty config symlink..."

GHOSTTY_CONFIG_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
DOTFILES_GHOSTTY_CONFIG="$HOME/dotfiles/ghostty/config.toml"

mkdir -p "$GHOSTTY_CONFIG_DIR"

if [ -f "$DOTFILES_GHOSTTY_CONFIG" ]; then
    ln -sf "$DOTFILES_GHOSTTY_CONFIG" "$GHOSTTY_CONFIG_DIR/config"
    echo "Symlinked config.toml to $GHOSTTY_CONFIG_DIR/config.toml"
else
    echo "No config.toml found at $DOTFILES_GHOSTTY_CONFIG. Skipping config symlink."
fi

echo "Ghostty setup completed!"
