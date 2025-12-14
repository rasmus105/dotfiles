[ -f "$HOME/.dotfiles_env" ] && source "$HOME/.dotfiles_env"

# ===============================
# History Configuration
# ===============================
HISTFILE=~/.histfile  # Location of history file
HISTSIZE=50000         # Number of commands to keep in memory
SAVEHIST=50000         # Number of commands to save to HISTFILE

setopt HIST_IGNORE_DUPS      # Don't record duplicate commands
setopt HIST_IGNORE_SPACE     # Don't record commands starting with space
setopt SHARE_HISTORY         # Share history between sessions
setopt HIST_VERIFY           # Show command before executing from history

# ===============================
# Path Configuration
# ===============================
# wmname LG3D  # Needed for Ghidra, Maple, and other Java-based software

# ===============================
# Exports
# ===============================
# DOTFILES_DIR will be set during installation
# export DOTFILES_DIR="$HOME/.dotfiles"

export PATH=$PATH:~/.npm/bin:/home/rasmus105/.platformio/penv/bin:~/.local/bin:/home/rasmus105/.opencode/bin
export MANPAGER="nvim +Man!" # use neovim for man pages.
export EDITOR="nvim" # some applications such as Yazi use this variable for determining editor
export TERM=xterm-256color

# ===============================
# Aliases
# ===============================
alias grep='grep --color=auto'  # Enable color output for grep
alias cd='z'  # Use zoxide for quick directory navigation
alias cat='bat' # better 'cat'.
alias g='lazygit'
alias n='nvim'
# alias opencode-jail='OPENCODE_CONFIG=~/.config/opencode/all-access.json firejail --profile=opencode --whitelist=$(pwd) opencode'

ls() { # better ls command
    command eza "$@" 
}

opencode-jail() {
    readonly workdir="$(pwd)"
    OPENCODE_CONFIG=~/.config/opencode/all-access.json firejail --profile=opencode --whitelist="$workdir" --read-write="$workdir" opencode "$@"
}

# Specific
alias clear_outputs='for i in {0..10}; do hyprctl output remove HEADLESS-$i; done'
alias rtouch='sudo modprobe -r hid_multitouch && sudo modprobe hid_multitouch' # fixing issue with touchpad.

# Change cursor shape in Neovim terminal
if [ -n "$NVIM_LOG_FILE" ]; then
  # Use escape codes to set cursor style
  # 1 or 0 for blinking block
  # 2 for steady block
  # 3 for blinking underline
  # 4 for steady underline
  # 5 for blinking bar (I-beam)
  # 6 for steady bar (I-beam)
  printf '\033[5 q'
fi
# ===============================
# Keybindings & Zoxide Integration
# ===============================
eval "$(zoxide init zsh)"
KEYTIMEOUT=1
bindkey -e # force emacs mode (i.e. <C-w> = delete word, <C-e> = end of line, <C-p> = prev command)

# ===============================
# Plugin Management (Antidote)
# ===============================
[ -f "/usr/share/zsh-antidote/antidote.zsh" ] && source "/usr/share/zsh-antidote/antidote.zsh"  # Load Antidote
[ -f "$HOME/.antidote/antidote.zsh" ] && source "$HOME/.antidote/antidote.zsh"  # Load Antidote
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
PROMPT='%F{blue}%~ %(?.%F{green}✓.%F{red}✗ %?)%f %F{green}(${vcs_info_msg_0_})%f %F{white}$ '

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
