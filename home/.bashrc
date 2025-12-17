[ -f "$HOME/.dotfiles_env" ] && source "$HOME/.dotfiles_env"

# ===============================
# Exports
# ===============================
export PATH=$PATH:~/.npm/bin:~/.platformio/penv/bin:~/.local/bin:~/.opencode/bin
export MANPAGER="nvim +Man!"
export EDITOR="nvim"
export TERM=xterm-256color

# ===============================
# Aliases
# ===============================
alias grep='grep --color=auto'
alias cd='z'
alias cat='bat'
alias g='lazygit'
alias n='nvim'

ls() {
    command eza "$@"
}

# Yazi file manager
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# ===============================
# Zoxide Integration
# ===============================
eval "$(zoxide init bash)"

# ===============================
# Custom Completions
# ===============================
# Source completions from user directory
# (bash-completion >= 2.8 auto-loads, but this ensures compatibility)
for f in ~/.local/share/bash-completion/completions/*; do
    [[ -f "$f" ]] && source "$f"
done
