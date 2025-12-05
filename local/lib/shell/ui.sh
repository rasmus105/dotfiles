#!/usr/bin/env bash
# UI Library for dotfiles system
# Provides a split-screen TUI with command history, output streaming, and progress tracking
# Works on bare Linux console and modern terminal emulators

set -euo pipefail

#──────────────────────────────────────────────────────────────────────────────
# State Variables
#──────────────────────────────────────────────────────────────────────────────

declare -g -a UI_HISTORY=()   # Array of completed commands: "icon|description|duration|status"
declare -g UI_CURRENT_STEP=0  # Current step number
declare -g UI_TOTAL_STEPS=0   # Total number of steps
declare -g UI_CURRENT_CMD=""  # Currently executing command description
declare -g UI_CURRENT_START=0 # Start time of current command
declare -g UI_LOG_FILE="/tmp/dotfiles-output.log"
declare -g UI_MONITOR_PID="" # Background monitor process PID
declare -g UI_IS_TTY=1       # Whether we're in a TTY (fancy UI enabled)
declare -g UI_ENABLED=0      # Whether UI has been initialized

# Color configuration (set via ui_init)
declare -g UI_COLOR_SUCCESS="" # Green for success (✓)
declare -g UI_COLOR_ERROR=""   # Red for errors (✗)
declare -g UI_COLOR_PENDING="" # Yellow for in-progress (⊙)
declare -g UI_COLOR_INFO=""    # Cyan for info/progress
declare -g UI_COLOR_MUTED=""   # Gray for dimmed text
declare -g UI_COLOR_RESET=""   # Reset to default

# Terminal dimensions (updated on resize)
declare -g UI_TERM_LINES=0
declare -g UI_TERM_COLS=0

# ANSI escape codes
declare -g -r ANSI_SAVE_CURSOR=$'\033[s'
declare -g -r ANSI_RESTORE_CURSOR=$'\033[u'
declare -g -r ANSI_CLEAR_LINE=$'\033[2K'
declare -g -r ANSI_HIDE_CURSOR=$'\033[?25l'
declare -g -r ANSI_SHOW_CURSOR=$'\033[?25h'
declare -g -r ANSI_RESET=$'\033[0m'
declare -g -r ANSI_DIM=$'\033[2m'

#──────────────────────────────────────────────────────────────────────────────
# Public API
#──────────────────────────────────────────────────────────────────────────────

# Initialize the UI system
# Usage: ui_init <total_steps> [color_scheme]
#   color_scheme: "basic" (8 ANSI colors) or "theme" (uses current theme colors)
#   Default: "basic"
ui_init() {
    local total_steps=${1:-1}
    local color_scheme=${2:-basic}

    UI_TOTAL_STEPS=$total_steps
    UI_CURRENT_STEP=0
    UI_HISTORY=()
    UI_CURRENT_CMD=""
    UI_ENABLED=1

    # Detect if we're in a TTY
    if [ ! -t 1 ]; then
        UI_IS_TTY=0
        return # Disable fancy UI if output is piped
    fi

    # Check terminal size
    UI_TERM_LINES=$(tput lines 2>/dev/null || echo 24)
    UI_TERM_COLS=$(tput cols 2>/dev/null || echo 80)

    # Disable fancy UI if terminal is too small
    if [ "$UI_TERM_LINES" -lt 15 ] || [ "$UI_TERM_COLS" -lt 60 ]; then
        UI_IS_TTY=0
        echo "Terminal too small for fancy UI, using simple mode" >&2
        return
    fi

    # Set color scheme
    _ui_set_colors "$color_scheme"

    # Create/clear log file
    : >"$UI_LOG_FILE"

    # Setup terminal
    printf "%s" "$ANSI_HIDE_CURSOR"

    # Set up traps for cleanup
    trap ui_cleanup EXIT INT TERM
    trap '_ui_handle_resize' WINCH

    # Start background monitor
    _ui_start_monitor
}

