#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
source "$DOTFILES_DIR/common.sh"

# ==== set zsh as default shell ====

gum_info "Setting zsh as default shell..."
ZSH_PATH=/usr/bin/zsh
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$USER"
    gum_success "Default shell set to zsh"
    gum_info "Note: You must log out and back in for the shell change to take effect."
else
    gum_info "zsh is already the default shell"
fi

# ==== install antidote (zsh plugin manager) ====
git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-~}/.antidote"
