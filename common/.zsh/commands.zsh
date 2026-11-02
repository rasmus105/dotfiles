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

rr() {
  rex run --focus=false -c "$PWD" -- "$@"
}

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

  if (( $# == 0 )); then
    local changes
    changes="$(git status --porcelain --untracked-files=normal)" || return
    if [[ -z "$changes" ]]; then
      print -r -- "No uncommitted changes."
      return 0
    fi
  fi

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

gstats() (
  emulate -L zsh
  setopt pipefail
  local root file tracked color=0

  root="$(git rev-parse --show-toplevel)" || return
  builtin cd -- "$root" || return
  tracked="$(git diff --no-color --raw --numstat HEAD)" || return
  [[ -t 1 && -z "${NO_COLOR:-}" && "$TERM" != dumb ]] && color=1

  {
    [[ -z "$tracked" ]] || print -r -- "$tracked"
    print -r -- '?'
    git ls-files --others --exclude-standard -z |
      while IFS= read -r -d '' file; do
        # A no-index diff exits with 1 when it finds changes.
        git diff --no-color --no-index --numstat -- /dev/null "$file" || (( $? == 1 )) || return
      done
  } | awk -F '\t' -v color="$color" '
    BEGIN {
      if (color) {
        reset = "\033[0m"; bold = "\033[1m"; dim = "\033[2m"
        green = "\033[32m"; red = "\033[31m"
        mark["M"] = mark["T"] = mark["?"] = "\033[33m"
        mark["A"] = green; mark["D"] = red
        mark["R"] = mark["C"] = "\033[36m"; mark["U"] = "\033[35m"
      }
      add_width = 5; del_width = 7
    }
    # Git emits raw statuses before numstat rows, in matching order.
    /^:/ {
      split($1, metadata, " ")
      kind[++tracked_count] = substr(metadata[5], 1, 1)
      next
    }
    $0 == "?" { untracked = 1; next }
    NF >= 3 {
      row++
      if (untracked) kind[row] = "?"
      path[row] = $0
      sub(/^[^\t]*\t[^\t]*\t/, "", path[row])
      if (untracked) sub(/^\/dev\/null => /, "", path[row])
      binary[row] = ($1 == "-")
      if (!binary[row]) {
        additions[row] = "+" $1; deletions[row] = "-" $2
        added += $1; deleted += $2
        if (length(additions[row]) > add_width) add_width = length(additions[row])
        if (length(deletions[row]) > del_width) del_width = length(deletions[row])
      }
    }
    END {
      if (row) printf "%s    %*s  %*s  File%s\n", dim, add_width, "Added", del_width, "Deleted", reset
      for (i = 1; i <= row; i++) {
        printf " %s%s%s  ", mark[kind[i]], kind[i], reset
        if (binary[i]) {
          printf "%s%*s%s", dim, add_width + del_width + 2, "binary", reset
        } else {
          printf "%s%*s%s  %s%*s%s", green, add_width, additions[i], reset, red, del_width, deletions[i], reset
        }
        printf "  %s\n", path[i]
      }
      printf "\n%sTotal:%s %s+%d%s %s-%d%s lines (%d %s)\n", bold, reset, green, added, reset, red, deleted, reset, row, (row == 1 ? "file" : "files")
    }
  '
)

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

gex() {
  local exclude_file

  exclude_file="$(git rev-parse --path-format=absolute --git-path info/exclude)" || return
  "${EDITOR:-vi}" "$exclude_file"
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

# ==============================================================================
# Pdf
# ==============================================================================

pdfpage() {
  local pdf="$1" page="$2"
  local output="/tmp/pdf-page-$page"
  pdftoppm -f "$page" -l "$page" -png -r 180 "$pdf" "$output"
  kitten icat "${output}-$(printf '%02d' "$page").png"
}
