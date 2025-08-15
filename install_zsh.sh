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

# ---------- Clone zsh plugins repositories ----------
echo -e "\nCloning zsh plugins..."
PLUGIN_DIR=~/dotfiles/zsh/plugins

if [ ! -d "$PLUGIN_DIR" ]; then
    # Create the zsh/plugins directory if it does not exist
    mkdir -p "$PLUGIN_DIR"
fi

# Clone zsh-autosuggestions plugin
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
    echo -e "\nCloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$PLUGIN_DIR/zsh-autosuggestions"
else
    echo -e "\nzsh-autosuggestions already cloned. Updating zsh-autosuggestions..."
    cd "$PLUGIN_DIR/zsh-autosuggestions" && git pull origin master
fi

# Clone zsh-syntax-highlighting plugin
if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    echo -e "\nCloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_DIR/zsh-syntax-highlighting"
else
    echo -e "\nzsh-syntax-highlighting already cloned. Updating zsh-syntax-highlighting..."
    cd "$PLUGIN_DIR/zsh-syntax-highlighting" && git pull origin master
fi

# Clone zsh-completions plugin
if [ ! -d "$PLUGIN_DIR/zsh-completions" ]; then
    echo -e "\nCloning zsh-completions..."
    git clone https://github.com/zsh-users/zsh-completions.git "$PLUGIN_DIR/zsh-completions"
else
    echo -e "\nzsh-completions already cloned. Updating zsh-completions..."
    cd "$PLUGIN_DIR/zsh-completions" && git pull origin master
fi


# ---------- Symlink dotfiles ----------
echo -e "\nSetting up dotfiles..."
DOTFILES_DIR="$HOME/dotfiles"

if [ ! -f "$HOME/.zshrc" ]; then
    # Create the .zshrc file if it does not exist
    touch "$HOME/.zshrc"
fi

# Add symbolic link for zsh config file
ln -sf "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

if [ ! -f "$HOME/.vimrc" ]; then
    # Create the .vimrc file if it does not exist
    touch "$HOME/.vimrc"
fi

# Add symbolic link for vim config file
ln -sf "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"

echo "Dotfiles setup completed!"
