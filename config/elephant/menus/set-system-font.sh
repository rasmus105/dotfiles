# Script Options

SELECTED_PREFIX=" "
PROMPT="Select Font "

####

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/common.sh"

CURRENT_FONT=$(bash -c "$HOME/.local/bin/system-theme font get")
ALL_FONTS=$(bash -c "$HOME/.local/bin/system-theme font list")

FONT_OPTIONS=$(echo "$ALL_FONTS" | sed "s/^${CURRENT_FONT}$/${SELECTED_PREFIX}${CURRENT_FONT}/")
# FONT_OPTIONS=${ALL_FONTS//$CURRENT_FONT/$SELECTED_PREFIX$CURRENT_FONT}

SELECTED=$(menu "$PROMPT" "$FONT_OPTIONS")

if [ -n "$SELECTED" ] && ! echo "$SELECTED" | grep -q "$SELECTED_PREFIX"; then
    run-notify system-theme font set "$SELECTED"
fi
