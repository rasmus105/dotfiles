#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
source "$HOME/.local/lib/shell/common.sh"

setup_zsh_main() {
    local ZSH_PATH=/usr/bin/zsh
    local CURRENT_SHELL
    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)

    if [[ ! -f "$ZSH_PATH" ]]; then
        log_error "zsh can not be found at '$ZSH_PATH'. This is likely\
 due to an error in the installation process\n\
 Aborting install..."
        exit 1
    fi

    log_info "Setting zsh as default shell..."

    if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
        sudo chsh -s "$ZSH_PATH" "$USER"
        log_success "Default shell set to zsh"
        log_info "Note: You must log out and back in for the shell change to take effect."
    else
        log_info "zsh is already the default shell"
    fi

    # ==== install antidote (zsh plugin manager) ====
    git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-~}/.antidote"
}

# only run setup is called as `bash setup_zsh.sh` (not when sourced)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    setup_zsh_main "$@"
fi
