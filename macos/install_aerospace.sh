#!/usr/bin/env bash
set -euo pipefail

# Variables
AEROSPACE_CONFIG_SOURCE="$HOME/dotfiles/macos/aerospace/aerospace.toml"
AEROSPACE_CONFIG_TARGET_DIR="$HOME/.config/aerospace"
AEROSPACE_CONFIG_TARGET="$AEROSPACE_CONFIG_TARGET_DIR/aerospace.toml"

# Install AeroSpace
echo "Installing AeroSpace..."
brew install --cask nikitabobko/tap/aerospace

# Ensure AeroSpace config directory exists
echo "Creating AeroSpace config directory..."
mkdir -p "$AEROSPACE_CONFIG_TARGET_DIR"

# Backup existing AeroSpace config if it's not a symlink
if [ -e "$AEROSPACE_CONFIG_TARGET" ] && [ ! -L "$AEROSPACE_CONFIG_TARGET" ]; then
	echo "Backing up existing AeroSpace config..."
	mv "$AEROSPACE_CONFIG_TARGET" "$AEROSPACE_CONFIG_TARGET.bak"
fi

# Create symlink for AeroSpace config
echo "Linking custom AeroSpace config..."
ln -sf "$AEROSPACE_CONFIG_SOURCE" "$AEROSPACE_CONFIG_TARGET"

# Install JankyBorders
echo "Installing JankyBorders..."
brew tap FelixKratz/formulae
brew install borders

echo "AeroSpace and JankyBorders installation and config setup complete."
