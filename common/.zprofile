for dotfiles_brew in "${commands[brew]:-}" /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  if [[ -x "$dotfiles_brew" ]]; then
    eval "$("$dotfiles_brew" shellenv zsh)"
    break
  fi
done
unset dotfiles_brew

if [[ -r "${ZDOTDIR:-$HOME}/.zprofile.local" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile.local"
fi
