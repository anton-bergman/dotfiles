#!/bin/bash

# Exit immediately if any command fails
set -e

echo "Starting Tmux installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}


# ---------- Install packages ----------
echo -e "\nInstalling packages..."

# Install Tmux
if ! command_exists tmux; then
    echo "Installing Tmux..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install tmux
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt update && sudo apt install -y tmux
    fi
else
    echo "Tmux is already installed."
fi

# Install Tmux Plugin Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm"
else
    echo "Tmux Plugin Manager (TPM) is already installed."
fi


# ---------- Symlink dotfiles ----------
echo -e "\nSetting up dotfiles..."

# Ensure ~/.config directory exists
if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
fi

# Remove ~/.config/tmux if it exists (to prevent nesting issues)
if [ -e "$HOME/.config/tmux" ] || [ -L "$HOME/.config/tmux" ]; then
    rm -rf "$HOME/.config/tmux"
fi

# Add a symbolic link between ~/dotfiles/tmux and ~/.config/tmux
ln -s "$HOME/dotfiles/tmux" "$HOME/.config/tmux"

echo "Tmux setup completed!"

