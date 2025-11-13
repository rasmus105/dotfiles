#!/bin/bash
set -e

# cache credentials (needed for later installation)
sudo -v

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
source "$DOTFILES_DIR/common.sh"

# ==== Initial Setup (gum to improve UI, install paru)
# Initialize logging
gum_log_init
gum_info "Logging to: $INSTALL_LOG_FILE"
echo # newline

# ==== Source Modules ====
source "$SCRIPT_DIR/install_packages.sh"

# ==== Proceed with Setup ====

if ! is_installed "paru"; then
    install_paru
fi

install_packages "$SCRIPT_DIR/packages.txt"

source "$SCRIPT_DIR/setup_zsh.sh"

# ==== Stow Configuration Files ====
source "$SCRIPT_DIR/stow.sh"
