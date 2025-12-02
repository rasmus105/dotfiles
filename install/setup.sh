#!/bin/bash
set -e

# cache credentials (needed for later installation)
sudo -v

# periodically cache sudo to keep it cached (otherwise it expires after 5 minutes)
while sleep 100; do sudo -v; done &

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
source "$DOTFILES_DIR/local/lib/shell/common.sh"

# Core environment/bootstrap steps
ensure_gum_is_installed
add_dotfiles_bin_to_path

# ==== Initial Setup (gum to improve UI, install paru)
# Initialize logging with consistent log file name
LOG_FILE="/tmp/gum-log/dotfiles-setup.log"
log_init
gum_info "Logging to: $LOG_FILE"
echo # newline

# ==== Source Modules with Functions ====
source "$SCRIPT_DIR/install_packages.sh"
source "$SCRIPT_DIR/setup_zsh.sh"
source "$SCRIPT_DIR/stow.sh"
source "$SCRIPT_DIR/mimetypes.sh"

# ==== Install Packages ====
if ! is_installed "paru"; then
    install_paru
fi

install_packages "$SCRIPT_DIR/packages.txt"

# ==== Configuration ====
# Export DOTFILES_DIR to shell configs
echo "export DOTFILES_DIR=\"$DOTFILES_DIR\"" >"$HOME/.dotfiles_env"

stow_dotfiles       # symlink config/ to ~/.config/
configure_mimetypes # set default applications
setup_zsh_main      # set shell to zsh

systemctl --user enable --now battery-monitor.timer

sudo mkdir -p /etc/chromium/policies/managed
sudo chmod a+rw /etc/chromium/policies/managed
