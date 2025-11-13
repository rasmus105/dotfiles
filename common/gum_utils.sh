#!/bin/bash
#
# Gum Utilities Library
# Source this file in your scripts: source ./gum-utils.sh
#

# Check if gum is installed
gum_check() {
    if ! command -v gum &> /dev/null; then
        echo "Error: 'gum' is not installed."
        echo "Install it from: https://github.com/charmbracelet/gum"
        exit 1
    fi
}

# Colors
GUM_COLOR_SUCCESS=2
GUM_COLOR_ERROR=196
GUM_COLOR_WARNING=214
GUM_COLOR_INFO=39
GUM_COLOR_ACCENT=212
GUM_COLOR_MUTED=246

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
            --width 50 \
            --margin "1 2" \
            --padding "1 2" \
            "$title" "$subtitle"
    else
        gum style \
            --foreground "$GUM_COLOR_ACCENT" \
            --border double \
            --border-foreground "$GUM_COLOR_ACCENT" \
            --align center \
            --width 50 \
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
    gum confirm "$prompt"
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

# Different spinner styles
gum_spin_line() {
    local title="$1"
    local cmd="$2"
    gum spin --spinner line --title "$title" -- bash -c "$cmd"
}

gum_spin_dots() {
    local title="$1"
    local cmd="$2"
    gum spin --spinner dots --title "$title" -- bash -c "$cmd"
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

# Progress bar (manual stepping)
gum_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    local percent=$((current * 100 / total))
    gum style --foreground "$GUM_COLOR_INFO" "[$current/$total] $message ($percent%)"
}

# Format text with optional color
gum_format() {
    local text="$1"
    local color="${2:-$GUM_COLOR_INFO}"
    gum style --foreground "$color" "$text"
}

# Bold text
gum_bold() {
    gum style --bold "$*"
}

# Italic text  
gum_italic() {
    gum style --italic "$*"
}

# Separator line
gum_separator() {
    local char="${1:--}"
    local width="${2:-50}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
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

# Wrapper for gum choose with mandatory default
# Usage: gum_choose_default "prompt" <default_index> option1 option2 ...
gum_choose_default() {
    local prompt="$1"
    local default_index="$2"
    
    if [[ -z "$default_index" ]]; then
        gum_error "gum_choose_default requires a default index"
        exit 1
    fi
    
    shift 2
    local options=("$@")
    
    if [[ "$USE_DEFAULT_OPTIONS" == "1" ]]; then
        local selected="${options[$default_index]}"
        gum_info "$prompt (auto: $selected)"
        echo "$selected"
        return 0
    fi
    
    gum_section "$prompt"
    gum_choose "${options[@]}"
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

# Setup logging directory
INSTALL_LOG_DIR="${INSTALL_LOG_DIR:-$HOME/.dotfiles/install/logs}"
INSTALL_LOG_FILE="${INSTALL_LOG_FILE:-$INSTALL_LOG_DIR/install-$(date +%Y%m%d_%H%M%S).log}"

# Initialize logging
gum_log_init() {
    mkdir -p "$INSTALL_LOG_DIR"
    echo "Installation started at $(date)" > "$INSTALL_LOG_FILE"
    echo "======================================" >> "$INSTALL_LOG_FILE"
    echo "" >> "$INSTALL_LOG_FILE"
}

# Run command with spinner and redirect output to log
# Usage: gum_run "Installing package..." "pacman -S package"
# Returns the exit code of the command
gum_run() {
    local title="$1"
    local cmd="$2"
    
    # Ensure log file exists
    if [[ ! -f "$INSTALL_LOG_FILE" ]]; then
        gum_log_init
    fi
    
    # Log the command being run
    {
        echo ""
        echo ">>> Running: $title"
        echo ">>> Command: $cmd"
        echo ">>> Time: $(date)"
        echo "---"
    } >> "$INSTALL_LOG_FILE"
    
    # Create temporary script
    local temp_script=$(mktemp)
    
    # Disable TTY detection so commands output plain text without progress bars
    # This prevents ANSI escape codes and carriage returns in logs
    cat > "$temp_script" << 'SCRIPT_EOF'
#!/bin/bash
# Force non-interactive mode for common tools
export TERM=dumb
export GIT_TERMINAL_PROMPT=0
# Redirect output to log file
exec >> "$INSTALL_LOG_FILE" 2>&1
SCRIPT_EOF
    echo "$cmd" >> "$temp_script"
    chmod +x "$temp_script"
    
    # Run command with spinner
    local exit_code=0
    if gum spin --spinner dot --title "$title" -- "$temp_script"; then
        gum_success "$title"
    else
        exit_code=$?
        gum_error "$title (failed - check $INSTALL_LOG_FILE)"
        {
            echo ">>> Exit code: $exit_code"
            echo ">>> FAILED"
            echo ""
        } >> "$INSTALL_LOG_FILE"
        rm -f "$temp_script"
        return $exit_code
    fi
    
    {
        echo ">>> Success"
        echo ""
    } >> "$INSTALL_LOG_FILE"
    
    rm -f "$temp_script"
    return 0
}

# Run command quietly (no spinner, just log)
# Usage: gum_run_quiet "command to run"
gum_run_quiet() {
    local cmd="$1"
    
    # Ensure log file exists
    if [[ ! -f "$INSTALL_LOG_FILE" ]]; then
        gum_log_init
    fi
    
    {
        echo ""
        echo ">>> Running (quiet): $cmd"
        echo ">>> Time: $(date)"
        echo "---"
    } >> "$INSTALL_LOG_FILE"
    
    # Disable TTY detection for plain text output
    TERM=dumb GIT_TERMINAL_PROMPT=0 bash -c "$cmd" >> "$INSTALL_LOG_FILE" 2>&1
    local exit_code=$?
    
    {
        echo ">>> Exit code: $exit_code"
        echo ""
    } >> "$INSTALL_LOG_FILE"
    
    return $exit_code
}
