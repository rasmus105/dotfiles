#!/usr/bin/env zsh

# Aliases and interactive command helpers.

# ==============================================================================
# Aliases
# ==============================================================================

alias g='lazygit -ucd "$HOME/.config/lazygit"'
alias gp='git push'
alias n='nvim'
alias grep='grep --color=auto'
alias cd='z'
alias cat='bat -p'
alias disable_sleep='sudo pmset -a disablesleep 1' # useful when needing to close lid while keeping laptop on.
alias enable_sleep='sudo pmset -a disablesleep 0'
alias venv='source .venv/bin/activate'
alias ..="cd .."
alias ...="cd ../.."

# ==============================================================================
# Misc commands
# ==============================================================================

mkcd() {
    mkdir -p -- "$1" && cd "$1"
}

# ==============================================================================
# Command Wrappers
# ==============================================================================

ls() {
  command eza "$@"
}

y() {
  local tmp cwd

  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# ==============================================================================
# Git Helpers
# ==============================================================================

gd() {
  local -a args
  local arg

  if (( $# == 1 )); then
    set -- "$1^" "$1"
  fi

  for arg in "$@"; do
    arg=${arg//\\/\\\\}
    arg=${arg// /\\ }
    args+=("$arg")
  done

  nvim -c "CodeDiffStandalone ${(j: :)args}"
}

gwt() {
  if [[ -z "$1" ]]; then
    print -u2 "Usage: gwt <branch-name>"
    return 1
  fi

  local branch="$1"

  git worktree add "$branch" -b "$branch" || return
  cd "$branch" || return

  if [[ -n "$TMUX" ]]; then
    tmux rename-window "$branch"
  fi
}

# [g]it[p]ush[a]ll
gpa() {
  emulate -L zsh
  setopt no_monitor
  local dir pushed=0

  for dir in */; do
    [[ -d "$dir/.git" ]] || continue

    pushed=1
    {
      print "Pushing ${dir%/}"
      git -C "$dir" push
    } & 
  done

  if (( ! pushed )); then
    print -u2 "No git repositories found in subdirectories."
    return 1
  fi

  wait
}
