#!/bin/bash
# ==============================================================================
# install.sh - Authoritative Dotfiles Orchestrator & CLI Runner
# ==============================================================================

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
source "$DOTFILES_DIR/lib/orchestrator.sh"

# --- 1. Module Registries ---
MODULES=(
	base
	core
	zsh
	tmux
	nvim
	ghostty
	fnox
	pi
	claude
	opencode
	vscode
	macos
	wallpapers
	python-lab
)

DEFAULT_ACTIVE_MODULES=(
	zsh
	tmux
	nvim
	ghostty
	fnox
	pi
	claude
	opencode
)

META_MODULE_KEYS=(
	agents
	terminal
	editors
	desktop
)

# --- 2. Module Metadata & Mappings ---
get_meta_module() {
	case "$1" in
	agents) echo "pi claude opencode" ;;
	terminal) echo "zsh tmux ghostty" ;;
	editors) echo "nvim vscode" ;;
	desktop) echo "ghostty macos wallpapers" ;;
	*) echo "" ;;
	esac
}

get_mise_tools() {
	case "$1" in
	base) echo "node uv python bun usage" ;;
	core) echo "fzf ripgrep lazygit fastfetch starship gh tlrc hunk github:pamburus/hl" ;;
	nvim) echo "neovim" ;;
	tmux) echo "tmux" ;;
	fnox) echo "fnox" ;;
	pi) echo "npm:@earendil-works/pi-coding-agent" ;;
	claude) echo "claude" ;;
	opencode) echo "opencode" ;;
	*) echo "" ;;
	esac
}

get_module_description() {
	case "$1" in
	base) echo "Foundation language runtimes & engines (node, python, uv, bun, poetry)" ;;
	core) echo "Universal CLI utilities (fzf, rg, lazygit, btop, fastfetch, fnox, vd)" ;;
	zsh) echo "Shell environment, plugins, starship prompt & gitconfig" ;;
	tmux) echo "Terminal multiplexer, TPM plugins & safe copy daemon" ;;
	nvim) echo "Neovim editor, LSPs & configuration" ;;
	ghostty) echo "GPU terminal emulator & configuration" ;;
	fnox) echo "Secret injection & credential daemon" ;;
	pi) echo "Pi coding agent, local packages & MCP manifests" ;;
	claude) echo "Claude Code assistant, guidelines & MCP manifests" ;;
	opencode) echo "OpenCode assistant, themes & MCP manifests" ;;
	vscode) echo "Visual Studio Code editor & extensions sync" ;;
	macos) echo "AeroSpace window manager, JankyBorders & Karabiner" ;;
	python-lab) echo "Persistent data analytics environment (~/.virtualenvs/lab)" ;;
	wallpapers) echo "Desktop wallpaper downloader" ;;
	*) echo "" ;;
	esac
}

# --- 3. Main Runner ---
main() {
	load_active_modules

	local positional_args=()
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-v | --verbose)
			VERBOSE=true
			shift
			;;
		-q | --quiet)
			QUIET=true
			shift
			;;
		-h | --help)
			show_help
			;;
		list)
			list_modules
			;;
		upgrade)
			shift
			upgrade_system "${1:-}"
			;;
		-*)
			log_error "Unknown option: $1"
			echo "Run './install.sh --help' for usage."
			exit 1
			;;
		*)
			positional_args+=("$1")
			shift
			;;
		esac
	done

	local start_time
	start_time=$(date +%s)

	if [ ${#positional_args[@]} -eq 0 ]; then
		# Full Machine Run: Module-by-Module
		log_header "Dotfiles Provisioning (${#ACTIVE_MODULES[@]} active modules)"

		# 1. Foundation: base & core fail-fast
		sync_base
		sync_core

		# 2. Sequential Module Execution with Error Collection
		local failed_modules=()
		for mod in "${ACTIVE_MODULES[@]}"; do
			[ "$mod" = "base" ] || [ "$mod" = "core" ] && continue
			if ! sync_module "$mod"; then
				failed_modules+=("$mod")
			fi
		done

		local total_elapsed=$(( $(date +%s) - start_time ))

		if [ ${#failed_modules[@]} -eq 0 ]; then
			log_header "Finished: All active modules synchronized in ${total_elapsed}s"
		else
			echo -e "\n${RED}${BOLD}Completed with errors in ${total_elapsed}s:${NC}"
			for fm in "${failed_modules[@]}"; do
				echo -e "  - ${RED}$fm${NC}"
			done
			echo -e "Check $LOG_FILE for details."
			exit 1
		fi
	else
		# Targeted Run (Single Module or Meta-Module)
		local target="${positional_args[0]}"
		local expanded_targets
		expanded_targets=$(resolve_targets "$target")

		for mod in $expanded_targets; do
			if [ "$mod" = "base" ]; then
				sync_base
			elif [ "$mod" = "core" ]; then
				sync_core
			else
				ensure_base_ready
				sync_module "$mod"
			fi
		done

		local total_elapsed=$(( $(date +%s) - start_time ))
		log_header "Target '$target' synchronized in ${total_elapsed}s"
	fi
}

main "$@"
