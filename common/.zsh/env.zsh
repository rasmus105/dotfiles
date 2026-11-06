#!/usr/bin/env zsh

# Environment variables and path setup.

# ==============================================================================
# Defaults
# ==============================================================================

export EDITOR="nvim"
export MANPAGER="nvim +Man!"
# Preserve the terminal's capabilities; use a fallback only when none is supplied.
export TERM="${TERM:-xterm-256color}"

# ==============================================================================
# Tool Homes
# ==============================================================================

export BUN_INSTALL="$HOME/.bun"

# ==============================================================================
# Paths
# ==============================================================================

typeset -U path
if [[ "$(uname -s)" == "Darwin" && -x /opt/homebrew/bin/brew ]]; then
  path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
fi
path=(
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$BUN_INSTALL/bin"
  $path
)
export PATH
