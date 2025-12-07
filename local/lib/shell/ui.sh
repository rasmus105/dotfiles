#!/usr/bin/env bash
# UI Library for dotfiles system
# Provides a split-screen TUI with command history, output streaming, and progress tracking
# Works on bare Linux console and modern terminal emulators
#
# Architecture: Single-process with on-demand redraw
# - No background monitor process
# - Redraws triggered by state changes
# - Output streaming via periodic log file checks during command execution

set -euo pipefail

#──────────────────────────────────────────────────────────────────────────────
# Configuration
#──────────────────────────────────────────────────────────────────────────────

readonly UI_MIN_LINES=15
readonly UI_MIN_COLS=60
readonly UI_REFRESH_INTERVAL=0.1  # Seconds between redraws during command execution
readonly UI_LOG_FILE="/tmp/dotfiles-output.log"

#──────────────────────────────────────────────────────────────────────────────
# State (single associative array for cleaner management)
#──────────────────────────────────────────────────────────────────────────────

declare -g -A UI_STATE=(
    [enabled]=0
    [is_tty]=1
    [current_step]=0
    [total_steps]=0
    [current_cmd]=""
    [current_start]=0
    [term_lines]=24
    [term_cols]=80
    [in_prompt]=0
)

# History stored as indexed array (bash doesn't support nested arrays)
# Format: "type|description|extra"
#   type: ok, err, input, select, confirm
declare -g -a UI_HISTORY=()

# ANSI escape codes
declare -g -r ESC=$'\033'
declare -g -r ANSI_HIDE_CURSOR="${ESC}[?25l"
declare -g -r ANSI_SHOW_CURSOR="${ESC}[?25h"
declare -g -r ANSI_ALT_SCREEN="${ESC}[?1049h"
declare -g -r ANSI_MAIN_SCREEN="${ESC}[?1049l"
declare -g -r ANSI_CLEAR="${ESC}[2J"
declare -g -r ANSI_HOME="${ESC}[H"
declare -g -r ANSI_RESET="${ESC}[0m"
declare -g -r ANSI_DIM="${ESC}[2m"

# Colors (initialized in ui_init)
declare -g UI_C_OK=""      # Green - success
declare -g UI_C_ERR=""     # Red - error
declare -g UI_C_WARN=""    # Yellow - in progress
declare -g UI_C_INFO=""    # Cyan - info
declare -g UI_C_DIM=""     # Gray - muted
declare -g UI_C_RST=""     # Reset

#──────────────────────────────────────────────────────────────────────────────
# Public API
#──────────────────────────────────────────────────────────────────────────────

# Initialize the UI system
# Usage: ui_init <total_steps> [color_scheme]
ui_init() {
    local total_steps=${1:-1}
    local color_scheme=${2:-basic}

    UI_STATE[total_steps]=$total_steps
    UI_STATE[current_step]=0
    UI_STATE[enabled]=1
    UI_HISTORY=()

    # Check if stdout is a terminal
    if [[ ! -t 1 ]]; then
        UI_STATE[is_tty]=0
        return
    fi

    # Get terminal dimensions
    _ui_update_dimensions

    # Check minimum size
    if (( UI_STATE[term_lines] < UI_MIN_LINES || UI_STATE[term_cols] < UI_MIN_COLS )); then
        UI_STATE[is_tty]=0
        echo "Terminal too small for TUI mode (need ${UI_MIN_COLS}x${UI_MIN_LINES}), using simple mode" >&2
        return
    fi

    # Initialize colors
    _ui_init_colors "$color_scheme"

    # Clear/create log file
    : > "$UI_LOG_FILE"

    # Setup terminal
    printf '%s%s%s' "$ANSI_ALT_SCREEN" "$ANSI_HIDE_CURSOR" "$ANSI_CLEAR"

    # Setup signal handlers
    trap '_ui_cleanup_handler' EXIT
    trap '_ui_cleanup_handler; exit 130' INT
    trap '_ui_cleanup_handler; exit 143' TERM
    trap '_ui_handle_resize' WINCH

    # Initial draw
    _ui_draw
}

