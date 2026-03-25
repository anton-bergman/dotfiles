#!/bin/bash
set -e

# 1. Source the "Brain"
source "$(dirname "$0")/../lib/utils.sh"

# 2. Bootstrap
ensure_base_ready
header "Simple-Bar Setup"

# Only run on macOS
if [ "$IS_MAC" = false ]; then
	warn "Simple-Bar is only supported on macOS. Skipping."
	exit 0
fi

# 3. Install Übersicht
smart_install "ubersicht:ubersicht:cask"

# 4. Clone or update Simple-Bar
UEBERSICHT_WIDGETS_DIR="$HOME/Library/Application Support/Übersicht/widgets"
mkdir -p "$UEBERSICHT_WIDGETS_DIR"

clone_or_pull "https://github.com/Jean-Tinland/simple-bar" "$UEBERSICHT_WIDGETS_DIR/simple-bar"

# 5. Link configuration
link_file "$HOME/dotfiles/macos/simple-bar/simplebarrc" "$HOME/.simplebarrc"

success "Simple-Bar setup completed!"
