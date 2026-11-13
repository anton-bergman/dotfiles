#!/bin/bash
# ==============================================================================
# lib/host_pkg.sh - Pluggable Host Package Adapter & Manifest Resolver
# ==============================================================================

# Default Linux package manager (override via DOTFILES_LINUX_PKG_MANAGER)
DOTFILES_LINUX_PKG_MANAGER="${DOTFILES_LINUX_PKG_MANAGER:-pacman}"

# --- Pre-Flight Validation with Interactive Bootstrap ---
ensure_prerequisites() {
	# 1. Check / Bootstrap Mise
	if ! command_exists mise; then
		if [ -t 0 ]; then
			echo -ne "${YELLOW}>> [NOTICE]${NC} Mise is required but not installed. Install mise automatically? [Y/n] "
			read -r answer
			answer=${answer:-Y}
			if [[ "$answer" =~ ^[Yy]$ ]]; then
				info "Installing Mise..."
				curl -fsSL https://mise.jdx.dev/install.sh | sh
				export PATH="$HOME/.local/bin:$PATH"
			else
				error "Mise is required. Install manually: curl https://mise.jdx.dev/install.sh | sh"
			fi
		else
			error "Missing prerequisite: mise (install: curl https://mise.jdx.dev/install.sh | sh)"
		fi
	fi

	# 2. Check / Bootstrap Homebrew on macOS
	if [ "$IS_MAC" = true ]; then
		if ! command_exists brew; then
			if [ -t 0 ]; then
				echo -ne "${YELLOW}>> [NOTICE]${NC} Homebrew is required on macOS. Install Homebrew automatically? [Y/n] "
				read -r answer
				answer=${answer:-Y}
				if [[ "$answer" =~ ^[Yy]$ ]]; then
					info "Installing Homebrew..."
					/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
					eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || true)"
				else
					error "Homebrew is required. Install manually: https://brew.sh"
				fi
			else
				error "Missing prerequisite: brew (install: https://brew.sh)"
			fi
		fi
	elif [ "$IS_LINUX" = true ]; then
		if ! command_exists "$DOTFILES_LINUX_PKG_MANAGER"; then
			error "Linux package manager '$DOTFILES_LINUX_PKG_MANAGER' not found."
		fi
	fi
}

# --- Existence Checking Helper ---
_check_package_installed() {
	local check_spec="$1"
	local provider="$2"
	local pkg="$3"

	local check_type=$(echo "$check_spec" | cut -d: -f1)
	local check_target=$(echo "$check_spec" | cut -d: -f2-)

	case "$check_type" in
	cmd)
		command_exists "$check_target"
		return $?
		;;
	font)
		font_installed "$check_target"
		return $?
		;;
	receipt)
		if [ "$IS_MAC" = true ]; then
			if [ "$provider" = "cask" ]; then
				brew list --cask "$pkg" &>/dev/null
			else
				brew list --formula "$pkg" &>/dev/null
			fi
			return $?
		elif [ "$IS_LINUX" = true ]; then
			case "$DOTFILES_LINUX_PKG_MANAGER" in
			pacman)
				pacman -Q "$pkg" &>/dev/null
				return $?
				;;
			apt)
				dpkg -s "$pkg" &>/dev/null
				return $?
				;;
			*)
				return 1
				;;
			esac
		fi
		return 1
		;;
	*)
		return 1
		;;
	esac
}

# --- Arch Linux Package Dispatcher ---
_install_arch_pkg() {
	local pkg="$1"
	local is_aur="${2:-false}"

	local helper=""
	if command_exists paru; then
		helper="paru"
	elif command_exists yay; then
		helper="yay"
	fi

	if [ "$is_aur" = true ]; then
		if [ -n "$helper" ]; then
			$helper -S --needed --noconfirm "$pkg"
		else
			error "Package '$pkg' requires an AUR helper (paru or yay), but neither was found."
		fi
	else
		if [ -n "$helper" ]; then
			$helper -S --needed --noconfirm "$pkg"
		else
			sudo pacman -S --needed --noconfirm "$pkg"
		fi
	fi
}

# --- Standalone Executable Downloader ---
install_binary_url() {
	local cmd="$1"
	local url="$2"
	local bin_dir="$HOME/.local/bin"

	if command_exists "$cmd"; then
		success "$cmd is already installed."
		return 0
	fi

	info "Downloading $cmd from $url..."
	mkdir -p "$bin_dir"

	if curl -fsSL "$url" -o "$bin_dir/$cmd"; then
		chmod +x "$bin_dir/$cmd"
		success "Installed $cmd to $bin_dir/$cmd"
	else
		error "Failed to download $cmd from $url"
	fi
}

