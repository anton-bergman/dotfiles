#!/usr/bin/env zsh

# ============================================
# Tmux Project Session Management
# ============================================

# Create or attach to a tmux project session with pre-configured layout
# Usage: tn [-c|-o] [directory]
#   tn ~/projects/myapp     - Create/attach to session (default: opencode)
#   tn -c ~/projects/myapp  - Create/attach with Claude Code as assistant
#   tn -o ~/projects/myapp  - Create/attach with OpenCode as assistant
#   tn                      - Create/attach for current directory
tn() {
	local assistant="opencode"

	# Parse flags
	while [[ "$1" == -* ]]; do
		case "$1" in
		-c)
			assistant="claude"
			shift
			;;
		-o)
			assistant="opencode"
			shift
			;;
		*)
			echo "Unknown flag: $1 (use -c for Claude Code, -o for OpenCode)"
			return 1
			;;
		esac
	done

	local project_path="${1:-.}"

	# Resolve to absolute path and navigate to directory
	project_path=$(cd "$project_path" 2>/dev/null && pwd)
	if [[ -z "$project_path" ]]; then
		echo "Error: Directory does not exist: $1"
		return 1
	fi

	# Generate session name from directory basename
	# Replace dots and spaces with underscores for tmux compatibility
	local session_name=$(basename "$project_path" | tr '. ' '__')

	# Check if session already exists
	if tmux has-session -t "$session_name" 2>/dev/null; then
		echo "Session '$session_name' already exists. Attaching..."
		_tmux_attach "$session_name"
		return 0
	fi

	# Create new session
	echo "Creating new tmux session: $session_name (assistant: $assistant)"

	# 1. Create new session (detached) in project directory
	tmux new-session -d -s "$session_name" -c "$project_path"

	# 2. Window 1: "editor" - nvim | assistant split
	tmux rename-window -t "$session_name:1" "editor"

	# Launch nvim in the first pane
	tmux send-keys -t "$session_name:1.1" "nvim" C-m

	# Split window vertically (creates right pane)
	tmux split-window -h -t "$session_name:1" -c "$project_path"

	# Launch the selected assistant in the right pane
	tmux send-keys -t "$session_name:1.2" "$assistant" C-m

	# Set pane sizes: 70/30 split (nvim larger, assistant smaller)
	tmux resize-pane -t "$session_name:1.1" -x 70%

	# 3. Window 2: "terminal" - empty pane for running code/tests
	tmux new-window -t "$session_name:2" -n "terminal" -c "$project_path"

	# 4. Focus on the editor window (window 1)
	tmux select-window -t "$session_name:1"

	# 5. Attach to the session
	_tmux_attach "$session_name"
}

# Helper: Attach to tmux session (handles being inside/outside tmux)
_tmux_attach() {
	local session_name="$1"

	if [[ -n "$TMUX" ]]; then
		# Already inside tmux, switch to the session
		tmux switch-client -t "$session_name"
	else
		# Not in tmux, attach to the session
		tmux attach-session -t "$session_name"
	fi
}

# ============================================
# Python Data Tools
# ============================================

# Convert a pickle file to CSV using the Lab environment
# Usage: pkl2csv input.pkl [output.csv]
pkl2csv() {
	if [[ $# -lt 1 ]]; then
		echo "Usage: pkl2csv <input.pkl> [output.csv]"
		return 1
	fi

	# Self-healing: Ensure venv and symlink exist
	if [[ ! -d "$PY_LAB_PROJECT/.venv" ]]; then
		(cd "$HOME/dotfiles" && ./install_python_lab.sh)
	elif [[ ! -L "$PY_LAB_VENV" ]]; then
		mkdir -p "$(dirname "$PY_LAB_VENV")"
		ln -sfn "$PY_LAB_PROJECT/.venv" "$PY_LAB_VENV"
	fi

	local script_path="$HOME/dotfiles/scripts/python/pkl2csv.py"
	"$PY_LAB_VENV/bin/python" "$script_path" "$@"
}

# Convert a parquet file to CSV using the Lab environment
# Usage: parquet2csv input.parquet [output.csv]
parquet2csv() {
	if [[ $# -lt 1 ]]; then
		echo "Usage: parquet2csv <input.parquet> [output.csv]"
		return 1
	fi

	# Self-healing: Ensure venv and symlink exist
	if [[ ! -d "$PY_LAB_PROJECT/.venv" ]]; then
		(cd "$HOME/dotfiles" && ./install_python_lab.sh)
	elif [[ ! -L "$PY_LAB_VENV" ]]; then
		mkdir -p "$(dirname "$PY_LAB_VENV")"
		ln -sfn "$PY_LAB_PROJECT/.venv" "$PY_LAB_VENV"
	fi

	local script_path="$HOME/dotfiles/scripts/python/parquet2csv.py"
	"$PY_LAB_VENV/bin/python" "$script_path" "$@"
}
