#!/bin/bash
set -e

# Source utility functions
source "$HOME/dotfiles/lib/utils.sh"

MANIFEST_FILE="$(dirname "$0")/apps.manifest"

# --- Help Banner ---
show_help() {
	cat <<EOF
Usage: ./macos/install_apps.sh [OPTIONS]

Batch installer for macOS applications defined in macos/apps.manifest.

Options:
  -h, --help                Show this help message and exit
  -l, --list                List all manifest packages and installation status
  -e, --exclude <pkg,...>   Exclude package(s) (comma or space separated)
  -o, --only <pkg,...>      Install only specified package(s)

Examples:
  ./macos/install_apps.sh
  ./macos/install_apps.sh --exclude spotify,google-chrome
  ./macos/install_apps.sh -e spotify -e google-chrome
  ./macos/install_apps.sh --only raycast
EOF
}

# --- State Inspection Helper ---
is_installed() {
	local id="$1"
	local pkg="$2"
	local provider="$3"

	if [ "$provider" = "cask" ]; then
		brew list --cask "$pkg" &>/dev/null || command_exists "$id"
	else
		brew list --formula "$pkg" &>/dev/null || command_exists "$id"
	fi
}

# --- Item Matcher Helper ---
list_contains() {
	local needle="$1"
	shift
	for item in "$@"; do
		if [ "$item" = "$needle" ]; then
			return 0
		fi
	done
	return 1
}

# --- Parse CLI Arguments ---
EXCLUDE_LIST=()
ONLY_LIST=()
LIST_MODE=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	-h | --help)
		show_help
		exit 0
		;;
	-l | --list)
		LIST_MODE=true
		shift
		;;
	-e | --exclude)
		if [ -z "$2" ] || [[ "$2" == -* ]]; then
			error "--exclude requires at least one package name"
		fi
		# Split comma-separated values into array
		IFS=',' read -ra ADDR <<<"$2"
		for item in "${ADDR[@]}"; do
			clean_item=$(echo "$item" | xargs)
			[ -n "$clean_item" ] && EXCLUDE_LIST+=("$clean_item")
		done
		shift 2
		;;
	-o | --only)
		if [ -z "$2" ] || [[ "$2" == -* ]]; then
			error "--only requires at least one package name"
		fi
		# Split comma-separated values into array
		IFS=',' read -ra ADDR <<<"$2"
		for item in "${ADDR[@]}"; do
			clean_item=$(echo "$item" | xargs)
			[ -n "$clean_item" ] && ONLY_LIST+=("$clean_item")
		done
		shift 2
		;;
	*)
		error "Unknown option: $1 (run with --help for usage)"
		;;
	esac
done

# Ensure Homebrew and base environment are ready
ensure_base_ready

# Guard OS
if [ "$IS_MAC" = false ]; then
	warn "macOS applications manifest is only supported on macOS. Skipping."
	exit 0
fi

if [ ! -f "$MANIFEST_FILE" ]; then
	error "Manifest file not found: $MANIFEST_FILE"
fi

# --- List Mode ---
if [ "$LIST_MODE" = true ]; then
	header "macOS Applications Manifest"
	printf "%-20s %-15s %-10s %s\n" "PACKAGE ID" "STATUS" "TYPE" "DESCRIPTION"
	printf "%-20s %-15s %-10s %s\n" "----------" "------" "----" "-----------"

	while IFS='|' read -r raw_id raw_pkg raw_provider raw_desc || [ -n "$raw_id" ]; do
		id=$(echo "$raw_id" | xargs)
		pkg=$(echo "$raw_pkg" | xargs)
		provider=$(echo "$raw_provider" | xargs)
		desc=$(echo "$raw_desc" | xargs)

		[[ -z "$id" || "$id" =~ ^# ]] && continue

		if is_installed "$id" "$pkg" "$provider"; then
			status_color="$GREEN"
			status_label="installed"
		else
			status_color="$YELLOW"
			status_label="missing"
		fi

		printf "%-20s ${status_color}%-15s${NC} %-10s %s\n" "$id" "$status_label" "$provider" "$desc"
	done <"$MANIFEST_FILE"
	echo ""
	exit 0
fi

# --- Execution Mode ---
header "macOS Applications Setup"

if [ ${#EXCLUDE_LIST[@]} -gt 0 ]; then
	info "Excluding packages: ${EXCLUDE_LIST[*]}"
fi
if [ ${#ONLY_LIST[@]} -gt 0 ]; then
	info "Targeting only: ${ONLY_LIST[*]}"
fi

FAILED_ITEMS=()

while IFS='|' read -r raw_id raw_pkg raw_provider raw_desc || [ -n "$raw_id" ]; do
	id=$(echo "$raw_id" | xargs)
	pkg=$(echo "$raw_pkg" | xargs)
	provider=$(echo "$raw_provider" | xargs)
	desc=$(echo "$raw_desc" | xargs)

	# Skip empty lines and comments
	[[ -z "$id" || "$id" =~ ^# ]] && continue

	# Check exclusion filter
	if list_contains "$id" "${EXCLUDE_LIST[@]}"; then
		warn "Skipping $id (excluded via CLI)"
		continue
	fi

	# Check only filter
	if [ ${#ONLY_LIST[@]} -gt 0 ] && ! list_contains "$id" "${ONLY_LIST[@]}"; then
		continue
	fi

	# Idempotence check
	if is_installed "$id" "$pkg" "$provider"; then
		success "$id ($pkg) is already installed."
		continue
	fi

	info "Installing $id ($pkg) via $provider..."

	install_status=0
	if [ "$provider" = "cask" ]; then
		brew install --cask "$pkg" || install_status=1
	else
		brew install "$pkg" || install_status=1
	fi

	if [ $install_status -ne 0 ]; then
		warn "Failed to install $id ($pkg)"
		FAILED_ITEMS+=("$id")
	else
		success "Installed $id ($pkg)"
	fi
done <"$MANIFEST_FILE"

# --- Summary ---
echo ""
if [ ${#FAILED_ITEMS[@]} -gt 0 ]; then
	warn "Batch installation finished with errors."
	echo -e "${RED}The following packages failed to install:${NC}"
	for item in "${FAILED_ITEMS[@]}"; do
		echo "  - $item"
	done
	exit 1
else
	success "All specified macOS applications are installed!"
fi
