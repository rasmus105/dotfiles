_COMMON_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
_COMMON_DOTFILES_DIR=$(dirname "$_COMMON_SCRIPT_DIR")

source "$_COMMON_SCRIPT_DIR/common/gum_utils.sh"

is_installed() {
    command -v "$1" &> /dev/null
}