# Run a command with UI integration
# Usage: ui_run "Description" command args...
# Returns: Command exit code
ui_run() {
    local desc="$1"
    shift

    # Simple mode: just run it
    if [ $UI_IS_TTY -eq 0 ] || [ $UI_ENABLED -eq 0 ]; then
        echo "→ $desc"
        "$@"
        return $?
    fi

    # Record start
    UI_CURRENT_CMD="$desc"
    UI_CURRENT_START=$(date +%s)

    # Clear log for this command
    : >"$UI_LOG_FILE"

    # Run command, stream to log
    "$@" >>"$UI_LOG_FILE" 2>&1
    local exit_code=$?

    # Calculate duration
    local end_time=$(date +%s)
    local duration=$((end_time - UI_CURRENT_START))
    local duration_str=$(_ui_format_duration $duration)

    # Update history based on exit code
    if [ $exit_code -eq 0 ]; then
        UI_HISTORY+=("✓|$desc|$duration_str|success")
    else
        UI_HISTORY+=("✗|$desc|$duration_str|failed")
    fi

    UI_CURRENT_STEP=$((UI_CURRENT_STEP + 1))
    UI_CURRENT_CMD=""

    return $exit_code
}

# Run a command and abort on failure
# Usage: ui_run_or_abort "Description" command args...
ui_run_or_abort() {
    ui_run "$@" || {
        local exit_code=$?
        _ui_stop_monitor
        printf "%s" "$ANSI_SHOW_CURSOR"
        echo ""
        echo "ERROR: Command failed with exit code $exit_code"
        echo "Aborting."
        exit $exit_code
    }
}

# Run a command and continue on failure (marks as failed in history)
# Usage: ui_run_continue "Description" command args...
ui_run_continue() {
    ui_run "$@" || true
}

# Run a command and prompt user on failure
# Usage: ui_run_or_prompt "Description" command args...
# Returns: 0 if command succeeded or user chose to continue, 1 if user chose to abort
ui_run_or_prompt() {
    local desc="$1"
    shift

    ui_run "$desc" "$@" || {
        local exit_code=$?

        if [ $UI_IS_TTY -eq 0 ] || [ $UI_ENABLED -eq 0 ]; then
            echo "Command failed with exit code $exit_code"
            echo "Continue anyway? (y/N)"
            read -r response
            if [[ ! "$response" =~ ^[Yy] ]]; then
                return 1
            fi
            return 0
        fi

        _ui_stop_monitor

        echo ""
        echo "Command failed with exit code $exit_code"
        echo ""

        # Show last 10 lines of output for context
        echo "Last few lines of output:"
        tail -n 10 "$UI_LOG_FILE" 2>/dev/null | sed 's/^/  /' || true
        echo ""

        local choice
        if command -v gum &>/dev/null; then
            choice=$(gum choose "Retry" "Continue anyway" "Abort" --header "What would you like to do?")
        else
            echo "1) Retry"
            echo "2) Continue anyway"
            echo "3) Abort"
            read -p "Choice (1-3): " choice
            case $choice in
            1) choice="Retry" ;;
            2) choice="Continue anyway" ;;
            3) choice="Abort" ;;
            *) choice="Abort" ;;
            esac
        fi

        _ui_start_monitor

        case "$choice" in
        "Retry")
            # Retry the command
            ui_run_or_prompt "$desc" "$@"
            return $?
            ;;
        "Continue anyway")
            return 0
            ;;
        "Abort" | *)
            ui_cleanup
            exit 1
            ;;
        esac
    }
}

# Prompt for confirmation (yes/no)
# Usage: ui_prompt_confirm "Question?" && do_something
# Returns: 0 for yes, 1 for no
ui_prompt_confirm() {
    local question="$1"

    if [ $UI_IS_TTY -eq 0 ] || [ $UI_ENABLED -eq 0 ]; then
        read -p "$question (y/N) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
        return $?
    fi

    _ui_stop_monitor

    local result=1
    if command -v gum &>/dev/null; then
        gum confirm "$question" && result=0 || result=1
    else
        read -p "$question (y/N) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && result=0 || result=1
    fi

    _ui_start_monitor

    return $result
}

