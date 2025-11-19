#!/bin/bash

stow_dotfiles() {
    local SCRIPT_DIR
    local DOTFILES_DIR

    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) # Get script directory
    DOTFILES_DIR=$(dirname "$SCRIPT_DIR") # Get dotfiles directory (parent of script directory)

    cd "$DOTFILES_DIR" # Change to dotfiles directory (required for stow)

    # Stow the config and home directory
    stow -t "$HOME/.config" config
    stow -t "$HOME" home

    # Stow the .application config files
    mkdir -p "$HOME/.local/share/applications/icons"
    stow -t "$HOME/.local" local

    # Set default theme (gruvbox) if theme symlink doesn't exist
    if [[ ! -e "$HOME/.config/theme" ]]; then
      ln -sf "$DOTFILES_DIR/themes/gruvbox" "$HOME/.config/theme"
    fi

    # Link all system themes to ~/.config/themes
    ln -sf "$DOTFILES_DIR/themes" "$HOME/.config/themes"

    # Set up hyprpaper background from current theme
    "$DOTFILES_DIR/bin/update-hyprpaper-background"

    # Set up neovim theme from current theme
    "$DOTFILES_DIR/bin/update-nvim-theme"

    mkdir -p ~/.config/btop/themes
    ln -snf ~/.config/theme/btop.theme ~/.config/btop/themes/current.theme
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    set -e
    stow_dotfiles "$@"
fi
