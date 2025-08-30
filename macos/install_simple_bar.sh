#!/usr/bin/env bash
set -euo pipefail

# Variables
UEBERSICHT_WIDGETS_DIR="$HOME/Library/Application Support/Übersicht/widgets"
SIMPLEBAR_WIDGET_SOURCE="$HOME/dotfiles/macos/simple-bar/simplebarrc"
SIMPLEBAR_WIDGET_TARGET="$HOME/.simplebarrc"
SIMPLEBAR_REPO_DIR="$UEBERSICHT_WIDGETS_DIR/simple-bar"
SIMPLEBAR_REPO_URL="https://github.com/Jean-Tinland/simple-bar"

# Install Übersicht
echo "Installing Übersicht..."
brew install --cask ubersicht

# Ensure Übersicht widgets directory exists
echo -e "\nCreating Übersicht widgets directory..."
mkdir -p "$UEBERSICHT_WIDGETS_DIR"

# Clone or update the simple-bar repo
if [ -d "$SIMPLEBAR_REPO_DIR/.git" ]; then
    echo "simple-bar repo already exists. Pulling latest changes..."
    git -C "$SIMPLEBAR_REPO_DIR" pull
else
    echo "Cloning simple-bar repo..."
    git clone "$SIMPLEBAR_REPO_URL" "$SIMPLEBAR_REPO_DIR"
fi

# Create symlink for Simple-Bar config
echo -e "\nLinking custom Simple-Bar config..."
ln -sf "$SIMPLEBAR_WIDGET_SOURCE" "$SIMPLEBAR_WIDGET_TARGET"

echo -e "\nSimple-Bar installation and config setup complete."
