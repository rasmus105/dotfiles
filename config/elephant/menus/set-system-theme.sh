# Script Options

PREFIX=" "
PROMPT="Select Colorscheme "

#####
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/common.sh"

THEMES_DIR="$HOME/.config/themes/"
CURRENT_THEME_DIR="$HOME/.config/theme"
CURRENT_THEME=$(basename "$(readlink "$CURRENT_THEME_DIR")")
ALL_THEMES=$(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | sort | grep -Eo "[^/]+$")

# Create options with prefix for current theme
themes_options=""
while IFS= read -r theme; do
    pretty_theme=$(echo "$theme" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))}1')
    if [ "$theme" = "$CURRENT_THEME" ]; then
        themes_options+="$PREFIX$pretty_theme\n"
    else
        themes_options+="  $pretty_theme\n"
    fi
done <<<"$ALL_THEMES"

# Show menu and capture selection
SELECTED=$(menu "$PROMPT" "$themes_options")

# If a theme was selected, convert back to original format and run command
if [ -n "$SELECTED" ]; then
    # Remove prefix and convert back to kebab-case
    SELECTED_THEME=$(echo "$SELECTED" | sed "s/^[$PREFIX]*//" | awk '{for(i=1;i<=NF;i++) $i=tolower($i)}1' | sed 's/ /-/g')

    # Run the theme setter command
    "$HOME/.local/bin/system-set-theme" "$SELECTED_THEME"
fi
