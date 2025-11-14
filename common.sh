_COMMON_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
_COMMON_DOTFILES_DIR=$(dirname "$_COMMON_SCRIPT_DIR")

# make sure gum is installed when this is sourced.
if ! $(command -v "gum" &> /dev/null); then
    echo "Installing gum for cleaner UI..."
    sudo pacman -S --noconfirm gum
fi

# Non-interactive mode support
# Set USE_DEFAULT_OPTIONS=1 to skip all prompts and use defaults
export USE_DEFAULT_OPTIONS="${USE_DEFAULT_OPTIONS:-0}"

export PATH="$_COMMON_DOTFILES_DIR/bin:$PATH"
source "$_COMMON_SCRIPT_DIR/common/gum_utils.sh"

is_installed() {
    # command -v "$1" &> /dev/null
    pacman -Q "$1" &>/dev/null
}

