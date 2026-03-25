#!/bin/bash
set -e

# 1. Source the "Brain"
source "$(dirname "$0")/../lib/utils.sh"

# 2. Bootstrap
ensure_base_ready
header "SketchyBar Setup"

# Only run on macOS
if [ "$IS_MAC" = false ]; then
	warn "SketchyBar is only supported on macOS. Skipping."
	exit 0
fi

# 3. Install Dependencies
info "Installing dependencies..."
smart_install "lua:lua:brew"
smart_install "SwitchAudioSource:switchaudio-osx:brew"
smart_install "nowplaying-cli:nowplaying-cli:brew"
smart_install "sketchybar:FelixKratz/formulae/sketchybar:brew"

# 4. Fonts
info "Installing fonts..."
smart_install "sf-symbols:sf-symbols:cask"
smart_install "font-sf-mono:font-sf-mono:cask"
smart_install "font-sf-pro:font-sf-pro:cask"

if ! font_installed "sketchybar-app-font"; then
	info "Downloading sketchybar-app-font..."
	curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.5/sketchybar-app-font.ttf -o "$HOME/Library/Fonts/sketchybar-app-font.ttf"
fi

# 5. SbarLua
if [ ! -d "$HOME/.local/share/lua" ] || [ ! -f "$HOME/.local/share/lua/5.4/sketchybar.so" ]; then
	info "Installing SbarLua..."
	git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua
	(cd /tmp/SbarLua && make install)
	rm -rf /tmp/SbarLua
fi

# 6. Linking Configuration
info "Linking configuration..."
SKETCHYBAR_DOTFILES_DIR="$HOME/dotfiles/macos/sketchybar"
SKETCHYBAR_CONFIG_TARGET_DIR="$HOME/.config/sketchybar"

mkdir -p "$SKETCHYBAR_CONFIG_TARGET_DIR"

for item in "$SKETCHYBAR_DOTFILES_DIR"/*; do
	filename=$(basename "$item")
	[ "$filename" = "install.sh" ] && continue
	link_file "$item" "$SKETCHYBAR_CONFIG_TARGET_DIR/$filename"
done

# 7. Restart Service
info "Restarting SketchyBar..."
brew services restart sketchybar

success "SketchyBar setup completed!"
