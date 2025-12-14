# FireJail profile for OpenCode
# Place this file in /etc/firejail/opencode.profile

include /etc/firejail/disable-common.inc

# Security restrictions
caps.drop all
nodvd
nogroups
noinput
nonewprivs
nosound
notv
novideo
seccomp
noroot
private-tmp
private-dev

# OpenCode directories
whitelist ~/.opencode
whitelist ~/.local/share/opencode
whitelist ~/.config/opencode
whitelist ~/.cache/opencode

# Git (SSH-based)
whitelist ~/.gitconfig
whitelist ~/.ssh

# Rust
whitelist ~/.cargo
whitelist ~/.rustup

# Node.js / JavaScript
whitelist ~/.npm
whitelist ~/.node_modules
whitelist ~/.nvm
whitelist ~/.local/share/npm
whitelist ~/.bun
whitelist ~/.deno

# Go
whitelist ~/.go
whitelist ~/go

# Python
whitelist ~/.python_history
whitelist ~/.local/share/virtualenvs
whitelist ~/.pyenv
whitelist ~/.conda
whitelist ~/.local/pipx
whitelist ~/.cache/pip

# Java
whitelist ~/.java
whitelist ~/.gradle
whitelist ~/.m2

# General development
whitelist ~/.local/bin

# Neovim
whitelist ~/.config/nvim
read-write ~/.local/share/nvim
whitelist ~/.local/share/nvim

read-write ~/.local/state/nvim
whitelist ~/.local/state/nvim

read-write ~/.cache/nvim
whitelist ~/.cache/nvim

read-write /usr/share/nvim/
whitelist /usr/share/nvim/


