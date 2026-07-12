#!/usr/bin/env zsh

# Core zsh behavior: history, plugins, completions, keybindings, and prompt.

# ==============================================================================
# History
# ==============================================================================

HISTFILE="$HOME/.histfile"
HISTSIZE=10000
SAVEHIST=10000

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt HIST_VERIFY

# ==============================================================================
# Plugin Cache
# ==============================================================================

zsh_plugins="${ZDOTDIR:-$HOME}/.zsh_plugins"

if [[ ! "${zsh_plugins}.zsh" -nt "${zsh_plugins}.txt" ]]; then
  source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
  antidote bundle <"${zsh_plugins}.txt" >|"${zsh_plugins}.zsh"
fi

# ==============================================================================
# Tool Integrations
# ==============================================================================

export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--bind=ctrl-n:down,ctrl-p:up,ctrl-d:page-down,ctrl-u:page-up,ctrl-f:forward-char,ctrl-b:backward-char,ctrl-g:accept"
source <(fzf --zsh)
eval "$(zoxide init zsh)"

# ==============================================================================
# Completion
# ==============================================================================

typeset -U fpath
fpath=(
  "$HOME/.local/share/zsh/site-functions"
  "$HOME/.zfunc/"
  $fpath
)

autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qNmh-24) ]]; then
  compinit -C
else
  compinit
fi

# ==============================================================================
# Plugins
# ==============================================================================

source "${zsh_plugins}.zsh"

zstyle ':fzf-tab:*' fzf-bindings 'ctrl-g:accept'

# ==============================================================================
# Keybindings
# ==============================================================================

KEYTIMEOUT=1
bindkey -e

# ==============================================================================
# Prompt
# ==============================================================================

autoload -Uz vcs_info

precmd() {
  vcs_info
}

zstyle ':vcs_info:git:*' formats '%b'

setopt PROMPT_SUBST
PROMPT='%F{blue}%~ %(?.%F{green}✓.%F{red}✗ %?)%f %F{green}(${vcs_info_msg_0_})%f %F{white}$ '
