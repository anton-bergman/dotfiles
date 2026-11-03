#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "CLI Tools Setup"

# Host-specific CLI tools
host_install_id "btop"
host_install_id "fastfetch"

# VisiData terminal data explorer (with data science libraries injected)
host_install_id "visidata"
if command_exists vd || command_exists visidata; then
	uv tool install --with pandas,numpy,pyarrow,pytz visidata --force
fi

success "CLI tools setup completed!"
