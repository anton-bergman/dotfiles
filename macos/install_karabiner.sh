#!/bin/bash
set -e

# 1. Source the "Brain"
source "$(dirname "$0")/../lib/utils.sh"

# 2. Bootstrap
ensure_base_ready
header "Karabiner-Elements Setup"

# Only run on macOS
if [ "$IS_MAC" = false ]; then
	warn "Karabiner-Elements is only supported on macOS. Skipping."
	exit 0
fi

# 3. Install Karabiner-Elements
host_install_id "karabiner"

# 4. Symlink Configuration
info "Linking configuration..."
link_file "$HOME/dotfiles/macos/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"

success "Karabiner-Elements setup completed!"
