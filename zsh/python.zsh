# Persistent Python Lab Environment
# Managed in ~/dotfiles/scripts/python
export PY_LAB_PROJECT="$HOME/dotfiles/scripts/python"
export PY_LAB_VENV="$HOME/.virtualenvs/lab"

# Smart Python command
py() {
	# Self-healing: Ensure venv and symlink exist
	if [[ ! -d "$PY_LAB_PROJECT/.venv" ]]; then
		echo "Lab environment not found. Building..."
		(cd "$HOME/dotfiles" && ./install_python_lab.sh)
	elif [[ ! -L "$PY_LAB_VENV" ]]; then
		mkdir -p "$(dirname "$PY_LAB_VENV")"
		ln -sfn "$PY_LAB_PROJECT/.venv" "$PY_LAB_VENV"
	fi

	if [[ $# -eq 0 ]]; then
		# Launch IPython for a better interactive shell
		"$PY_LAB_VENV/bin/ipython"
	else
		# Run script or command with the lab environment
		"$PY_LAB_VENV/bin/python" "$@"
	fi
}

# Quick add to lab environment
# Usage: py-add requests
py-add() {
	if [[ ! -d "$PY_LAB_PROJECT/.venv" ]]; then
		py -c "print('Initializing...')"
	fi
	"$PY_LAB_VENV/bin/pip" install "$@"
	
	# Update requirements.txt to persist changes
	"$PY_LAB_VENV/bin/pip" freeze > "$PY_LAB_PROJECT/requirements.txt"
}

# Wipe and rebuild the lab environment
py-clean() {
	echo "Wiping lab environment..."
	rm -rf "$PY_LAB_PROJECT/.venv"
	rm -rf "$PY_LAB_VENV"

	# Rebuild and re-link
	(cd "$HOME/dotfiles" && ./install_python_lab.sh)
}
