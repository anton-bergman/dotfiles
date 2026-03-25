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

# --- Command Check ---
command_exists() {
	command -v "$1" &>/dev/null
}

# --- Provider Implementation ---

_install_with_brew() {
	brew install "$1"
}

_install_with_cask() {
	if [ "$IS_MAC" = true ]; then
		brew install --cask "$1"
	else
		warn "Casks are only supported on macOS. Skipping $1."
		return 1
	fi
}

_install_with_mise() {
	if command_exists mise; then
		mise use -g "$1"
	else
		return 1
	fi
}

_install_with_apt() {
	if command_exists apt; then
		sudo apt update && sudo apt install -y "$1"
	else
		return 1
	fi
}

_install_with_uv() {
	if command_exists uv; then
		uv tool install "$1"
	else
		return 1
	fi
}

# --- Repository Management ---

# add_apt_repo <ppa_path>
# Example: add_apt_repo "ppa:neovim-ppa/stable"
add_apt_repo() {
	local ppa=$1
	if [ "$IS_LINUX" = true ] && command_exists apt; then
		# Ensure add-apt-repository is installed (handled by ensure_base_ready, but good for safety)
		if ! command_exists add-apt-repository; then
			sudo apt update && sudo apt install -y software-properties-common
		fi

		# Check if repo is already added to avoid redundant updates
		if ! grep -q "$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
			info "Adding APT repository: $ppa"
			sudo add-apt-repository -y "$ppa"
			sudo apt update
		else
			info "APT repository $ppa already exists. Skipping."
		fi
	fi
}

# add_apt_key <key_url> <keyring_name>
# Example: add_apt_key "https://packages.microsoft.com/keys/microsoft.asc" "microsoft.gpg"
add_apt_key() {
	local url=$1
	local name=$2
	if [ "$IS_LINUX" = true ] && command_exists apt; then
		if [ ! -f "/usr/share/keyrings/$name" ]; then
			info "Adding GPG key: $name"
			curl -fsSL "$url" | gpg --dearmor | sudo tee "/usr/share/keyrings/$name" >/dev/null
		else
			info "GPG key $name already exists. Skipping."
		fi
	fi
}

# add_apt_source <name> <source_line>
# Example: add_apt_source "vscode" "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
add_apt_source() {
	local name=$1
	local line=$2
	if [ "$IS_LINUX" = true ] && command_exists apt; then
		if [ ! -f "/etc/apt/sources.list.d/$name.list" ]; then
			info "Adding APT source: $name"
			echo "$line" | sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
			sudo apt update
		else
			info "APT source $name already exists. Skipping."
		fi
	fi
}

# --- Smart Install Function ---

# Internal helper to parse and execute a spec
# Format: cmd:pkg:provider
_execute_smart_install() {
	local spec="$1"

	# Parse using awk for robustness across bash versions
	local cmd=$(echo "$spec" | awk -F: '{print $1}')
	local pkg=$(echo "$spec" | awk -F: '{print $2}')
	local provider=$(echo "$spec" | awk -F: '{print $3}')

	if [ -z "$cmd" ] || [ -z "$pkg" ] || [ -z "$provider" ]; then
		error "Invalid spec format: '$spec'. Expected 'cmd:pkg:provider'"
	fi

	if command_exists "$cmd"; then
		success "$cmd is already installed."
		return 0
	fi

	info "Installing $pkg via $provider (expecting cmd: $cmd)..."

	local status=0
	case "$provider" in
	brew) _install_with_brew "$pkg" || status=1 ;;
	cask) _install_with_cask "$pkg" || status=1 ;;
	mise) _install_with_mise "$pkg" || status=1 ;;
	apt) _install_with_apt "$pkg" || status=1 ;;
	uv) _install_with_uv "$pkg" "$extras" || status=1 ;;
	*) error "Unknown provider: $provider in spec '$spec'" ;;
	esac

	if [ $status -eq 0 ] && command_exists "$cmd"; then
		success "Successfully installed $pkg"
	else
		error "Failed to install $pkg via $provider. Command '$cmd' not found."
	fi
}

# Usage: smart_install "cmd:pkg:provider" ["linux_cmd:linux_pkg:linux_provider"]
smart_install() {
	local spec="$1"

	# Use second argument if we are on Linux/WSL and it was provided
	if [ "$IS_LINUX" = true ] && [ -n "$2" ]; then
		spec="$2"
	fi

	_execute_smart_install "$spec"
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

	# Linux Core Bootstrap
	if [ "$IS_LINUX" = true ] && command_exists apt; then
		info "Ensuring Linux core dependencies..."
		if ! command_exists gpg || ! command_exists wget || ! command_exists add-apt-repository; then
			sudo apt update
			sudo apt install -y apt-transport-https ca-certificates curl gnupg wget software-properties-common
		fi
	fi

	# Install Homebrew if missing
	if ! command_exists brew; then
		info "Homebrew not found. Installing..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		if [ "$IS_MAC" = true ]; then
			eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)"
		else
			eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
		fi
		success "Homebrew installation completed!"
	fi

	# Install Mise if missing
	if ! command_exists mise; then
		info "Mise not found. Installing..."
		curl https://mise.jdx.dev/install.sh | sh
		# Setup path
		export PATH="$HOME/.local/bin:$PATH"

		info "Linking Mise configuration..."
		mkdir -p "$HOME/.config/mise"
		link_file "$HOME/dotfiles/mise/config.toml" "$HOME/.config/mise/config.toml"
		mise trust "$HOME/.config/mise/config.toml"
		mise trust "$HOME/dotfiles/mise/config.toml"
		eval "$(mise activate bash --shims)"

		info "Ensuring global tools are installed (Node, Python, etc.)..."
		mise install --yes
		mise exec uv -- uv tool install poetry
		poetry config virtualenvs.in-project true
		success "Mise setup completed!"
	fi

	success "Base environment ready."
}
