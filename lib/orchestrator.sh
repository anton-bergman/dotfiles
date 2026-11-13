#!/bin/bash
# ==============================================================================
# lib/orchestrator.sh - Subsystem Orchestrator & CLI Subroutines
# ==============================================================================

# --- Array & Target Utility Helpers ---
contains_element() {
	local match="$1"
	shift
	for e in "$@"; do
		[ "$e" = "$match" ] && return 0
	done
	return 1
}

resolve_targets() {
	local input="$1"
	local meta_val
	meta_val=$(get_meta_module "$input")
	if [ -n "$meta_val" ]; then
		echo "$meta_val"
	else
		echo "$input"
	fi
}

load_active_modules() {
	if [ -f "$DOTFILES_DIR/.active_modules" ]; then
		ACTIVE_MODULES=()
		while IFS= read -r line || [ -n "$line" ]; do
			[[ "$line" =~ ^[[:space:]]*# ]] && continue
			line=$(echo "$line" | xargs)
			[ -n "$line" ] && ACTIVE_MODULES+=("$line")
		done <"$DOTFILES_DIR/.active_modules"
	else
		ACTIVE_MODULES=("${DEFAULT_ACTIVE_MODULES[@]}")
	fi
}

# --- CLI Presentation Subroutines ---
show_help() {
	echo -e "${BOLD}dotfiles${NC} — personal development environment manager"
	echo ""
	echo -e "${BOLD}USAGE:${NC}"
	echo "    ./install.sh [OPTIONS] [COMMAND | MODULE | META-MODULE]"
	echo ""
	echo -e "${BOLD}COMMANDS:${NC}"
	echo "    (no args)             Provision base, core, and all active modules"
	echo "    <module>              Provision a single subsystem (e.g. nvim, tmux, zsh)"
	echo "    <meta-module>         Provision a group of subsystems (e.g. agents, terminal)"
	echo "    upgrade [target]      Cascade-upgrade target (or all tools across all managers)"
	echo "    list                  Display all atomic modules, active status, and meta-modules"
	echo ""
	echo -e "${BOLD}OPTIONS:${NC}"
	echo "    -v, --verbose         Stream raw sub-command stdout/stderr in real-time"
	echo "    -q, --quiet           Suppress non-error logs (show warnings and errors only)"
	echo "    -h, --help            Show this help documentation"
	echo ""
	echo -e "${BOLD}EXAMPLES:${NC}"
	echo "    ./install.sh                  # Setup full active workstation"
	echo "    ./install.sh nvim             # Setup only Neovim and its dependencies"
	echo "    ./install.sh agents           # Setup Pi, Claude, and OpenCode together"
	echo "    ./install.sh upgrade          # Upgrade all tools across Mise, Homebrew, and uv"
	echo "    ./install.sh upgrade nvim     # Upgrade only Neovim and its C-libraries"
	echo "    ./install.sh -v tmux          # Setup Tmux with verbose command streaming"
	exit 0
}

list_modules() {
	echo -e "${BOLD}=== Dotfiles Subsystem Registry ===${NC}\n"

	echo -e "${BOLD}Active Modules (Provisioned by default):${NC}"
	printf "  ${GREEN}+${NC} %-14s %s\n" "base" "$(get_module_description base)"
	printf "  ${GREEN}+${NC} %-14s %s\n" "core" "$(get_module_description core)"
	for mod in "${ACTIVE_MODULES[@]}"; do
		[ "$mod" = "base" ] || [ "$mod" = "core" ] && continue
		printf "  ${GREEN}+${NC} %-14s %s\n" "$mod" "$(get_module_description "$mod")"
	done

	echo -e "\n${BOLD}Dormant Modules (Available via ./install.sh <module>):${NC}"
	for mod in "${MODULES[@]}"; do
		[ "$mod" = "base" ] || [ "$mod" = "core" ] && continue
		if ! contains_element "$mod" "${ACTIVE_MODULES[@]}"; then
			printf "  ${YELLOW}-${NC} %-14s %s\n" "$mod" "$(get_module_description "$mod")"
		fi
	done

	echo -e "\n${BOLD}Meta-Modules (Composite Targets):${NC}"
	for meta in "${META_MODULE_KEYS[@]}"; do
		printf "  ${CYAN}@${NC} %-14s [%s]\n" "$meta" "$(get_meta_module "$meta")"
	done
	echo ""
	exit 0
}

# --- Foundation Synchronization ---
sync_base() {
	local start_time
	start_time=$(date +%s)
	log_module_start "base" "foundation"

	ensure_base_ready

	log_action "Resolving" "node, uv, python, bun, usage (mise)"
	run_task "Mise base tools" mise install node uv python bun usage

	if ! command_exists poetry; then
		log_action "Installing" "poetry (uv tool)"
		run_task "Install poetry via uv" uv tool install poetry
	else
		log_action "Verified" "poetry (already installed)"
	fi

	local end_time
	end_time=$(date +%s)
	log_module_done "base" "$((end_time - start_time))"
}

sync_core() {
	local start_time
	start_time=$(date +%s)
	log_module_start "core" "utilities"

	log_action "Resolving" "core CLI tools (mise)"
	run_task "Mise core tools" mise install fzf ripgrep lazygit fastfetch starship gh tlrc hunk github:pamburus/hl

	log_action "Resolving" "core host packages (packages.psv)"
	host_install_module "core"

	# Ensure visidata has data-science dependencies injected
	if command_exists vd || command_exists visidata; then
		log_action "Configuring" "visidata data-science plugins"
		run_task "Visidata plugins" uv tool install --with pandas,numpy,pyarrow,pytz visidata --force
	fi

	local end_time
	end_time=$(date +%s)
	log_module_done "core" "$((end_time - start_time))"
}

# --- Universal Module Sync Pipeline ---
sync_module() {
	local mod="$1"
	local start_time
	start_time=$(date +%s)

	log_module_start "$mod"

	# Step 1: Resolve Mise Tool
	local mise_tools
	mise_tools=$(get_mise_tools "$mod")
	if [ -n "$mise_tools" ]; then
		log_action "Resolving" "$mise_tools (mise)"
		for tool in $mise_tools; do
			run_task "Install $tool via mise" mise install "$tool"
		done
	fi

	# Step 2: Resolve Host Dependencies from packages.psv
	host_install_module "$mod"

	# Step 3: Run Subsystem Configuration Setup
	local setup_script=""
	if [ "$mod" = "python-lab" ] && [ -f "$DOTFILES_DIR/scripts/python/setup.sh" ]; then
		setup_script="$DOTFILES_DIR/scripts/python/setup.sh"
	elif [ -f "$DOTFILES_DIR/$mod/setup.sh" ]; then
		setup_script="$DOTFILES_DIR/$mod/setup.sh"
	fi

	if [ -n "$setup_script" ]; then
		run_task "Configure $mod" "$setup_script"
	fi

	local end_time
	end_time=$(date +%s)
	log_module_done "$mod" "$((end_time - start_time))"
}

# --- Cascade Upgrade Engine ---
upgrade_system() {
	local target="${1:-}"

	if [ -z "$target" ]; then
		log_header "Cascade Upgrade: All Systems"

		log_action "Upgrading" "Mise tools..."
		mise upgrade

		if [ "$IS_MAC" = true ]; then
			log_action "Upgrading" "Homebrew formulas & casks..."
			brew upgrade || true
		elif [ "$IS_LINUX" = true ]; then
			log_action "Upgrading" "Linux packages..."
			case "$DOTFILES_LINUX_PKG_MANAGER" in
			pacman) sudo pacman -Syu --noconfirm || true ;;
			apt) sudo apt update && sudo apt upgrade -y || true ;;
			esac
		fi

		if command_exists uv; then
			log_action "Upgrading" "Python tools via uv..."
			uv tool upgrade --all 2>/dev/null || true
		fi

		log_action "Updating" "Git submodules and plugins..."
		export DOTFILES_DO_UPGRADE=true
		sync_module "zsh"
		sync_module "tmux"

		log_header "System Upgrade Completed Successfully"
		exit 0
	fi

	# Target-specific upgrade
	local expanded_targets
	expanded_targets=$(resolve_targets "$target")

	for mod in $expanded_targets; do
		log_header "Upgrading Module: $mod"

		local mise_tools
		mise_tools=$(get_mise_tools "$mod")
		if [ -n "$mise_tools" ]; then
			log_action "Upgrading" "$mise_tools (mise)"
			for tool in $mise_tools; do
				mise upgrade "$tool" || true
			done
		fi

		host_upgrade_module "$mod"

		export DOTFILES_DO_UPGRADE=true
		sync_module "$mod"
	done

	log_header "Upgrade for '$target' Completed"
	exit 0
}
