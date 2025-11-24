#!/bin/bash
set -e

# cache credentials (needed for later installation)
# FIXME - will expire after 5 minutes.
sudo -v

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
source "$DOTFILES_DIR/common.sh"

# Core environment/bootstrap steps
ensure_gum
add_dotfiles_bin_to_path

# ==== Initial Setup (gum to improve UI, install paru)
# Initialize logging
gum_log_init
gum_info "Logging to: $INSTALL_LOG_FILE"
echo # newline

# ==== Source Modules with Functions ====
source "$SCRIPT_DIR/install_packages.sh"
source "$SCRIPT_DIR/setup_zsh.sh"
source "$SCRIPT_DIR/stow.sh"
source "$SCRIPT_DIR/config/mimetypes.sh"

# ==== Install Packages ====
if ! is_installed "paru"; then
    install_paru
fi

install_packages "$SCRIPT_DIR/packages.txt"

# ==== Configuration ====
stow_dotfiles       # symlink config/ to ~/.config/
configure_mimetypes # set default applications
setup_zsh_main      # set shell

#
# systemctl --user enable elephant
# systemctl --user enable walker
# systemctl --user start elephant
# systemctl --user start walker