# Prompt for selection from a list
# Usage: choice=$(ui_prompt_select "Choose option" opt1 opt2 opt3)
ui_prompt_select() {
    local question="$1"
    shift
    local options=("$@")

    if [ $UI_IS_TTY -eq 0 ] || [ $UI_ENABLED -eq 0 ]; then
        echo "$question"
        select opt in "${options[@]}"; do
            if [ -n "$opt" ]; then
                echo "$opt"
                return 0
            fi
        done
        return 1
    fi

    _ui_stop_monitor

    local choice
    if command -v gum &>/dev/null; then
        choice=$(gum choose "${options[@]}" --header "$question")
    else
        echo "$question"
        select opt in "${options[@]}"; do
            if [ -n "$opt" ]; then
                choice="$opt"
                break
            fi
        done
    fi

    _ui_start_monitor

    echo "$choice"
}

# Prompt for multiple selections
# Usage: choices=$(ui_prompt_multiselect "Choose options" opt1 opt2 opt3)
#        Returns selections separated by newlines
ui_prompt_multiselect() {
    local question="$1"
    shift
    local options=("$@")

    if [ $UI_IS_TTY -eq 0 ] || [ $UI_ENABLED -eq 0 ]; then
        echo "$question (enter numbers separated by spaces)"
        local i=1
        for opt in "${options[@]}"; do
            echo "$i) $opt"
            ((i++))
        done
        read -r -a selections
        for sel in "${selections[@]}"; do
            if [ "$sel" -ge 1 ] && [ "$sel" -le "${#options[@]}" ]; then
                echo "${options[$((sel - 1))]}"
            fi
        done
        return 0
    fi

    _ui_stop_monitor

    local choices
    if command -v gum &>/dev/null; then
        choices=$(gum choose --no-limit "${options[@]}" --header "$question")
    else
        echo "$question (enter numbers separated by spaces)"
        local i=1
        for opt in "${options[@]}"; do
            echo "$i) $opt"
            ((i++))
        done
        read -r -a selections
        for sel in "${selections[@]}"; do
            if [ "$sel" -ge 1 ] && [ "$sel" -le "${#options[@]}" ]; then
                echo "${options[$((sel - 1))]}"
            fi
        done
    fi

    _ui_start_monitor

    echo "$choices"
}

# Prompt for text input
# Usage: value=$(ui_prompt_input "Enter value" "default")
ui_prompt_input() {
    local question="$1"
    local default="${2:-}"

    if [ $UI_IS_TTY -eq 0 ] || [ $UI_ENABLED -eq 0 ]; then
        if [ -n "$default" ]; then
            read -p "$question [$default]: " -r value
            echo "${value:-$default}"
        else
            read -p "$question: " -r value
            echo "$value"
        fi
        return 0
    fi

    _ui_stop_monitor

    local value
    if command -v gum &>/dev/null; then
        if [ -n "$default" ]; then
            value=$(gum input --placeholder "$default" --prompt "$question: " --value "$default")
        else
            value=$(gum input --prompt "$question: ")
        fi
    else
        if [ -n "$default" ]; then
            read -p "$question [$default]: " -r value
            value="${value:-$default}"
        else
            read -p "$question: " -r value
        fi
    fi

    _ui_start_monitor

    echo "$value"
}

# Cleanup and restore terminal
ui_cleanup() {
    if [ $UI_ENABLED -eq 0 ]; then
        return
    fi

    _ui_stop_monitor
    printf "%s" "$ANSI_SHOW_CURSOR"

    # Clear traps
    trap - EXIT INT TERM WINCH

    # Show final summary if there's history
    if [ ${#UI_HISTORY[@]} -gt 0 ] && [ $UI_IS_TTY -eq 1 ]; then
        echo ""
        echo "──────────────────────────────────────"
        echo "Summary:"
        echo "──────────────────────────────────────"
        for entry in "${UI_HISTORY[@]}"; do
            IFS='|' read -r icon desc time status <<<"$entry"
            case $icon in
            ✓) printf "%s" "$UI_COLOR_SUCCESS" ;;
            ✗) printf "%s" "$UI_COLOR_ERROR" ;;
            ⊙) printf "%s" "$UI_COLOR_PENDING" ;;
            esac
            printf "%s %s %s%s\n" "$icon" "$desc" "${time:+($time)}" "$UI_COLOR_RESET"
        done
        echo "──────────────────────────────────────"
    fi

    UI_ENABLED=0
}

