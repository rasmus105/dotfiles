# Script Options

SELECTED_PREFIX=" "
PROMPT="Select Shell "

####

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
source "$SCRIPT_DIR/common.sh"

# Get current shell
CURRENT_SHELL=$(basename "$(getent passwd "$USER" | cut -d: -f7)")

# Available shells
ALL_SHELLS="zsh
bash
fish"

# Create options with prefix for current shell
shell_options=""
while IFS= read -r shell; do
    if [ "$shell" = "$CURRENT_SHELL" ]; then
        shell_options+="$SELECTED_PREFIX$shell\n"
    else
        shell_options+="  $shell\n"
    fi
done <<<"$ALL_SHELLS"

# Show menu and capture selection
SELECTED=$(menu "$PROMPT" "$shell_options")

# If a shell was selected, remove prefix and run command
if [ -n "$SELECTED" ]; then
    SELECTED_SHELL=$(echo "$SELECTED" | sed "s/^[$SELECTED_PREFIX]//")
    ghostty --class=TUI.float -e "$HOME/.local/bin/system-setup shell" "$SELECTED_SHELL"
fi
