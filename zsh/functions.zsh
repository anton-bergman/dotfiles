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

# ============================================
# Sleep Prevention (Caffeinate)
# ============================================

# Prevent macOS from sleeping for a specific process (attach to already running)
# Usage: caf [keyword]
caf() {
	# Guard to ensure we are running on macOS
	if [[ "$(uname)" != "Darwin" ]]; then
		echo "Error: caf is a macOS-only utility (requires caffeinate)." >&2
		return 1
	fi

	local keyword=""
	if [[ "$1" == "-h" || "$1" == "--help" ]]; then
		echo "Usage: caf [keyword]"
		echo ""
		echo "Prevent macOS from sleeping while background processes are running."
		echo ""
		echo "Examples:"
		echo "  caf                 Interactive fuzzy-search (fzf) of all your processes"
		echo "  caf opencode        Prevent sleep while opencode build runs"
		return 0
	else
		keyword="$1"
	fi

	# Determine terminal dimensions and calculate column safety budget
	local cols=${COLUMNS:-80}
	local max_w=$((cols - 5))
	[[ $max_w -lt 40 ]] && max_w=40 # Floor budget for extremely narrow windows

	local pid_w=7
	# CWD gets 40% of total max_w, bounded between 25 and 50 characters
	local cwd_w=$((max_w * 4 / 10))
	[[ $cwd_w -lt 25 ]] && cwd_w=25
	[[ $cwd_w -gt 50 ]] && cwd_w=50

	# Command gets the remaining width
	local cmd_w=$((max_w - pid_w - cwd_w - 6)) # 6 accounts for separators: " | " and " | "
	[[ $cmd_w -lt 15 ]] && cmd_w=15

	# Retrieve user processes and match with CWD using awk
	local formatted_matches
	formatted_matches=$(awk \
		-v current_shell_pid="$$" \
		-v home_dir="$HOME" \
		-v keyword="$keyword" \
		-v pid_w="$pid_w" \
		-v cwd_w="$cwd_w" \
		-v cmd_w="$cmd_w" '
		NR == 1 { next }
		NR == FNR {
			if ($1 ~ /^p/) {
				current_pid = substr($1, 2)
			} else if ($1 ~ /^n/) {
				cwd_array[current_pid] = substr($0, 2)
			}
			next
		}
		FNR == 1 { next }
		$1 == current_shell_pid { next }
		$0 ~ /ps -U/ || $0 ~ /awk/ || $0 ~ /grep/ || $0 ~ /fzf/ || $0 ~ /caffeinate/ || $0 ~ /caf([[:space:]]|$)/ { next }
		keyword != "" && tolower($0) !~ tolower(keyword) { next }
		{
			pid = $1
			$1 = ""
			sub(/^[ \t]+/, "", $0)
			cmd = $0
			cwd = cwd_array[pid]

			# 1. Format CWD (Left Truncation)
			if (cwd == "") {
				cwd_display = "-"
			} else if (cwd == "/") {
				cwd_display = "/"
			} else {
				if (index(cwd, home_dir) == 1) {
					cwd = "~" substr(cwd, length(home_dir) + 1)
				}
				if (length(cwd) > cwd_w) {
					cwd_display = "..." substr(cwd, length(cwd) - cwd_w + 4)
				} else {
					cwd_display = cwd
				}
			}

			# 2. Format Command (Right Truncation)
			if (length(cmd) > cmd_w) {
				cmd_display = substr(cmd, 1, cmd_w - 3) "..."
			} else {
				cmd_display = cmd
			}

			# 3. Print aligned record
			fmt = "%-" pid_w "s | %-" cwd_w "s | %-" cmd_w "s\n"
			printf fmt, pid, cwd_display, cmd_display
		}
	' <(lsof -u "$USER" -a -d cwd -Fn 2>/dev/null) <(ps -U "$USER" -o pid,command))

	if [[ -z "$formatted_matches" ]]; then
		if [[ -n "$keyword" ]]; then
			echo "Error: No matching processes found for '$keyword'." >&2
		else
			echo "Error: No user processes found." >&2
		fi
		return 1
	fi

	local match_count=$(echo "$formatted_matches" | grep -c '^')
	local selection=""

	if [[ "$match_count" -eq 1 && -n "$keyword" ]]; then
		selection="$formatted_matches"
	else
		if command -v fzf >/dev/null 2>&1; then
			selection=$(echo "$formatted_matches" | fzf --header "Select a process to caffeinate (Ctrl+C to cancel):" --height 40% --layout=reverse --no-hscroll)
			if [[ -z "$selection" ]]; then
				echo "Aborted."
				return 0
			fi
		else
			echo "Select a process to prevent sleep:"
			echo "$formatted_matches" | awk '{print NR ") " $0}'
			printf "Enter number (1-%d, or 'q' to quit): " "$match_count"
			read -r choice
			if [[ "$choice" == "q" || -z "$choice" ]]; then
				echo "Aborted."
				return 0
			fi
			if ! [[ "$choice" -eq "$choice" ]] 2>/dev/null || [[ "$choice" -lt 1 || "$choice" -gt "$match_count" ]]; then
				echo "Error: Invalid selection." >&2
				return 1
			fi
			selection=$(echo "$formatted_matches" | sed -n "${choice}p")
		fi
	fi

	# Extract selection PID
	local target_pid=$(echo "$selection" | awk '{print $1}')

	# Fetch single pristine command & exact CWD for final confirmation
	local target_cmd=$(ps -p "$target_pid" -o command=)
	local target_cwd=$(lsof -p "$target_pid" -a -d cwd -Fn 2>/dev/null | awk '/^n/ {print substr($0, 2)}')
	local target_cwd_abbr="${target_cwd/#$HOME/~}"
	[[ -z "$target_cwd_abbr" ]] && target_cwd_abbr="-"

	echo "============================================="
	echo "Sleep assertion activated for process:"
	echo "  PID:     $target_pid"
	echo "  CWD:     $target_cwd_abbr"
	echo "  Command: $target_cmd"
	echo "============================================="
	echo "Preventing sleep. Press Ctrl+C to stop caffeinating."

	caffeinate -i -w "$target_pid"
}
