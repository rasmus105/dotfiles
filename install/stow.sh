#!/bin/bash
set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) # Get script directory
DOTFILES_DIR=$(dirname "$SCRIPT_DIR") # Get dotfiles directory (parent of script directory)
cd "$DOTFILES_DIR" # Change to dotfiles directory (required for stow)

# Stow the config directory
stow -t "$HOME/.config" config
stow -t "$HOME" home


