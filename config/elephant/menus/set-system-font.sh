# Script Options

SELECTED_PREFIX=" "
PROMPT="Select Font "

####

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/common.sh"

CURRENT_FONT=$(bash "$HOME/.local/bin/system-get-font")
ALL_FONTS=$(bash "$HOME/.local/bin/system-list-fonts")

FONT_OPTIONS=$(echo "$ALL_FONTS" | sed "s/^${CURRENT_FONT}$/${SELECTED_PREFIX}${CURRENT_FONT}/")

SELECTED=$(menu "$PROMPT" "$FONT_OPTIONS")

if [ -n "$SELECTED" ] && ! echo "$SELECTED" | grep -q "$SELECTED_PREFIX"; then
    bash "$HOME/.local/bin/system-set-font" "$SELECTED"
fi
