#!/bin/bash
#
# Gum Utilities Library
# Source this file in your scripts: source ./gum-utils.sh
#

GUM_UTILS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

# Check if gum is installed
gum_check() {
    if ! command -v gum &>/dev/null; then
        echo "Error: 'gum' is not installed."
        echo "Install it from: https://github.com/charmbracelet/gum"
        exit 1
    fi
}

# Colors
GUM_COLOR_SUCCESS=2
GUM_COLOR_ERROR=196
GUM_COLOR_WARNING=214
GUM_COLOR_INFO=250
GUM_COLOR_ACCENT=212
GUM_COLOR_MUTED=240

# Styled messages
gum_success() {
    gum style --foreground "$GUM_COLOR_SUCCESS" "✓ $*"
}

gum_error() {
    gum style --foreground "$GUM_COLOR_ERROR" "✗ $*"
}

gum_warning() {
    gum style --foreground "$GUM_COLOR_WARNING" "⚠ $*"
}

gum_info() {
    gum style --foreground "$GUM_COLOR_INFO" "→ $*"
}

gum_muted() {
    gum style --foreground "$GUM_COLOR_MUTED" "$*"
}

# Header with border
gum_header() {
    local title="$1"
    local subtitle="$2"

    if [ -n "$subtitle" ]; then
        gum style \
            --foreground "$GUM_COLOR_ACCENT" \
            --border double \
            --border-foreground "$GUM_COLOR_ACCENT" \
            --align center \
            --width 80 \
            --margin "1 2" \
            --padding "1 2" \
            "$title" "$subtitle"
    else
        gum style \
            --foreground "$GUM_COLOR_ACCENT" \
            --border double \
            --border-foreground "$GUM_COLOR_ACCENT" \
            --align center \
            --width 80 \
            --margin "1 2" \
            --padding "1 2" \
            "$title"
    fi
}

# Simple section header
gum_section() {
    gum style --foreground "$GUM_COLOR_ACCENT" --bold "$*"
}

# Confirmation prompt (returns 0 for yes, 1 for no)
gum_confirm() {
    local prompt="${1:-Proceed?}"
    gum confirm "$prompt" && return 0 || return 1
}

# Confirmation with custom buttons
gum_confirm_custom() {
    local prompt="$1"
    local yes_text="${2:-Yes}"
    local no_text="${3:-No}"
    gum confirm --affirmative="$yes_text" --negative="$no_text" "$prompt"
}

# Single choice menu
gum_choose() {
    gum choose "$@"
}

# Multi-choice menu
gum_choose_multiple() {
    gum choose --no-limit "$@"
}

# Text input
gum_input() {
    local placeholder="${1:-Enter value}"
    gum input --placeholder "$placeholder"
}

# Text input with prompt
gum_input_prompt() {
    local prompt="$1"
    local placeholder="$2"
    gum input --prompt "$prompt " --placeholder "$placeholder"
}

# Password input
gum_input_password() {
    local placeholder="${1:-Enter password}"
    gum input --password --placeholder "$placeholder"
}

# Spinner with command
gum_spin() {
    local title="${1:-Processing...}"
    local cmd="$2"

    if [ -z "$cmd" ]; then
        # Just show spinner for 1 second
        gum spin --spinner dot --title "$title" -- sleep 1
    else
        gum spin --spinner dot --title "$title" -- bash -c "$cmd"
    fi
}

# Fuzzy filter
gum_filter() {
    gum filter "$@"
}

# Box with border
gum_box() {
    local content="$1"
    gum style \
        --border normal \
        --padding "1 2" \
        --border-foreground "$GUM_COLOR_ACCENT" \
        "$content"
}

# Colored box
gum_box_colored() {
    local content="$1"
    local color="${2:-$GUM_COLOR_INFO}"
    gum style \
        --border normal \
        --padding "1 2" \
        --border-foreground "$color" \
        "$content"
}

# Bold text
gum_bold() {
    gum style --bold "$*"
}

# Italic text
gum_italic() {
    gum style --italic "$*"
}

# Ask yes/no with default (like [Y/n])
gum_ask_yes() {
    local prompt="$1"
    gum confirm "$prompt" --default=true
}

gum_ask_no() {
    local prompt="$1"
    gum confirm "$prompt" --default=false
}

# Non-interactive mode wrappers
# These functions support USE_DEFAULT_OPTIONS for automated testing
# Note: defaults are MANDATORY to force callers to think about test behavior

# Wrapper for gum confirm with mandatory default
# Usage: gum_confirm_default "prompt" <default_yes_or_no>
gum_confirm_default() {
    local prompt="$1"
    local default="$2"

    if [[ -z "$default" ]]; then
        gum_error "gum_confirm_default requires a default value (true/false)"
        exit 1
    fi

    if [[ "$USE_DEFAULT_OPTIONS" == "1" ]]; then
        if [[ "$default" == "true" ]]; then
            gum_info "$prompt (auto: yes)"
            return 0
        else
            gum_info "$prompt (auto: no)"
            return 1
        fi
    fi

    if [[ "$default" == "true" ]]; then
        gum_ask_yes "$prompt"
    else
        gum_ask_no "$prompt"
    fi
}

# Wrapper for gum input with mandatory default
# Usage: gum_input_default "prompt" "<default_value>"
gum_input_default() {
    local prompt="$1"
    local default="$2"

    if [[ -z "$default" ]]; then
        gum_error "gum_input_default requires a default value"
        exit 1
    fi

    if [[ "$USE_DEFAULT_OPTIONS" == "1" ]]; then
        gum_info "$prompt (auto: $default)"
        echo "$default"
        return 0
    fi

    local result
    result=$(gum_input_prompt "$prompt" "$default")
    echo "${result:-$default}"
}

gum_show () {
    echo
    gum spin --spinner "dot" --title "Done! Press any key to close..." -- bash -c 'read -n 1 -s'
}
