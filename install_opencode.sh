#!/bin/bash

# Exit immediately if any command fails
set -e

# ---------- Configuration ----------
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
OPENCODE_THEMES_DIR="$OPENCODE_CONFIG_DIR/themes"

# Track installation status for summary
INSTALLED_ITEMS=()
SKIPPED_ITEMS=()

# ---------- Helper Functions ----------

# Check if a command exists
command_exists() {
	command -v "$1" &>/dev/null
}

# Ensure a directory exists
ensure_directory() {
	local dir="$1"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
		echo "Created directory: $dir"
	fi
}

# Create a symlink with proper error handling
# Usage: create_symlink <source_file> <target_path> <description> [required]
create_symlink() {
	local source="$1"
	local target="$2"
	local description="$3"
	local required="${4:-false}"

	# Check if source file exists
	if [ ! -f "$source" ]; then
		if [ "$required" = true ]; then
			echo "ERROR: Required file not found: $source"
			exit 1
		else
			echo "⚠ Skipping $description (file not found: $source)"
			SKIPPED_ITEMS+=("$description")
			return 1
		fi
	fi

	# Ensure target directory exists
	local target_dir
	target_dir="$(dirname "$target")"
	ensure_directory "$target_dir"

	# Remove existing file or symlink
	if [ -e "$target" ] || [ -L "$target" ]; then
		rm -f "$target"
	fi

	# Create symlink
	ln -s "$source" "$target"
	echo "✓ Linked $description"
	INSTALLED_ITEMS+=("$description")
}

# ---------- Install OpenCode ----------
echo "Starting OpenCode installation..."
echo ""

if ! command_exists opencode; then
	echo "OpenCode not found. Installing..."
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# macOS - install via brew
		if ! command_exists brew; then
			echo "ERROR: Homebrew is not installed. Please install Homebrew first."
			echo "Visit: https://brew.sh"
			exit 1
		fi
		brew install opencode-ai/opencode/opencode
		echo "✓ Installed OpenCode"
		INSTALLED_ITEMS+=("OpenCode binary")
	else
		echo "ERROR: Unsupported OS: $OSTYPE"
		echo "Please install OpenCode manually from: https://opencode.ai"
		exit 1
	fi
else
	echo "✓ OpenCode is already installed"
fi

# ---------- Setup Configuration ----------
echo ""
echo "Setting up OpenCode configuration..."

# Create necessary directories
ensure_directory "$OPENCODE_CONFIG_DIR"
ensure_directory "$OPENCODE_THEMES_DIR"

# Symlink main config (required)
create_symlink \
	"$DOTFILES_DIR/opencode/opencode.json" \
	"$OPENCODE_CONFIG_DIR/opencode.json" \
	"opencode.json" \
	true

# Symlink theme (optional)
create_symlink \
	"$DOTFILES_DIR/opencode/my-theme.json" \
	"$OPENCODE_THEMES_DIR/my-theme.json" \
	"my-theme.json" \
	false

# ---------- Installation Summary ----------
echo ""

if [ ${#INSTALLED_ITEMS[@]} -gt 0 ]; then
	echo "✓ Successfully installed/configured:"
	for item in "${INSTALLED_ITEMS[@]}"; do
		echo "  - $item"
	done
fi

if [ ${#SKIPPED_ITEMS[@]} -gt 0 ]; then
	echo ""
	echo "⚠ Skipped items:"
	for item in "${SKIPPED_ITEMS[@]}"; do
		echo "  - $item"
	done
fi
