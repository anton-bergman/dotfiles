#!/bin/bash

# Exit immediately if any command fails
set -e

# ---------- Configuration ----------
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
WALLPAPERS_DIR="$DOTFILES_DIR/wallpapers"

# Wallpaper definitions (name, URL, description)
declare -a WALLPAPERS=(
	"wallhaven-d8386j.png|https://w.wallhaven.cc/full/d8/wallhaven-d8386j.png|Sylvain Sarrailh - Space Rocket (5156x2160)"
)

# Track download status
DOWNLOADED_ITEMS=()
SKIPPED_ITEMS=()
FAILED_ITEMS=()

# ---------- Helper Functions ----------

# Ensure directory exists
ensure_directory() {
	local dir="$1"
	if [ ! -d "$dir" ]; then
		mkdir -p "$dir"
		echo "Created directory: $dir"
	fi
}

# Download wallpaper with validation
download_wallpaper() {
	local filename="$1"
	local url="$2"
	local description="$3"
	local target_path="$WALLPAPERS_DIR/$filename"

	# Check if already exists
	if [ -f "$target_path" ]; then
		echo "⚠ Skipping $filename (already exists)"
		SKIPPED_ITEMS+=("$description")
		return 0
	fi

	# Download with curl
	if curl -L -o "$target_path" "$url" 2>/dev/null; then
		# Validate it's actually an image
		if file "$target_path" | grep -qE 'image|PNG|JPEG'; then
			echo "✓ Downloaded $description"
			DOWNLOADED_ITEMS+=("$description")
		else
			echo "✗ Failed: $filename is not a valid image"
			rm -f "$target_path"
			FAILED_ITEMS+=("$description (invalid file)")
			return 1
		fi
	else
		echo "✗ Failed to download $description"
		FAILED_ITEMS+=("$description (download failed)")
		return 1
	fi
}

# ---------- Main Installation ----------
# Ensure wallpapers directory exists
ensure_directory "$WALLPAPERS_DIR"

# Download all wallpapers
echo "Downloading wallpapers..."
echo ""

for wallpaper_entry in "${WALLPAPERS[@]}"; do
	IFS='|' read -r filename url description <<<"$wallpaper_entry"
	download_wallpaper "$filename" "$url" "$description"
done

echo ""
echo "Wallpapers are located at: $WALLPAPERS_DIR"
