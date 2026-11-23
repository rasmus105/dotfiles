#!/usr/bin/env zsh

source "$HOME/.zsh/env.zsh"
source "$HOME/.zsh/shell.zsh"
source "$HOME/.zsh/commands.zsh"
source "$HOME/.zsh/manpages.zsh"
source "$HOME/.zsh/terminal.zsh"

[[ -r "$HOME/.zsh/local.zsh" ]] && source "$HOME/.zsh/local.zsh"
[[ -r "$HOME/.zsh/machine.zsh" ]] && source "$HOME/.zsh/machine.zsh"
