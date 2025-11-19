_COMMON_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
_COMMON_DOTFILES_DIR=$(dirname "$_COMMON_SCRIPT_DIR")

# Public helper: ensure gum is installed
ensure_gum() {
    if ! command -v gum &>/dev/null; then
        echo "Installing gum for cleaner UI..."
        sudo pacman -S --noconfirm gum
    fi
}

# Public helper: add dotfiles bin to PATH
add_dotfiles_bin_to_path() {
    case ":$PATH:" in
        *":$_COMMON_DOTFILES_DIR/bin:"*) ;; # already present
        *) export PATH="$_COMMON_DOTFILES_DIR/bin:$PATH" ;;
    esac
}

# Gum UI utilities (no side effects on source)
source "$_COMMON_SCRIPT_DIR/common/gum_utils.sh"

# Non-interactive mode support
# Set USE_DEFAULT_OPTIONS=1 to skip all prompts and use defaults
export USE_DEFAULT_OPTIONS="${USE_DEFAULT_OPTIONS:-0}"

# Package helper
is_installed() {
    # command -v "$1" &> /dev/null
    pacman -Q "$1" &>/dev/null
}