#──────────────────────────────────────────────────────────────────────────────
# Internal Functions
#──────────────────────────────────────────────────────────────────────────────

# Set color scheme based on configuration
_ui_set_colors() {
    local scheme=${1:-basic}

    if [ "$scheme" = "basic" ]; then
        # Basic ANSI colors (work everywhere)
        UI_COLOR_SUCCESS=$'\033[32m' # Green
        UI_COLOR_ERROR=$'\033[31m'   # Red
        UI_COLOR_PENDING=$'\033[33m' # Yellow
        UI_COLOR_INFO=$'\033[36m'    # Cyan
        UI_COLOR_MUTED=$'\033[90m'   # Bright black (gray)
        UI_COLOR_RESET=$'\033[0m'
    else
        # Theme-based colors (future enhancement)
        # For now, fall back to basic
        UI_COLOR_SUCCESS=$'\033[32m'
        UI_COLOR_ERROR=$'\033[31m'
        UI_COLOR_PENDING=$'\033[33m'
        UI_COLOR_INFO=$'\033[36m'
        UI_COLOR_MUTED=$'\033[90m'
        UI_COLOR_RESET=$'\033[0m'
    fi
}

# Format duration in human-readable format
_ui_format_duration() {
    local seconds=$1

    if [ $seconds -lt 60 ]; then
        echo "${seconds}s"
    else
        local mins=$((seconds / 60))
        local secs=$((seconds % 60))
        echo "${mins}m ${secs}s"
    fi
}

# Start background monitor process
_ui_start_monitor() {
    if [ $UI_IS_TTY -eq 0 ] || [ -n "$UI_MONITOR_PID" ]; then
        return
    fi

    (
        while true; do
            _ui_draw_screen
            sleep 0.1
        done
    ) &
    UI_MONITOR_PID=$!
}

# Stop background monitor process
_ui_stop_monitor() {
    if [ -n "$UI_MONITOR_PID" ]; then
        kill "$UI_MONITOR_PID" 2>/dev/null || true
        wait "$UI_MONITOR_PID" 2>/dev/null || true
        UI_MONITOR_PID=""

        # Clear the screen
        clear
    fi
}

# Handle terminal resize
_ui_handle_resize() {
    UI_TERM_LINES=$(tput lines 2>/dev/null || echo 24)
    UI_TERM_COLS=$(tput cols 2>/dev/null || echo 80)

    # Disable UI if terminal becomes too small
    if [ "$UI_TERM_LINES" -lt 15 ] || [ "$UI_TERM_COLS" -lt 60 ]; then
        if [ $UI_IS_TTY -eq 1 ]; then
            UI_IS_TTY=0
            _ui_stop_monitor
            echo "Terminal too small, switching to simple mode"
        fi
    fi
}

# Draw the entire screen (called by background monitor)
_ui_draw_screen() {
    # Calculate region heights (as percentage of terminal)
    local history_lines=$((UI_TERM_LINES * 20 / 100))
    local status_lines=3
    local output_lines=$((UI_TERM_LINES - history_lines - status_lines - 2)) # -2 for separators

    # Ensure minimum sizes
    [ $history_lines -lt 3 ] && history_lines=3
    [ $output_lines -lt 5 ] && output_lines=5

    # Move to top-left and clear screen
    tput cup 0 0 2>/dev/null || printf "\033[H" # Fallback to ANSI
    tput ed 2>/dev/null || printf "\033[J"      # Clear to end, fallback to ANSI

    # Draw history region
    _ui_draw_history $history_lines

    # Draw separator
    _ui_draw_separator

    # Draw output region
    _ui_draw_output $output_lines

    # Draw separator
    _ui_draw_separator

    # Draw status bar
    _ui_draw_status
}

