#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

# Ensure brew/mise are ready
ensure_base_ready

header "Python Lab Setup"

LAB_DIR="$HOME/dotfiles/scripts/python"
VENV_DIR="$HOME/.virtualenvs"
LAB_VENV="$LAB_DIR/.venv"

# --- Initialize Environment ---
info "Building Python Lab virtual environment..."
mkdir -p "$VENV_DIR"

# Ensure we use a clean environment for building
if [ -d "$LAB_VENV" ]; then
	rm -rf "$LAB_VENV"
fi

# Find the python binary (prefer mise)
PYTHON_BIN=$(command -v python3)
if command -v mise >/dev/null 2>&1; then
	PYTHON_BIN=$(mise which python3 2>/dev/null || echo "$PYTHON_BIN")
fi

info "Using Python at: $PYTHON_BIN"
"$PYTHON_BIN" -m venv "$LAB_VENV"

# Install packages
info "Installing core lab dependencies..."
"$LAB_VENV/bin/pip" install --upgrade pip
"$LAB_VENV/bin/pip" install -r "$LAB_DIR/requirements.txt"

# --- Symlink Environment ---
info "Linking lab environment..."
link_file "$LAB_VENV" "$VENV_DIR/lab"

success "Python Lab setup completed!"
