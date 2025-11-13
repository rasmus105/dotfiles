#!/bin/bash
set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")

source "$DOTFILES_DIR/common.sh"

# Initialize logging
gum_log_init
gum_info "Logging to: $INSTALL_LOG_FILE"
echo

# cache credentials (needed for later installation)
sudo -v

if ! is_installed "gum"; then
    echo "Installing gum for cleaner UI..."
    sudo pacman -S --noconfirm gum
fi

if ! is_installed "base-devel"; then
    gum_run "Installing base-devel" "sudo pacman --noconfirm -S base-devel"
fi

if ! is_installed "git"; then
    gum_run "Installing git" "sudo pacman --noconfirm -S git"
fi

# install paru (AUR helper)
gum_info "Setting up paru (AUR helper)..."
gum_run "Cloning paru from AUR" "rm -rf /tmp/paru && git clone https://aur.archlinux.org/paru-bin.git /tmp/paru"
cd /tmp/paru
gum_run "Building and installing paru" "makepkg -si --noconfirm"
cd ~
gum_run_quiet "rm -rf /tmp/paru"
gum_success "Paru installed successfully"

