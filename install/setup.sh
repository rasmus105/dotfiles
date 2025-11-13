#!/bin/bash
set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")

source "$SCRIPT_DIR/common.sh"

# cache credentials (needed for later installation)
sudo -v

if ! is_installed "gum"; then
    echo "Installing gum for cleaner UI..."
    sudo pacman -S --noconfirm gum
fi

if ! is_installed "base-devel"; then
    gum_info "Installing base-devel..."
    sudo pacman --noconfirm -S base-devel
fi
if ! is_installed "git"; then
    gum_info "Installing git..."
    sudo pacman --noconfirm -S git
fi

# install paru (AUR helper)
gum_info "Cloning paru from AUR..."
rm -rf /tmp/paru
git clone https://aur.archlinux.org/paru.git /tmp/paru
cd /tmp/paru
gum_info "Building and installing paru..."
makepkg -si --noconfirm
cd ~
rm -rf /tmp/paru
gum_success "Paru installed successfully"

