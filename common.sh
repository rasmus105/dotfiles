_COMMON_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
_COMMON_DOTFILES_DIR=$(dirname "$_COMMON_SCRIPT_DIR")

# Non-interactive mode support
# Set USE_DEFAULT_OPTIONS=1 to skip all prompts and use defaults
export USE_DEFAULT_OPTIONS="${USE_DEFAULT_OPTIONS:-0}"

source "$_COMMON_SCRIPT_DIR/common/gum_utils.sh"

is_installed() {
    command -v "$1" &> /dev/null
}