# Run a command with UI integration
# Usage: ui_run "Description" command args...
# Returns: Command exit code
ui_run() {
    local desc="$1"
    shift

    if _ui_is_simple; then
        echo "-> $desc"
        "$@"
        return $?
    fi

    # Record start
    UI_STATE[current_cmd]="$desc"
    UI_STATE[current_start]=$(_ui_time_ms)

    # Clear log for this command
    : > "$UI_LOG_FILE"

    # Draw initial state
    _ui_draw

    # Run command with output monitoring
    local exit_code=0
    _ui_run_with_output "$@" || exit_code=$?

    # Calculate duration
    local end_time=$(_ui_time_ms)
    local duration=$(( end_time - UI_STATE[current_start] ))
    local duration_str=$(_ui_format_duration "$duration")

    # Update history
    if (( exit_code == 0 )); then
        UI_HISTORY+=("ok|$desc|$duration_str")
    else
        UI_HISTORY+=("err|$desc|$duration_str")
    fi

    # Update state
    (( UI_STATE[current_step]++ )) || true
    UI_STATE[current_cmd]=""
    UI_STATE[current_start]=0

    # Final draw for this command
    _ui_draw

    return $exit_code
}

# Run a command and abort on failure
ui_run_or_abort() {
    if ! ui_run "$@"; then
        local exit_code=$?
        ui_cleanup
        echo ""
        echo "ERROR: Command failed with exit code $exit_code"
        echo "Last output:"
        tail -n 10 "$UI_LOG_FILE" 2>/dev/null | sed 's/^/  /' || true
        exit $exit_code
    fi
}

# Run a command and continue on failure
ui_run_continue() {
    ui_run "$@" || true
}

# Run a command and prompt user on failure
ui_run_or_prompt() {
    local desc="$1"
    shift

    if ui_run "$desc" "$@"; then
        return 0
    fi

    local exit_code=$?

    if _ui_is_simple; then
        echo "Command failed with exit code $exit_code"
        read -rp "Continue anyway? (y/N) " response
        [[ "$response" =~ ^[Yy] ]] && return 0
        return 1
    fi

    # Show prompt in overlay
    UI_STATE[in_prompt]=1
    printf '%s' "$ANSI_SHOW_CURSOR"
    
    # Temporarily disable our signal handlers for clean Ctrl+C
    trap - INT TERM
    
    local choice
    choice=$(_ui_prompt_failure "$exit_code")
    
    # Restore signal handlers
    trap '_ui_cleanup_handler; exit 130' INT
    trap '_ui_cleanup_handler; exit 143' TERM
    
    printf '%s' "$ANSI_HIDE_CURSOR"
    _ui_draw
    UI_STATE[in_prompt]=0

    case "$choice" in
        retry)
            ui_run_or_prompt "$desc" "$@"
            return $?
            ;;
        continue)
            return 0
            ;;
        *)
            ui_cleanup
            exit 1
            ;;
    esac
}

# Prompt for confirmation
# Usage: ui_prompt_confirm "Question?" && do_something
ui_prompt_confirm() {
    local question="$1"

    if _ui_is_simple; then
        read -rp "$question (y/N) " -n 1 reply
        echo
        [[ "$reply" =~ ^[Yy]$ ]]
        return $?
    fi

    local result
    result=$(_ui_with_prompt_overlay _ui_do_confirm "$question")
    
    # Record in history
    if [[ "$result" == "yes" ]]; then
        UI_HISTORY+=("confirm|$question|Yes")
        return 0
    else
        UI_HISTORY+=("confirm|$question|No")
        return 1
    fi
}

# Prompt for selection from a list
# Usage: choice=$(ui_prompt_select "Choose option" opt1 opt2 opt3)
ui_prompt_select() {
    local question="$1"
    shift

    if _ui_is_simple; then
        _ui_select_fallback "$question" "$@"
        return $?
    fi

    local result
    result=$(_ui_with_prompt_overlay _ui_do_select "$question" "$@")
    
    # Record in history and output
    UI_HISTORY+=("select|$question|$result")
    echo "$result"
}

# Prompt for multiple selections
# Usage: choices=$(ui_prompt_multiselect "Choose options" opt1 opt2 opt3)
ui_prompt_multiselect() {
    local question="$1"
    shift

    if _ui_is_simple; then
        _ui_multiselect_fallback "$question" "$@"
        return $?
    fi

    local result
    result=$(_ui_with_prompt_overlay _ui_do_multiselect "$question" "$@")
    
    # Record in history (join multiple selections with comma for display)
    local display_result
    display_result=$(echo "$result" | tr '\n' ',' | sed 's/,$//')
    UI_HISTORY+=("select|$question|$display_result")
    echo "$result"
}

