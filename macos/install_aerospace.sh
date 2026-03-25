#!/bin/bash
set -e

# 1. Source the "Brain"
source "$(dirname "$0")/../lib/utils.sh"

# 2. Bootstrap
ensure_base_ready
header "AeroSpace & JankyBorders Setup"

# Only run on macOS
if [ "$IS_MAC" = false ]; then
	warn "AeroSpace is only supported on macOS. Skipping."
	exit 0
fi

# 3. Install AeroSpace
# Format: cmd:pkg:provider
smart_install "aerospace:nikitabobko/tap/aerospace:cask"

# 4. Install JankyBorders
smart_install "borders:FelixKratz/formulae/borders:brew"

# 5. Symlink Configuration
info "Linking configuration..."
link_file "$HOME/dotfiles/macos/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

success "AeroSpace and JankyBorders setup completed!"
