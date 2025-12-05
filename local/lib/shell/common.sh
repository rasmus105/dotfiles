#!/usr/bin/env bash
# Common shell helper functions
# Source this file to access shared utilities across dotfiles scripts

#──────────────────────────────────────────────────────────────────────────────
# Setup
#──────────────────────────────────────────────────────────────────────────────

_COMMON_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
_COMMON_DOTFILES_DIR=$(dirname "$(dirname "$(dirname "$_COMMON_SCRIPT_DIR")")")

# Non-interactive mode support
# Set USE_DEFAULT_OPTIONS=1 to skip all prompts and use defaults
export USE_DEFAULT_OPTIONS="${USE_DEFAULT_OPTIONS:-0}"

#──────────────────────────────────────────────────────────────────────────────
# Environment Functions
#──────────────────────────────────────────────────────────────────────────────

add_dotfiles_bin_to_path() {
    case ":$PATH:" in
    *":$_COMMON_DOTFILES_DIR/bin:"*) ;; # already present
    *) export PATH="$_COMMON_DOTFILES_DIR/local/bin:$PATH" ;;
    esac
}

ensure_gum_is_installed() {
    command -v gum &>/dev/null || {
        echo "Installing gum for cleaner UI..."
        sudo pacman -S --noconfirm gum
    }
}

#──────────────────────────────────────────────────────────────────────────────
# Package Functions
#──────────────────────────────────────────────────────────────────────────────

is_installed() {
    pacman -Q "$1" &>/dev/null
}

command_exists() {
    command -v "$1" &>/dev/null
}

#──────────────────────────────────────────────────────────────────────────────
# Execution Functions
#──────────────────────────────────────────────────────────────────────────────

# Quiet command execution helper
# Suppresses stdout/stderr unless VERBOSE=1 or LOG_ENABLED=1
# Usage: q command args...
q() {
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        # Verbose mode: show everything
        "$@"
    elif [[ "${LOG_ENABLED:-0}" == "1" ]] && [[ -n "${LOG_FILE:-}" ]] && [[ -f "$LOG_FILE" ]]; then
        # Log mode: send to log file (only if explicitly enabled and file exists)
        "$@" >>"$LOG_FILE" 2>&1
    else
        # Quiet mode: suppress output
        "$@" >/dev/null 2>&1
    fi
}