# Draw command history region
_ui_draw_history() {
    local max_lines=$1

    # Calculate how many history entries to show
    local history_count=${#UI_HISTORY[@]}
    local start=0

    if [ "$history_count" -gt "$max_lines" ]; then
        start=$((history_count - max_lines))
    fi

    # Show history entries
    for ((i = start; i < history_count; i++)); do
        local entry="${UI_HISTORY[$i]}"
        IFS='|' read -r icon desc time status <<<"$entry"

        # Set color based on icon
        case $icon in
        ✓) printf "%s" "$UI_COLOR_SUCCESS" ;;
        ✗) printf "%s" "$UI_COLOR_ERROR" ;;
        ⊙) printf "%s" "$UI_COLOR_PENDING" ;;
        esac

        # Format and truncate if needed
        local line="$icon $desc ${time:+($time)}"
        if [ ${#line} -gt $UI_TERM_COLS ]; then
            line="${line:0:$((UI_TERM_COLS - 3))}..."
        fi

        printf "%s%s\n" "$line" "$UI_COLOR_RESET"
    done

    # Show current command if running
    if [ -n "$UI_CURRENT_CMD" ]; then
        local elapsed=$(($(date +%s) - UI_CURRENT_START))
        local elapsed_str=$(_ui_format_duration $elapsed)

        printf "%s" "$UI_COLOR_PENDING"
        local line="⊙ $UI_CURRENT_CMD ($elapsed_str)"
        if [ ${#line} -gt $UI_TERM_COLS ]; then
            line="${line:0:$((UI_TERM_COLS - 3))}..."
        fi
        printf "%s%s\n" "$line" "$UI_COLOR_RESET"
    fi
}

# Draw separator line
_ui_draw_separator() {
    printf "%s" "$UI_COLOR_MUTED"
    printf "─%.0s" $(seq 1 $UI_TERM_COLS)
    printf "%s\n" "$UI_COLOR_RESET"
}

# Draw command output region
_ui_draw_output() {
    local max_lines=$1

    # Read last N lines from log file
    if [ -f "$UI_LOG_FILE" ]; then
        mapfile -t lines < <(tail -n "$max_lines" "$UI_LOG_FILE" 2>/dev/null || true)

        for line in "${lines[@]}"; do
            # Truncate if too long
            if [ ${#line} -gt $((UI_TERM_COLS - 2)) ]; then
                line="${line:0:$((UI_TERM_COLS - 5))}..."
            fi

            # Print with muted color and indentation
            printf "%s  %s%s\n" "$UI_COLOR_MUTED" "$line" "$UI_COLOR_RESET"
        done
    fi
}

# Draw status bar (progress and keybindings)
_ui_draw_status() {
    # Progress bar
    local percent=0
    if [ $UI_TOTAL_STEPS -gt 0 ]; then
        percent=$((UI_CURRENT_STEP * 100 / UI_TOTAL_STEPS))
    fi

    local bar_width=$((UI_TERM_COLS - 20))
    [ $bar_width -lt 10 ] && bar_width=10

    local filled=$((bar_width * percent / 100))
    local empty=$((bar_width - filled))

    printf "%s" "$UI_COLOR_INFO"
    printf "━%.0s" $(seq 1 $filled)
    printf "─%.0s" $(seq 1 $empty)
    printf " %3d%% (%d/%d)%s\n" $percent $UI_CURRENT_STEP $UI_TOTAL_STEPS "$UI_COLOR_RESET"

    # Keybindings
    printf "%s^C Cancel  ^Z Background%s\n" "$ANSI_DIM" "$UI_COLOR_RESET"
}

#──────────────────────────────────────────────────────────────────────────────
# Export functions for use in other scripts
#──────────────────────────────────────────────────────────────────────────────

# If sourced, export all public functions
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
    export -f ui_init
    export -f ui_run
    export -f ui_run_or_abort
    export -f ui_run_continue
    export -f ui_run_or_prompt
    export -f ui_prompt_confirm
    export -f ui_prompt_select
    export -f ui_prompt_multiselect
    export -f ui_prompt_input
    export -f ui_cleanup
fi
