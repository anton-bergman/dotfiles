#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

LAB_DIR="$DOTFILES_DIR/scripts/python"
VENV_DIR="$HOME/.virtualenvs"
LAB_VENV="$LAB_DIR/.venv"

mkdir -p "$VENV_DIR"

if [ -d "$LAB_VENV" ]; then
	rm -rf "$LAB_VENV"
fi

PYTHON_BIN=$(command -v python3)
if command -v mise >/dev/null 2>&1; then
	PYTHON_BIN=$(mise which python3 2>/dev/null || echo "$PYTHON_BIN")
fi

"$PYTHON_BIN" -m venv "$LAB_VENV"

"$LAB_VENV/bin/pip" install --upgrade pip >/dev/null 2>&1 || true
if [ -f "$LAB_DIR/requirements.txt" ]; then
	"$LAB_VENV/bin/pip" install -r "$LAB_DIR/requirements.txt" >/dev/null 2>&1 || true
fi

link_file "$LAB_VENV" "$VENV_DIR/lab"