# Prompt for text input
# Usage: value=$(ui_prompt_input "Enter value" "default")
ui_prompt_input() {
    local question="$1"
    local default="${2:-}"

    if _ui_is_simple; then
        _ui_input_fallback "$question" "$default"
        return $?
    fi

    local result
    result=$(_ui_with_prompt_overlay _ui_do_input "$question" "$default")
    
    # Record in history and output
    UI_HISTORY+=("input|$question|$result")
    echo "$result"
}

# Cleanup and restore terminal
ui_cleanup() {
    (( UI_STATE[enabled] == 0 )) && return

    # Restore terminal
    if (( UI_STATE[is_tty] == 1 )); then
        printf '%s%s' "$ANSI_SHOW_CURSOR" "$ANSI_MAIN_SCREEN"
    fi

    # Clear traps
    trap - EXIT INT TERM WINCH

    # Show summary
    if (( ${#UI_HISTORY[@]} > 0 && UI_STATE[is_tty] == 1 )); then
        _ui_print_summary
    fi

    UI_STATE[enabled]=0
}

#──────────────────────────────────────────────────────────────────────────────
# Internal: Drawing
#──────────────────────────────────────────────────────────────────────────────

# Main draw function - renders entire screen
_ui_draw() {
    (( UI_STATE[is_tty] == 0 )) && return

    local lines=${UI_STATE[term_lines]}
    local cols=${UI_STATE[term_cols]}

    # Calculate layout
    local history_height=$(( lines * 20 / 100 ))
    (( history_height < 3 )) && history_height=3

    local status_height=3
    local output_height=$(( lines - history_height - status_height - 2 ))  # -2 for separators
    (( output_height < 3 )) && output_height=3

    # Build frame
    local frame=""

    # Move to top-left
    frame+="${ANSI_HOME}"

    # History section
    frame+="$(_ui_render_history "$history_height" "$cols")"

    # Separator
    frame+="$(_ui_render_separator "$cols")"

    # Output section
    frame+="$(_ui_render_output "$output_height" "$cols")"

    # Status bar (positioned at bottom)
    frame+="$(_ui_render_status "$cols" "$lines")"

    # Atomic write to terminal
    printf '%s' "$frame"
}

# Render history section
_ui_render_history() {
    local max_lines=$1
    local cols=$2
    local out=""

    # Reserve a line for current command if one is running
    local history_max=$max_lines
    if [[ -n "${UI_STATE[current_cmd]}" ]]; then
        (( history_max-- ))
    fi

    local count=${#UI_HISTORY[@]}
    local start=0
    (( count > history_max )) && start=$(( count - history_max ))

    # Render completed commands and prompts
    local lines_used=0
    for (( i = start; i < count && lines_used < history_max; i++ )); do
        local entry="${UI_HISTORY[$i]}"
        local type="${entry%%|*}"
        local rest="${entry#*|}"
        local desc="${rest%%|*}"
        local extra="${rest#*|}"

        local icon color line
        case "$type" in
            ok)
                icon="✓"; color="$UI_C_OK"
                line="$icon $desc ($extra)"
                ;;
            err)
                icon="✗"; color="$UI_C_ERR"
                line="$icon $desc ($extra)"
                ;;
            confirm|select|input)
                icon="›"; color="$UI_C_INFO"
                line="$icon $desc: $extra"
                ;;
            *)
                icon="·"; color="$UI_C_RST"
                line="$icon $desc"
                ;;
        esac

        (( ${#line} > cols )) && line="${line:0:cols-3}..."

        out+="${color}${line}${UI_C_RST}"
        out+="${ESC}[K"  # Clear to end of line
        out+=$'\n'
        (( lines_used++ ))
    done

    # Render current command if running
    if [[ -n "${UI_STATE[current_cmd]}" ]]; then
        local elapsed=$(( $(_ui_time_ms) - UI_STATE[current_start] ))
        local elapsed_str=$(_ui_format_duration "$elapsed")
        local line="⊙ ${UI_STATE[current_cmd]} ($elapsed_str)"
        (( ${#line} > cols )) && line="${line:0:cols-3}..."

        out+="${UI_C_WARN}${line}${UI_C_RST}"
        out+="${ESC}[K"
        out+=$'\n'
        (( lines_used++ ))
    fi

    # Fill remaining lines
    while (( lines_used < max_lines )); do
        out+="${ESC}[K"$'\n'
        (( lines_used++ ))
    done

    printf '%s' "$out"
}

# Render separator line
_ui_render_separator() {
    local cols=$1
    local line=""
    for (( i = 0; i < cols; i++ )); do
        line+="─"
    done
    printf '%s%s%s%s\n' "$UI_C_DIM" "$line" "$UI_C_RST" "${ESC}[K"
}

# Render output section
_ui_render_output() {
    local max_lines=$1
    local cols=$2
    local out=""

    # Read last N lines from log
    local -a log_lines=()
    if [[ -f "$UI_LOG_FILE" ]]; then
        mapfile -t log_lines < <(tail -n "$max_lines" "$UI_LOG_FILE" 2>/dev/null || true)
    fi

    local lines_used=0
    for line in "${log_lines[@]}"; do
        # Truncate long lines
        (( ${#line} > cols - 2 )) && line="${line:0:cols-5}..."
        out+="${UI_C_DIM}  ${line}${UI_C_RST}${ESC}[K"$'\n'
        (( lines_used++ ))
    done

    # Fill remaining lines
    while (( lines_used < max_lines )); do
        out+="${ESC}[K"$'\n'
        (( lines_used++ ))
    done

    printf '%s' "$out"
}

# Render status bar at bottom
_ui_render_status() {
    local cols=$1
    local lines=$2
    local out=""

    # Position cursor for status area (3 lines from bottom)
    out+="${ESC}[$((lines - 2));1H"

    # Bottom separator
    local sep=""
    for (( i = 0; i < cols; i++ )); do
        sep+="─"
    done
    out+="${UI_C_DIM}${sep}${UI_C_RST}${ESC}[K"$'\n'

    # Progress bar
    local step=${UI_STATE[current_step]}
    local total=${UI_STATE[total_steps]}
    local percent=0
    (( total > 0 )) && percent=$(( step * 100 / total ))

    local bar_width=$(( cols - 20 ))
    (( bar_width < 10 )) && bar_width=10

    local filled=$(( bar_width * percent / 100 ))
    local empty=$(( bar_width - filled ))

    out+="$UI_C_INFO"
    for (( i = 0; i < filled; i++ )); do out+="━"; done
    for (( i = 0; i < empty; i++ )); do out+="─"; done
    out+="$(printf ' %3d%% (%d/%d)' "$percent" "$step" "$total")"
    out+="$UI_C_RST${ESC}[K"$'\n'

    # Keybindings hint
    out+="${ANSI_DIM}^C Cancel${UI_C_RST}${ESC}[K"

    printf '%s' "$out"
}

#──────────────────────────────────────────────────────────────────────────────
# Internal: Command Execution
#──────────────────────────────────────────────────────────────────────────────

# Run command with periodic output refresh
_ui_run_with_output() {
    # Start command in background, redirect output to log
    "$@" >> "$UI_LOG_FILE" 2>&1 &
    local cmd_pid=$!

    # Poll for completion while refreshing display
    while kill -0 "$cmd_pid" 2>/dev/null; do
        _ui_draw
        sleep "$UI_REFRESH_INTERVAL"
    done

    # Get exit code
    wait "$cmd_pid"
    return $?
}

#──────────────────────────────────────────────────────────────────────────────
# Internal: Prompts
#──────────────────────────────────────────────────────────────────────────────

# Execute a prompt function with a centered overlay (stays in alt buffer)
# All drawing goes to /dev/tty, only the prompt result goes to stdout
_ui_with_prompt_overlay() {
    local func="$1"
    shift

    UI_STATE[in_prompt]=1

    # Clear screen and position cursor at center for gum
    # This gives gum a clean slate to render from
    local lines=${UI_STATE[term_lines]}
    local cols=${UI_STATE[term_cols]}
    local center_row=$(( lines / 3 ))  # Upper third looks better for prompts
    
    {
        # Clear screen
        printf '%s%s' "$ANSI_HOME" "$ANSI_CLEAR"
        # Position cursor
        printf "${ESC}[%d;1H" "$center_row"
        # Show cursor
        printf '%s' "$ANSI_SHOW_CURSOR"
    } >/dev/tty

    # Temporarily disable our signal handlers for clean Ctrl+C in prompts
    trap - INT TERM

    # Run the prompt function - stdout captured by caller
    local result=0
    "$func" "$@" || result=$?

    # Restore signal handlers
    trap '_ui_cleanup_handler; exit 130' INT
    trap '_ui_cleanup_handler; exit 143' TERM

    # Hide cursor and redraw the full UI
    {
        printf '%s' "$ANSI_HIDE_CURSOR"
    } >/dev/tty
    _ui_draw >/dev/tty

    UI_STATE[in_prompt]=0

    return $result
}

# Prompt after command failure
# Shows error info and asks user what to do
_ui_prompt_failure() {
    local exit_code=$1
    local lines=${UI_STATE[term_lines]}
    
    # Clear screen and show failure info
    {
        printf '%s%s' "$ANSI_HOME" "$ANSI_CLEAR"
        printf "${ESC}[3;1H"  # Start at row 3
        printf '%s' "$ANSI_SHOW_CURSOR"
        
        printf "${UI_C_ERR}Command failed with exit code %d${UI_C_RST}\n\n" "$exit_code"
        printf "${UI_C_DIM}Last output:${UI_C_RST}\n"
    } >/dev/tty
    
    # Show last few lines of output
    tail -n 8 "$UI_LOG_FILE" 2>/dev/null | while IFS= read -r line; do
        printf "  ${UI_C_DIM}%s${UI_C_RST}\n" "$line"
    done >/dev/tty
    
    printf "\n" >/dev/tty

    local choice
    if command -v gum &>/dev/null; then
        choice=$(gum choose "Retry" "Continue anyway" "Abort" --header "What would you like to do?" --height=4)
    else
        {
            printf "1) Retry  2) Continue  3) Abort\n"
        } >/dev/tty
        read -rp "Choice (1-3): " num </dev/tty
        case "$num" in
            1) choice="Retry" ;;
            2) choice="Continue anyway" ;;
            *) choice="Abort" ;;
        esac
    fi

    case "$choice" in
        "Retry") echo "retry" ;;
        "Continue anyway") echo "continue" ;;
        *) echo "abort" ;;
    esac
}

# Confirm prompt implementation
# Outputs "yes" or "no" to stdout based on user choice
_ui_do_confirm() {
    local question="$1"
    if command -v gum &>/dev/null; then
        # gum confirm uses exit code: 0=yes, 1=no
        # gum handles tty internally for rendering
        if gum confirm "$question" --timeout=0; then
            echo "yes"
        else
            echo "no"
        fi
    else
        # Fallback: read from tty directly
        read -rp "$question (y/N) " -n 1 reply </dev/tty
        echo >/dev/tty  # newline
        if [[ "$reply" =~ ^[Yy]$ ]]; then
            echo "yes"
        else
            echo "no"
        fi
    fi
}

# Select prompt implementation
_ui_do_select() {
    local question="$1"
    shift
    if command -v gum &>/dev/null; then
        gum choose "$@" --header "$question" --height=8
    else
        _ui_select_fallback "$question" "$@"
    fi
}

# Multiselect prompt implementation
_ui_do_multiselect() {
    local question="$1"
    shift
    if command -v gum &>/dev/null; then
        gum choose --no-limit "$@" --header "$question" --height=8
    else
        _ui_multiselect_fallback "$question" "$@"
    fi
}

# Input prompt implementation
_ui_do_input() {
    local question="$1"
    local default="$2"
    if command -v gum &>/dev/null; then
        if [[ -n "$default" ]]; then
            gum input --placeholder "$default" --header "$question" --value "$default" --width=50
        else
            gum input --header "$question" --width=50
        fi
    else
        _ui_input_fallback "$question" "$default"
    fi
}

# Fallback implementations (no gum)
_ui_select_fallback() {
    local question="$1"
    shift
    local options=("$@")
    echo "$question"
    select opt in "${options[@]}"; do
        if [[ -n "$opt" ]]; then
            echo "$opt"
            return 0
        fi
    done
    return 1
}

_ui_multiselect_fallback() {
    local question="$1"
    shift
    local options=("$@")
    echo "$question (enter numbers separated by spaces)"
    local i=1
    for opt in "${options[@]}"; do
        echo "$i) $opt"
        (( i++ ))
    done
    read -ra selections
    for sel in "${selections[@]}"; do
        if (( sel >= 1 && sel <= ${#options[@]} )); then
            echo "${options[$((sel - 1))]}"
        fi
    done
}

_ui_input_fallback() {
    local question="$1"
    local default="$2"
    local value
    if [[ -n "$default" ]]; then
        read -rp "$question [$default]: " value
        echo "${value:-$default}"
    else
        read -rp "$question: " value
        echo "$value"
    fi
}

#──────────────────────────────────────────────────────────────────────────────
# Internal: Utilities
#──────────────────────────────────────────────────────────────────────────────

# Check if in simple mode
_ui_is_simple() {
    (( UI_STATE[is_tty] == 0 || UI_STATE[enabled] == 0 ))
}

# Get time in milliseconds
_ui_time_ms() {
    echo $(( $(date +%s%N) / 1000000 ))
}

# Format duration
_ui_format_duration() {
    local ms=$1
    if (( ms < 1000 )); then
        echo "${ms}ms"
    elif (( ms < 60000 )); then
        printf "%.1fs" "$(echo "scale=1; $ms / 1000" | bc)"
    else
        local secs=$(( ms / 1000 ))
        local mins=$(( secs / 60 ))
        secs=$(( secs % 60 ))
        echo "${mins}m ${secs}s"
    fi
}

# Update terminal dimensions
_ui_update_dimensions() {
    UI_STATE[term_lines]=$(tput lines 2>/dev/null || echo 24)
    UI_STATE[term_cols]=$(tput cols 2>/dev/null || echo 80)
}

# Initialize colors
_ui_init_colors() {
    local scheme=${1:-basic}
    # Basic ANSI colors work everywhere
    UI_C_OK=$'\033[32m'    # Green
    UI_C_ERR=$'\033[31m'   # Red
    UI_C_WARN=$'\033[33m'  # Yellow
    UI_C_INFO=$'\033[36m'  # Cyan
    UI_C_DIM=$'\033[90m'   # Gray
    UI_C_RST=$'\033[0m'    # Reset
}

# Handle terminal resize
_ui_handle_resize() {
    _ui_update_dimensions

    if (( UI_STATE[term_lines] < UI_MIN_LINES || UI_STATE[term_cols] < UI_MIN_COLS )); then
        if (( UI_STATE[is_tty] == 1 )); then
            UI_STATE[is_tty]=0
            printf '%s%s' "$ANSI_SHOW_CURSOR" "$ANSI_MAIN_SCREEN"
            echo "Terminal too small, switching to simple mode" >&2
        fi
    else
        _ui_draw
    fi
}

# Cleanup handler for traps
_ui_cleanup_handler() {
    ui_cleanup
}

# Print summary after completion
_ui_print_summary() {
    echo ""
    echo "──────────────────────────────────────"
    echo "Summary:"
    echo "──────────────────────────────────────"

    for entry in "${UI_HISTORY[@]}"; do
        local type="${entry%%|*}"
        local rest="${entry#*|}"
        local desc="${rest%%|*}"
        local extra="${rest#*|}"

        local icon color
        case "$type" in
            ok)      icon="✓"; color="$UI_C_OK" ;;
            err)     icon="✗"; color="$UI_C_ERR" ;;
            confirm) icon="?"; color="$UI_C_INFO" ;;
            select)  icon="›"; color="$UI_C_INFO" ;;
            input)   icon="›"; color="$UI_C_INFO" ;;
            *)       icon="·"; color="$UI_C_RST" ;;
        esac

        case "$type" in
            ok|err)
                printf '%s%s %s (%s)%s\n' "$color" "$icon" "$desc" "$extra" "$UI_C_RST"
                ;;
            confirm|select|input)
                printf '%s%s %s: %s%s\n' "$color" "$icon" "$desc" "$extra" "$UI_C_RST"
                ;;
        esac
    done

    echo "──────────────────────────────────────"
}

#──────────────────────────────────────────────────────────────────────────────
# Export functions when sourced
#──────────────────────────────────────────────────────────────────────────────

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f ui_init ui_run ui_run_or_abort ui_run_continue ui_run_or_prompt
    export -f ui_prompt_confirm ui_prompt_select ui_prompt_multiselect ui_prompt_input
    export -f ui_cleanup
fi
