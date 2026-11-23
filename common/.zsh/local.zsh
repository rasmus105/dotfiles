#!/usr/bin/env zsh

# Tab completion for juliaup and julia channel selection.
[[ -r "$HOME/.julia/juliaup/completions/zsh.zsh" ]] && source "$HOME/.julia/juliaup/completions/zsh.zsh"

if [[ -r "$HOME/.claude/settings-machine.json" ]]; then
  claude() {
    local arg
    for arg in "$@"; do
      if [[ "$arg" == --settings || "$arg" == --settings=* ]]; then
        command claude "$@"
        return
      fi
    done
    command claude --settings "$HOME/.claude/settings-machine.json" "$@"
  }
fi

# lazy-load bun.
bun() {
  command bun "$@"
  local ret=$?

  if [[ -z "$BUN_COMPLETE" ]]; then
    [[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
    BUN_COMPLETE=1
  fi

  return $ret
}
