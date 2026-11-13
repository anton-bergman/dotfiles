#!/bin/bash
set -e
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES_DIR/lib/utils.sh"
ensure_base_ready

# --- Zsh Plugins ---
PLUGIN_DIR="$DOTFILES_DIR/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

clone_or_pull "https://github.com/zsh-users/zsh-autosuggestions.git" "$PLUGIN_DIR/zsh-autosuggestions"
clone_or_pull "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$PLUGIN_DIR/zsh-syntax-highlighting"
clone_or_pull "https://github.com/zsh-users/zsh-completions.git" "$PLUGIN_DIR/zsh-completions"

# --- Configurations Linking ---
link_file "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

# Optional local overrides (graceful degradation)
if [ -f "$DOTFILES_DIR/zsh/zshrc.local" ]; then
	link_file "$DOTFILES_DIR/zsh/zshrc.local" "$HOME/.zshrc.local"
fi

link_file "$DOTFILES_DIR/vim/vimrc" "$HOME/.vimrc"
link_file "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"
link_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
