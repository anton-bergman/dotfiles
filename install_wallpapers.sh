#!/bin/bash

# Exit immediately if any command fails
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

header "Wallpaper Installation"

# --- Configuration ---
DOTFILES_DIR="$HOME/dotfiles"
WALLPAPERS_DIR="$DOTFILES_DIR/wallpapers"

# Wallpaper definitions (name, URL, description)
declare -a WALLPAPERS=(
	"wallhaven-d8386j.png|https://w.wallhaven.cc/full/d8/wallhaven-d8386j.png|Sylvain Sarrailh - Space Rocket (5156x2160)"
)

# Download wallpaper with validation
download_wallpaper() {
	local filename="$1"
	local url="$2"
	local description="$3"
	local target_path="$WALLPAPERS_DIR/$filename"

	# Check if already exists
	if [ -f "$target_path" ]; then
		success "Skipping $filename (already exists)"
		return 0
	fi

	info "Downloading $description..."

	# Download with curl
	if curl -L -o "$target_path" "$url" 2>/dev/null; then
		# Validate it's actually an image
		if file "$target_path" | grep -qE 'image|PNG|JPEG'; then
			success "Successfully downloaded $description"
		else
			warn "Failed: $filename is not a valid image"
			rm -f "$target_path"
			return 1
		fi
	else
		warn "Failed to download $description"
		return 1
	fi
}

# --- Main Installation ---
# Ensure wallpapers directory exists
mkdir -p "$WALLPAPERS_DIR"

# Download all wallpapers
for wallpaper_entry in "${WALLPAPERS[@]}"; do
	IFS='|' read -r filename url description <<<"$wallpaper_entry"
	download_wallpaper "$filename" "$url" "$description"
done

success "Wallpaper setup completed!"
info "Wallpapers are located at: $WALLPAPERS_DIR"
