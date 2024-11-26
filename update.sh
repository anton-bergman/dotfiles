#!/bin/bash

# Exit immediately if any command fails
set -e

echo "Starting dotfiles plugin update..."

# Function to check if a directory exists
dir_exists() {
    [ -d "$1" ]
}

# Update zsh plugins
PLUGIN_DIR=~/.dotfiles/zsh_plugins

# Update zsh-autosuggestions plugin
if dir_exists "$PLUGIN_DIR/zsh-autosuggestions"; then
    echo -e "\nUpdating zsh-autosuggestions..."
    cd "$PLUGIN_DIR/zsh-autosuggestions" && git pull origin master
else
    echo -e "\nzsh-autosuggestions plugin not found. Please run install.sh first."
fi

# Update zsh-syntax-highlighting plugin
if dir_exists "$PLUGIN_DIR/zsh-syntax-highlighting"; then
    echo -e "\nUpdating zsh-syntax-highlighting..."
    cd "$PLUGIN_DIR/zsh-syntax-highlighting" && git pull origin master
else
    echo -e "\nzsh-syntax-highlighting plugin not found. Please run install.sh first."
fi

# Update zsh-completions plugin
if dir_exists "$PLUGIN_DIR/zsh-completions"; then
    echo -e "\nUpdating zsh-completions..."
    cd "$PLUGIN_DIR/zsh-completions" && git pull origin master
else
    echo -e "\nzsh-completions plugin not found. Please run install.sh first."
fi

echo -e "\nPlugins update completed!"
