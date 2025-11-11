# ===============================
# History Configuration
# ===============================
HISTFILE=~/.histfile  # Location of history file
HISTSIZE=50000         # Number of commands to keep in memory
SAVEHIST=50000         # Number of commands to save to HISTFILE

# ===============================
# Path Configuration
# ===============================
wmname LG3D  # Needed for Ghidra, Maple, and other Java-based software

# ===============================
# Exports
# ===============================
export PATH=$PATH:~/.npm/bin:home/rasmus105/.platformio/penv/bin
export MANPAGER="nvim +Man!" # use neovim for man pages.
# export TERM=xterm-256color
export TERM=xterm-256color

# ===============================
# Aliases
# ===============================
alias grep='grep --color=auto'  # Enable color output for grep
alias cd='z'  # Use zoxide for quick directory navigation
alias cat='batcat' # better 'cat'.
alias g='lazygit'
alias n='nvim'
alias clear_outputs='for i in {0..10}; do hyprctl output remove HEADLESS-$i; done'
# alias cat='bat --paging=never'
ls() { # better ls command
    command eza "$@" 
}

# ===============================
# Keybindings & Zoxide Integration
# ===============================
eval "$(zoxide init zsh)"
KEYTIMEOUT=1

# ===============================
# Plugin Management (Antidote)
# ===============================
source ~/.antidote/antidote.zsh  # Load Antidote
antidote load ${ZDOTDIR:-$HOME}/.zsh_plugins.txt  # Load plugins from file

# ===============================
# Prompt Configuration
# ===============================
# Load version control information
autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '%b'

# Set up the prompt (with git branch name)
setopt PROMPT_SUBST
PROMPT='%F{blue}%~ %(?.%F{green}.%F{red})%f%F{green}(${vcs_info_msg_0_}) %F{white}$ '

# ===============================
# Completion System (compinit)
# ===============================
zstyle :compinstall filename '/home/rasmus105/.zshrc'
autoload -Uz compinit
compinit

# ===============================
# Colored Man Pages
# ===============================

autoload -U colors && colors

# Define terminal capabilities for colored man pages
typeset -AHg less_termcap
less_termcap[mb]="${fg_bold[red]}"      # Bold & blinking
less_termcap[md]="${fg_bold[red]}"
less_termcap[me]="${reset_color}"
less_termcap[so]="${fg_bold[yellow]}${bg[blue]}"  # Standout mode
less_termcap[se]="${reset_color}"
less_termcap[us]="${fg_bold[green]}"  # Underline
less_termcap[ue]="${reset_color}"

# Define absolute path to this file's directory
typeset -g __colored_man_pages_dir="${0:A:h}"

# Function to apply color settings to man pages
function colored() {
  local -a environment
  local k v
  for k v in "${(@kv)less_termcap}"; do
    environment+=( "LESS_TERMCAP_${k}=${v}" )
  done
  environment+=( PAGER="${commands[less]:-$PAGER}" )
  environment+=( GROFF_NO_SGR=1 )
  if [[ "$OSTYPE" = solaris* ]]; then
    environment+=( PATH="${__colored_man_pages_dir}:$PATH" )
  fi
  command env $environment "$@"
}

# Functions for colorizing man and Debian man pages
function man dman debman {
  colored $0 "$@"
}

# Yazi (File manager)
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
