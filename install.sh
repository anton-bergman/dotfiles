#!/bin/bash

# Exit immediately if any command fails
set -e

echo "Starting dotfiles installation..."

# Function to check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}


# ---------- Install packages ----------
echo -e "\nInstalling packages..."

# Install oh-my-posh
if ! command_exists oh-my-posh; then
    echo "Installing Oh-My-Posh..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install jandedobbeleer/oh-my-posh/oh-my-posh
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # linux
        curl -s https://ohmyposh.dev/install.sh | bash -s
    fi

else
    echo "Oh-My-Posh already installed."
fi

# Install Nerd Font (Hack font)
if ! fc-list | grep -i "Hack" >/dev/null; then
    echo "Installing Nerd Font Hack..."
    oh-my-posh font install Hack
else
    echo "Hack font already installed."
fi

# Install fastfetch — tool to show OS, hardware, and environment details in terminal
if ! command_exists fastfetch; then
    echo "Installing fastfetch..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install fastfetch
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # linux
		sudo apt-get update && sudo apt-get install -y fastfetch
    fi
else
    echo "fastfetch already installed."
fi

# ---------- Clone zsh plugins repositories ----------
echo -e "\nCloning zsh plugins..."
PLUGIN_DIR=~/dotfiles/zsh_plugins

if [ ! -d "$PLUGIN_DIR" ]; then
    # Create the zsh_plugins directory if it does not exist
    mkdir -p "$PLUGIN_DIR"
fi

# Clone zsh-autosuggestions plugin
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
    echo "Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGIN_DIR/zsh-autosuggestions"
else
    echo "zsh-autosuggestions already cloned."
fi

# Clone zsh-syntax-highlighting plugin
if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    echo "Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR/zsh-syntax-highlighting"
else
    echo "zsh-syntax-highlighting already cloned."
fi

# Clone zsh-completions plugin
if [ ! -d "$PLUGIN_DIR/zsh-completions" ]; then
    echo "Cloning zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions.git "$PLUGIN_DIR/zsh-completions"
else
    echo "zsh-completions already cloned."
fi


# ---------- Symlink dotfiles ----------
echo -e "\nSetting up dotfiles..."
DOTFILES_DIR="$HOME/dotfiles"

if [ ! -f "$HOME/.zshrc" ]; then
    # Create the .zshrc file if it does not exist
    touch "$HOME/.zshrc"
fi

# Add symbolic link for zsh config file
ln -sf "$DOTFILES_DIR/zshrc" "$HOME/.zshrc"

if [ ! -f "$HOME/.vimrc" ]; then
    # Create the .vimrc file if it does not exist
    touch "$HOME/.vimrc"
fi

# Add symbolic link for vim config file
ln -sf "$DOTFILES_DIR/vimrc" "$HOME/.vimrc"

echo "Dotfiles setup completed!"
