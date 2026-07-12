#!/usr/bin/env zsh

# Terminal-specific behavior and UI hooks.

# ==============================================================================
# Neovim Terminal Cursor
# ==============================================================================

if [[ -n "$NVIM_LOG_FILE" ]]; then
  printf '\033[5 q'
fi

# ==============================================================================
# Window Title
# ==============================================================================

# Set title to directory as that is more useful than the command run.
__set_title() {
  emulate -L zsh

  local title
  title="${PWD/#$HOME/~}"
  title="${title//$'\a'/}"
  title="${title//$'\e'/}"

  printf '\e]2;%s\a' "$title"
}

autoload -Uz add-zsh-hook

__set_title
add-zsh-hook chpwd __set_title
