#!/bin/bash
# ==============================================================================
# lib/utils.sh - Core Utility Primitives & Execution Engine
# ==============================================================================

# --- Colors & Typography ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Runtime Flags ---
VERBOSE="${VERBOSE:-false}"
QUIET="${QUIET:-false}"
LOG_FILE="${LOG_FILE:-/tmp/dotfiles-install.log}"

# --- High-Craft Verb Logging ---
log_header() {
	[ "$QUIET" = false ] && echo -e "\n${BOLD}$1${NC}\n"
}

log_module_start() {
	local mod="$1"
	local note="$2"
	[ "$QUIET" = false ] && echo -e "\n${CYAN}→${NC} ${BOLD}${mod}${NC}${note:+ ($note)}"
}

log_action() {
	local verb="$1"
	local target="$2"
	[ "$QUIET" = false ] && printf "  ${CYAN}%-11s${NC} %s\n" "$verb" "$target"
}

log_module_done() {
	local mod="$1"
	local elapsed="$2"
	[ "$QUIET" = false ] && printf "  ${GREEN}%-11s${NC} %s in %ss\n" "Finished" "$mod" "$elapsed"
}

log_warn() {
	echo -e "  ${YELLOW}!${NC} $1"
}

log_error() {
	echo -e "  ${RED}Error:${NC} $1" >&2
}

# Legacy logging shims (for backward compatibility)
info() { [ "$QUIET" = false ] && echo -e "${BLUE}>> [INFO]${NC}    $1"; }
success() { [ "$QUIET" = false ] && echo -e "${GREEN}>> [SUCCESS]${NC} $1"; }
warn() { log_warn "$1"; }
error() {
	log_error "$1"
	exit 1
}
header() { log_header "$1"; }

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

# --- Task Execution Engine with Error Replay ---
run_task() {
	local label="$1"
	shift
	local tmp_out
	tmp_out=$(mktemp)

	mkdir -p "$(dirname "$LOG_FILE")"

	if [ "$VERBOSE" = true ]; then
		log_action "Executing" "$label"
		if "$@" 2>&1 | tee -a "$LOG_FILE"; then
			rm -f "$tmp_out"
			return 0
		else
			local status=${PIPESTATUS[0]}
			rm -f "$tmp_out"
			return $status
		fi
	else
		if "$@" >"$tmp_out" 2>&1; then
			cat "$tmp_out" >>"$LOG_FILE"
			rm -f "$tmp_out"
			return 0
		else
			local status=$?
			log_error "Command failed: $label (exit code $status)"
			echo "" >&2
			sed 's/^/  /' "$tmp_out" >&2
			echo "" >&2
			echo -e "  Log: $LOG_FILE" >&2
			cat "$tmp_out" >>"$LOG_FILE"
			rm -f "$tmp_out"
			return $status
		fi
	fi
}

# --- Font Utilities ---
font_installed() {
	local font_name=$1

	if [ "$IS_MAC" = true ]; then
		if mdfind "kMDItemKind == 'Font' && kMDItemFSName == '*${font_name}*'" 2>/dev/null | grep -q "."; then
			return 0
		fi
		find "$HOME/Library/Fonts" "/Library/Fonts" "/System/Library/Fonts" -iname "*${font_name}*" 2>/dev/null | grep -q "."
		return $?
	fi

	if [ "$IS_LINUX" = true ]; then
		if command_exists fc-list; then
			if fc-list | grep -iq "$font_name"; then
				return 0
			fi
		fi
		find "$HOME/.local/share/fonts" "$HOME/.fonts" "/usr/share/fonts" "/usr/local/share/fonts" -iname "*${font_name}*" 2>/dev/null | grep -q "."
		return $?
	fi
	return 1
}

# --- Smart Idempotent Symlink Engine ---
link_file() {
	local source="$1"
	local target="$2"

	# 1. Check if already correctly linked (true no-op to preserve mtime)
	if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
		return 0
	fi

	# 2. If it is an outdated or broken symlink, remove it cleanly
	if [ -L "$target" ]; then
		rm "$target"
	elif [ -e "$target" ]; then
		# Back up real files/directories
		local timestamp
		timestamp=$(date +%Y%m%d_%H%M%S)
		mv "$target" "${target}.bak_${timestamp}"
		log_warn "Backed up existing $(basename "$target") to ${target}.bak_${timestamp}"
	fi

	mkdir -p "$(dirname "$target")"
	ln -s "$source" "$target"
	log_action "Linking" "$target -> $source"
}

# --- Offline-First Git Plugin Manager ---
clone_or_pull() {
	local repo="$1"
	local target="$2"
	local branch="${3:-}"

	if [ ! -d "$target" ]; then
		log_action "Cloning" "$(basename "$target")"
		if [ -n "$branch" ]; then
			run_task "Clone $(basename "$target")" git clone --depth 1 -b "$branch" "$repo" "$target"
		else
			run_task "Clone $(basename "$target")" git clone --depth 1 "$repo" "$target"
		fi
	else
		# Only fetch over network during explicit upgrades
		if [ "${DOTFILES_DO_UPGRADE:-false}" = "true" ]; then
			log_action "Updating" "$(basename "$target")"
			(cd "$target" && git pull --ff-only 2>/dev/null || true)
		fi
	fi
}

# --- Environment Base Initializer ---
ensure_base_ready() {
	[ "${DOTFILES_BASE_READY:-0}" = "1" ] && return 0

	# 1. Assert package managers (interactive prompt if missing)
	ensure_prerequisites

	# 2. Ensure Mise config is linked & trusted
	mkdir -p "$HOME/.config/mise"
	link_file "$HOME/dotfiles/mise/config.toml" "$HOME/.config/mise/config.toml"
	mise trust "$HOME/.config/mise/config.toml" >/dev/null 2>&1 || true
	mise trust "$HOME/dotfiles/mise/config.toml" >/dev/null 2>&1 || true

	# 3. Activate shims in current subshell PATH
	eval "$(mise activate bash --shims 2>/dev/null || true)"

	export DOTFILES_BASE_READY=1
}
