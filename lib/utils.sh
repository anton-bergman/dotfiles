#!/bin/bash

# --- Colors & Logging ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

info() { echo -e "${BLUE}>> [INFO]${NC}    $1"; }
success() { echo -e "${GREEN}>> [SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}>> [WARN]${NC}    $1"; }
error() {
	echo -e "${RED}>> [ERROR]${NC}   $1"
	exit 1
}
header() { echo -e "\n${MAGENTA}=== $1 ===${NC}\n"; }

# --- Environment Detection ---
OSTYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OSTYPE" in
darwin*)
	IS_MAC=true
	IS_LINUX=false
	;;
linux*)
	IS_MAC=false
	IS_LINUX=true
	;;
*)
	error "Unsupported OS: $OSTYPE"
	;;
esac

IS_WSL=false
if [ "$IS_LINUX" = true ] && grep -qEi "(Microsoft|WSL)" /proc/version 2>/dev/null; then
	IS_WSL=true
fi

ARCH=$(uname -m)

# Source pluggable host package manager adapter
source "$(dirname "${BASH_SOURCE[0]}")/host_pkg.sh"

# --- Command Check ---
command_exists() {
	command -v "$1" &>/dev/null
}

# --- Font Utilities ---

# Checks if a font is installed by searching system font directories and using OS tools.
# Usage: font_installed "FontName"
font_installed() {
	local font_name=$1

	# macOS logic
	if [ "$IS_MAC" = true ]; then
		# 1. Try native metadata (fastest)
		if mdfind "kMDItemKind == 'Font' && kMDItemFSName == '*${font_name}*'" 2>/dev/null | grep -q "."; then
			return 0
		fi
		# 2. Direct path recursive check (more reliable for new installs)
		# Search user fonts, system fonts, and network fonts
		find "$HOME/Library/Fonts" "/Library/Fonts" "/System/Library/Fonts" -iname "*${font_name}*" 2>/dev/null | grep -q "."
		return $?
	fi

	# Linux logic
	if [ "$IS_LINUX" = true ]; then
		# 1. Try fontconfig (if installed)
		if command_exists fc-list; then
			if fc-list | grep -iq "$font_name"; then
				return 0
			fi
		fi
		# 2. Direct path recursive check
		# Search common Linux font paths
		find "$HOME/.local/share/fonts" "$HOME/.fonts" "/usr/share/fonts" "/usr/local/share/fonts" -iname "*${font_name}*" 2>/dev/null | grep -q "."
		return $?
	fi
	return 1
}

# --- Python Utilities ---

# setup_python_venv <name> <packages>
# Creates a virtualenv in ~/.virtualenvs/<name> and installs the given packages.
setup_python_venv() {
	local name=$1
	local packages=$2
	local venv_dir="$HOME/.virtualenvs/$name"

	if [ ! -d "$venv_dir" ]; then
		info "Creating Python virtual environment at $venv_dir..."
		mkdir -p "$HOME/.virtualenvs"

		# Ensure we are using the mise-managed python or system python
		local python_cmd="python3"
		if command_exists mise; then
			python_cmd=$(mise which python3 2>/dev/null || echo "python3")
		fi

		"$python_cmd" -m venv "$venv_dir"
		source "$venv_dir/bin/activate"
		pip install --upgrade pip
		pip install $packages
		deactivate
		success "Python venv '$name' created and packages installed."
	else
		success "Python venv '$name' already exists."
	fi
}

# --- File & Git Utilities ---

# link_file <source> <target>
# Creates a symbolic link at <target> pointing to <source>.
#
# Backup Logic:
# - If <target> is a symbolic link: It is removed (not backed up) to avoid backup clutter.
# - If <target> is a real file or directory: It is backed up with a timestamped suffix.
link_file() {
	local source=$1
	local target=$2

	if [ -L "$target" ]; then
		rm "$target"
	elif [ -e "$target" ]; then
		local timestamp=$(date +%Y%m%d_%H%M%S)
		mv "$target" "${target}.bak_${timestamp}"
		warn "Backed up existing file $target to ${target}.bak_${timestamp}"
	fi

	mkdir -p "$(dirname "$target")"
	ln -s "$source" "$target"
	success "Linked $source to $target"
}

clone_or_pull() {
	local repo=$1
	local target=$2
	local branch=${3:-master}

	if [ ! -d "$target" ]; then
		info "Cloning $repo into $target..."
		git clone "$repo" "$target"
	else
		info "Updating $repo in $target..."
		(cd "$target" && git pull origin "$branch")
	fi
}

# --- Initializer ---
ensure_base_ready() {
	header "Initializing Environment"

	# 1. Assert required package managers are installed
	ensure_prerequisites

	# 2. Ensure Mise configuration is linked and trusted
	mkdir -p "$HOME/.config/mise"
	link_file "$HOME/dotfiles/mise/config.toml" "$HOME/.config/mise/config.toml"
	mise trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
	mise trust "$HOME/dotfiles/mise/config.toml" >/dev/null 2>&1 || true

	# 3. Ensure global tools from mise/config.toml are installed
	info "Ensuring global tools are installed via Mise..."
	mise install --yes

	# 4. Activate shims in current subshell PATH
	eval "$(mise activate bash --shims 2>/dev/null || true)"

	success "Base environment ready."
}
