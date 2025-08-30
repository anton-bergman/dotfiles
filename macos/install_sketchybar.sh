#!/usr/bin/env bash
set -euo pipefail

# Variables
SKETCHYBAR_DOTFILES_DIR="$HOME/dotfiles/macos/sketchybar"
SKETCHYBAR_CONFIG_SOURCE="$HOME/dotfiles/macos/sketchybar/sketchybarrc"
SKETCHYBAR_PLUGINS_SOURCE_DIR="$HOME/dotfiles/macos/sketchybar/plugins"
SKETCHYBAR_CONFIG_TARGET_DIR="$HOME/.config/sketchybar"
SKETCHYBAR_CONFIG_TARGET="$HOME/.config/sketchybar/sketchybarrc"
SKETCHYBAR_PLUGINS_TARGET_DIR="$HOME/.config/sketchybar/plugins"


# Packages
echo "Installing Dependencies"
brew install lua
brew install switchaudio-osx
brew install nowplaying-cli

# Install SketchyBar
echo "Installing SketchyBar..."
brew tap FelixKratz/formulae
brew install sketchybar

# Fonts
brew install --cask sf-symbols
brew install --cask font-sf-mono
brew install --cask font-sf-pro

curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.5/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf

# SbarLua
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)

# Clone SketchyBar Theme fron FelixKratz's dotfiles
# echo "Cloning Config"
# git clone https://github.com/FelixKratz/dotfiles.git /tmp/dotfiles
# mv /tmp/dotfiles/.config/sketchybar $SKETCHYBAR_DOTFILES_DIR
# rm -rf /tmp/dotfiles

# Ensure config directory exists
echo "Creating SketchyBar config directory..."
mkdir -p "$SKETCHYBAR_CONFIG_TARGET_DIR"

# Create symlinks
EXCLUDE_FILE="install.sh"  # Do not create a symlink for install.sh
for item in "$SKETCHYBAR_DOTFILES_DIR"/*; do
    filename=$(basename "$item")
    if [[ "$filename" == "$EXCLUDE_FILE" ]]; then
        continue
    fi
    ln -sfn "$item" "$SKETCHYBAR_CONFIG_TARGET_DIR/$filename"
done

brew services restart sketchybar
echo "SketchyBar installation and config setup complete."
