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

    stow --restow --ignore='^\.gitkeep$' --dir "$repo_dir" --target "$HOME" "$mode"='.*' "$package"
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
brew bundle --file "$repo_dir/Brewfile"

# Defer conflicts from the generic package so the platform package owns them.
stow_package common --defer
stow_package "$platform" --override

source "$platform_setup"
