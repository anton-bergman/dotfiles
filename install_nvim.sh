#!/bin/bash

# Exit immediately if any command fails
set -e

echo "Starting Neovim installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}


# ---------- Install packages ----------
echo -e "\nInstalling packages..."

# Install Neovim
if ! command_exists nvim; then
    echo "Installing Neovim..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install neovim
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # linux
        sudo apt update && sudo apt install -y neovim
    fi

else
    echo "Neovim is already installed."
fi

# Install Luarocks
# A package manager for Lua required by Lazy.nvim
if ! command_exists luarocks; then
    echo "Installing Luarocks..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install luarocks
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt update && sudo apt install -y luarocks
    fi
else
    echo "Luarocks is already installed."
fi

# Install ripgrep
# A fast search tool required by Neovim Telescope plugin for live grep functionality
if ! command_exists rg; then
    echo "Installing ripgrep..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install ripgrep
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt update && sudo apt install -y ripgrep
    fi
else
    echo "ripgrep is already installed."
fi


# Install nvm (Node Version Manager) and Node.js
# Required for LSP servers and other tools
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing nvm and Node.js..."
		echo "Don't forget to add the following lines to your ~/.zshrc or ~/.bashrc:"
		echo ''
		echo 'export NVM_DIR="$HOME/.nvm"'
		echo '[ -s "$NVM_DIR/nvm.sh" ] && \."$NVM_DIR/nvm.sh"  # This loads nvm'

    # Download and run the nvm installation script
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    # Source nvm to use it in the current script session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install the latest LTS version of Node.js and set it as default
    nvm install --lts
    nvm alias default 'lts/*'
    nvm use default
else
		if ! command_exists nvm; then 
			echo "nvm is installed but NOT sourced in your current shell."
			echo "To fix this, add the following lines to your ~/.zshrc or ~/.bashrc:"
			echo ''
			echo 'export NVM_DIR="$HOME/.nvm"'
			echo '[ -s "$NVM_DIR/nvm.sh" ] && \."$NVM_DIR/nvm.sh"  # This loads nvm'
		else
			echo "nvm is already installed."
		fi
fi


# ---------- Symlink dotfiles ----------
echo -e "\nSetting up dotfiles..."

# Ensure ~/.config directory exists
if [ ! -d "$HOME/.config" ]; then
    mkdir -p "$HOME/.config"
fi

# Remove ~/.config/nvim if it exists (to prevent nesting issues)
if [ -e "$HOME/.config/nvim" ] || [ -L "$HOME/.config/nvim" ]; then
    rm -rf "$HOME/.config/nvim"
fi

# Add a symbolic link between ~/dotfiles/nvim and ~/.config/nvim
ln -s "$HOME/dotfiles/nvim" "$HOME/.config/nvim"

echo "Neovim setup completed!"