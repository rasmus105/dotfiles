#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

install_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        return
    fi

    if ! command -v curl >/dev/null 2>&1; then
        fail "Homebrew is not installed and curl is unavailable."
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

activate_homebrew() {
    local brew_bin

    brew_bin="$(command -v brew || true)"
    if [[ -z "$brew_bin" ]]; then
        for brew_bin in \
            /opt/homebrew/bin/brew \
            /usr/local/bin/brew \
            /home/linuxbrew/.linuxbrew/bin/brew; do
            [[ -x "$brew_bin" ]] && break
        done
    fi

    [[ -x "$brew_bin" ]] || fail "Homebrew was installed but brew could not be found."
    eval "$("$brew_bin" shellenv)"
}

stow_package() {
    local package="$1"
    local mode="$2"

    [[ -d "$repo_dir/$package" ]] || fail "Missing Stow package: $package"

    stow --restow --no-folding --ignore='^\.gitkeep$' \
        --ignore='(^|/)\.claude/(?!CLAUDE\.md$|settings\.json$|statusline-command\.sh$).*' \
        --ignore='(^|/)\.codex/(?!AGENTS\.md$|shared\.config\.toml$).*' \
        --ignore='(^|/)\.ssh/(?!config$).*' \
        --ignore='(^|/)(\.gitconfig\.local|\.zprofile\.local|\.zsh/machine\.zsh)$' \
        --dir "$repo_dir" --target "$HOME" "$mode"='.*' "$package"
}

case "$(uname -s)" in
    Darwin)
        platform="macos"
        ;;
    Linux)
        [[ -r /etc/os-release ]] || fail "Cannot determine Linux distribution."
        source /etc/os-release
        [[ -n "${ID:-}" ]] || fail "Linux distribution ID is missing."
        platform="$ID"
        ;;
    *)
        fail "Unsupported operating system: $(uname -s)"
        ;;
esac

[[ "$platform" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || fail "Invalid platform name: $platform"
platform_setup="$repo_dir/bin/${platform}-setup.sh"

[[ -d "$repo_dir/$platform" ]] || fail "Unsupported platform: $platform"
[[ -f "$platform_setup" ]] || fail "Missing platform setup script: $platform_setup"

install_homebrew
activate_homebrew

# The old client and tlrc install the same command and completion files.
if [[ -n "$(brew list --versions tldr)" ]]; then
    brew unlink tldr
fi
brew bundle --file "$repo_dir/Brewfile"

nvim_bin="$HOMEBREW_PREFIX/bin/nvim"
# Bundle considers a linked HEAD install sufficient even with a stable spec.
if [[ -x "$nvim_bin" && "$("$nvim_bin" --version)" == NVIM\ *-dev* ]]; then
    brew unlink neovim
    if ! HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --formula neovim; then
        brew link --HEAD neovim
        fail "Could not install stable Neovim."
    fi
    [[ -x "$nvim_bin" ]] || brew link neovim
fi

export PATH="$HOME/.juliaup/bin:$HOME/.cargo/bin:$HOMEBREW_PREFIX/opt/rustup/bin:$HOMEBREW_PREFIX/bin:$PATH"
if ! rustup default >/dev/null 2>&1; then
    rustup default stable
fi
rustup component add rust-src
juliaup add 1.12
if ! julia --version >/dev/null 2>&1; then
    juliaup default 1.12
fi
if [[ ! -x "${JAVA_HOME:-}/bin/java" || -z "${JAVA_HOME:-}" ]]; then
    if [[ "$platform" == "macos" ]]; then
        export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
    else
        export JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk"
    fi
fi
export PATH="$JAVA_HOME/bin:$PATH"

migrate_zprofile=false
if [[ -f "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]]; then
    [[ ! -e "$HOME/.zprofile.local" && ! -L "$HOME/.zprofile.local" ]] ||
        fail "Both ~/.zprofile and ~/.zprofile.local exist. Back up and merge their contents before setup."
    migrate_zprofile=true
fi

# Remove folded directory links from previous runs before merging packages.
stow --delete --dir "$repo_dir" --target "$HOME" common "$platform"

if [[ "$migrate_zprofile" == true ]]; then
    mv "$HOME/.zprofile" "$HOME/.zprofile.local"
fi

# Defer conflicts from the generic package so the platform package owns them.
if ! stow_package common --defer; then
    if [[ "$migrate_zprofile" == true && ! -e "$HOME/.zprofile" && ! -L "$HOME/.zprofile" ]]; then
        mv "$HOME/.zprofile.local" "$HOME/.zprofile"
    fi
    exit 1
fi
stow_package "$platform" --override

"$nvim_bin" --headless -i NONE -n -u NONE -l "$repo_dir/bin/nvim-setup.lua" plugins
"$nvim_bin" --headless -i NONE -n -u "$HOME/.config/nvim/init.lua" -l "$repo_dir/bin/nvim-setup.lua"

source "$platform_setup"