# --- Manifest Package Resolver by ID ---
host_install_id() {
	local target_id="$1"
	local manifest="$HOME/dotfiles/packages.psv"

	if [ ! -f "$manifest" ]; then
		error "Manifest file not found: $manifest"
	fi

	local matched_line=""
	while IFS='|' read -r raw_id raw_mod raw_mac raw_linux raw_check raw_desc || [ -n "$raw_id" ]; do
		# Skip comments and empty lines
		[[ "$raw_id" =~ ^[[:space:]]*# ]] && continue
		[[ -z "$(echo "$raw_id" | xargs)" ]] && continue

		local clean_id=$(echo "$raw_id" | xargs)
		if [ "$clean_id" = "$target_id" ]; then
			matched_line="$raw_id|$raw_mod|$raw_mac|$raw_linux|$raw_check|$raw_desc"
			break
		fi
	done <"$manifest"

	if [ -z "$matched_line" ]; then
		error "Package ID '$target_id' not found in packages.psv"
	fi

	local mod_name=$(echo "$matched_line" | cut -d'|' -f2 | xargs)
	local macos_spec=$(echo "$matched_line" | cut -d'|' -f3 | xargs)
	local linux_spec=$(echo "$matched_line" | cut -d'|' -f4 | xargs)
	local check_spec=$(echo "$matched_line" | cut -d'|' -f5 | xargs)
	local desc=$(echo "$matched_line" | cut -d'|' -f6 | xargs)

	local spec="$macos_spec"
	if [ "$IS_LINUX" = true ]; then
		spec="$linux_spec"
	fi

	if [ "$spec" = "skip" ]; then
		log_action "Skipping" "$target_id (not applicable on this OS)"
		return 0
	fi

	local provider=$(echo "$spec" | cut -d: -f1)
	local pkg=$(echo "$spec" | cut -d: -f2-)

	# Check if already installed
	if _check_package_installed "$check_spec" "$provider" "$pkg"; then
		log_action "Verified" "$target_id ($provider: ok)"
		return 0
	fi

	log_action "Installing" "$target_id via $provider"

	local status=0
	case "$provider" in
	brew)
		brew install "$pkg" || status=1
		;;
	cask)
		brew install --cask "$pkg" || status=1
		;;
	pacman)
		_install_arch_pkg "$pkg" false || status=1
		;;
	aur)
		_install_arch_pkg "$pkg" true || status=1
		;;
	apt)
		sudo apt update && sudo apt install -y "$pkg" || status=1
		;;
	uv)
		uv tool install "$pkg" || status=1
		;;
	url)
		install_binary_url "$target_id" "$pkg" || status=1
		;;
	*)
		error "Unknown provider '$provider' for package ID '$target_id'"
		;;
	esac

	if [ $status -eq 0 ] && _check_package_installed "$check_spec" "$provider" "$pkg"; then
		log_action "Installed" "$target_id ($provider)"
	elif [ $status -eq 0 ]; then
		log_action "Installed" "$target_id ($provider)"
	else
		log_error "Failed to install $target_id via $provider"
		return 1
	fi
}

# --- Manifest Package Resolver by Module Tag ---
host_install_module() {
	local target_module="$1"
	local manifest="$HOME/dotfiles/packages.psv"

	[ -f "$manifest" ] || error "Manifest file not found: $manifest"

	local pkg_ids=()
	while IFS='|' read -r raw_id raw_mod raw_mac raw_linux raw_check raw_desc || [ -n "$raw_id" ]; do
		[[ "$raw_id" =~ ^[[:space:]]*# ]] && continue
		[[ -z "$(echo "$raw_id" | xargs)" ]] && continue

		local clean_id=$(echo "$raw_id" | xargs)
		local clean_mod=$(echo "$raw_mod" | xargs)

		if [ "$clean_mod" = "$target_module" ]; then
			pkg_ids+=("$clean_id")
		fi
	done <"$manifest"

	for pid in "${pkg_ids[@]}"; do
		host_install_id "$pid"
	done
}

# --- Module-Scoped Package Upgrades ---
host_upgrade_module() {
	local target_module="$1"
	local manifest="$HOME/dotfiles/packages.psv"

	[ -f "$manifest" ] || return 0

	local pkgs=()
	while IFS='|' read -r raw_id raw_mod raw_mac raw_linux raw_check raw_desc || [ -n "$raw_id" ]; do
		[[ "$raw_id" =~ ^[[:space:]]*# ]] && continue
		[[ -z "$(echo "$raw_id" | xargs)" ]] && continue

		local clean_mod=$(echo "$raw_mod" | xargs)
		if [ "$clean_mod" = "$target_module" ]; then
			local spec="$raw_mac"
			[ "$IS_LINUX" = true ] && spec="$raw_linux"
			local clean_spec=$(echo "$spec" | xargs)
			[ "$clean_spec" = "skip" ] && continue
			local pkg=$(echo "$clean_spec" | cut -d: -f2-)
			pkgs+=("$pkg")
		fi
	done <"$manifest"

	if [ ${#pkgs[@]} -gt 0 ]; then
		if [ "$IS_MAC" = true ]; then
			brew upgrade "${pkgs[@]}" 2>/dev/null || true
		elif [ "$IS_LINUX" = true ]; then
			case "$DOTFILES_LINUX_PKG_MANAGER" in
			pacman) sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || true ;;
			apt) sudo apt install --only-upgrade -y "${pkgs[@]}" 2>/dev/null || true ;;
			esac
		fi
	fi
}
