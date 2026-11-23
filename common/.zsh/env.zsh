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
if [[ -x /opt/homebrew/bin/brew ]]; then
  path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  path=(/home/linuxbrew/.linuxbrew/bin /home/linuxbrew/.linuxbrew/sbin $path)
fi
if (( $+commands[brew] )); then
  brew_prefix="${commands[brew]:h:h}"
  [[ -x "$brew_prefix/opt/rustup/bin/rustup" ]] && path=("$brew_prefix/opt/rustup/bin" $path)
  if [[ -z "${JAVA_HOME:-}" || ! -x "$JAVA_HOME/bin/java" ]]; then
    if [[ -x "$brew_prefix/opt/openjdk/libexec/openjdk.jdk/Contents/Home/bin/java" ]]; then
      export JAVA_HOME="$brew_prefix/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
    elif [[ -x "$brew_prefix/opt/openjdk/bin/java" ]]; then
      export JAVA_HOME="$brew_prefix/opt/openjdk"
    fi
  fi
  unset brew_prefix
fi
[[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]] && path=("$JAVA_HOME/bin" $path)
path=(
  "$HOME/.juliaup/bin"
  "$HOME/.cargo/bin"
  "$HOME/.local/bin"
  "$BUN_INSTALL/bin"
  $path
)
export PATH
