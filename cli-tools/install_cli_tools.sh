#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$(dirname "$0")/../lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "CLI Tools Setup"

# 3. Install Tools
# Format: cmd:pkg:provider
smart_install "fastfetch:fastfetch:brew" "fastfetch:fastfetch:apt"
smart_install "tldr:tlrc:brew" "tldr:tlrc:apt"

# TODO: These tools are dependencies of neovim and used for some neovim plugins
# Investigate if that should be handled in some separate way and if so then how
smart_install "lazygit:lazygit:brew" "lazygit:lazygit:apt"

smart_install "vd:visidata:uv"
if command_exists visidata; then
	# To support specific data formats (like Pickles) we inject these libraries
	# into VisiData's private virtualenv.
	uv tool install --with pandas,numpy,pytz visidata --force
fi

success "CLI tools setup completed!"
