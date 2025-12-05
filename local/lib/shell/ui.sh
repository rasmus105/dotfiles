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
declare -g UI_FIFO=""        # Named pipe for IPC with monitor process

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

    # Create FIFO for IPC
    UI_FIFO="/tmp/dotfiles-ui-$$.fifo"
    mkfifo "$UI_FIFO" 2>/dev/null || {
        echo "Failed to create FIFO, disabling fancy UI" >&2
        UI_IS_TTY=0
        return
    }

    # Setup terminal
    # Switch to alternate screen buffer to preserve shell history
    tput smcup 2>/dev/null || printf "\033[?1049h"
    
    # Hide cursor
    printf "%s" "$ANSI_HIDE_CURSOR"

    # Set up traps for cleanup
    trap ui_cleanup EXIT INT TERM
    trap '_ui_handle_resize' WINCH

    # Start background monitor
    _ui_start_monitor

    # Send initial state to monitor
    _ui_send_update "INIT|$UI_CURRENT_STEP|$UI_TOTAL_STEPS|$UI_TERM_LINES|$UI_TERM_COLS"
}

# Run a command with UI integration
# Usage: ui_run "Description" command args...
# Returns: Command exit code
ui_run() {
    local desc="$1"
    shift

    # Simple mode: just run it
    if _ui_is_simple_mode; then
        echo "→ $desc"
        "$@"
        return $?
    fi

    # Record start
    UI_CURRENT_CMD="$desc"
    UI_CURRENT_START=$(_get_time)

    # Notify monitor of new command
    _ui_send_update "CMD|$UI_CURRENT_CMD|$UI_CURRENT_START"

    # Clear log for this command
    : >"$UI_LOG_FILE"

    # Run command, stream to log
    "$@" >>"$UI_LOG_FILE" 2>&1
    local exit_code=$?

    # Calculate duration
    local end_time=$(_get_time)
    local duration=$((end_time - UI_CURRENT_START))
    local duration_str=$(_format_duration $duration)

    # Update history based on exit code
    if [ $exit_code -eq 0 ]; then
        UI_HISTORY+=("✓|$desc|$duration_str|success")
        _ui_send_update "HISTORY|✓|$desc|$duration_str|success"
    else
        UI_HISTORY+=("✗|$desc|$duration_str|failed")
        _ui_send_update "HISTORY|✗|$desc|$duration_str|failed"
    fi

    UI_CURRENT_STEP=$((UI_CURRENT_STEP + 1))
    UI_CURRENT_CMD=""

    # Clear current command and update step
    _ui_send_update "CMD||0"
    _ui_send_update "STEP|$UI_CURRENT_STEP|$UI_TOTAL_STEPS"

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

        if _ui_is_simple_mode; then
            echo "Command failed with exit code $exit_code"
            echo "Continue anyway? (y/N)"
            read -r response
            if [[ ! "$response" =~ ^[Yy] ]]; then
                return 1
            fi
            return 0
        fi

        # Handler function for prompt logic
        _ui_prompt_failure_handler() {
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
            echo "$choice"
        }

        local choice
        choice=$(_ui_with_monitor_stopped _ui_prompt_failure_handler)

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

    if _ui_is_simple_mode; then
        read -p "$question (y/N) " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
        return $?
    fi

    # Handler function
    _ui_confirm_handler() {
        if command -v gum &>/dev/null; then
            gum confirm "$question"
        else
            read -p "$question (y/N) " -n 1 -r
            echo
            [[ $REPLY =~ ^[Yy]$ ]]
        fi
    }

    _ui_with_monitor_stopped _ui_confirm_handler
    return $?
}

# Prompt for selection from a list
# Usage: choice=$(ui_prompt_select "Choose option" opt1 opt2 opt3)
ui_prompt_select() {
    local question="$1"
    shift
    local options=("$@")

    # Simple mode fallback
    _ui_select_fallback() {
        echo "$question"
        select opt in "${options[@]}"; do
            if [ -n "$opt" ]; then
                echo "$opt"
                return 0
            fi
        done
        return 1
    }

    if _ui_is_simple_mode; then
        _ui_select_fallback
        return $?
    fi

    # Handler function
    _ui_select_handler() {
        if command -v gum &>/dev/null; then
            gum choose "${options[@]}" --header "$question"
        else
            _ui_select_fallback
        fi
    }

    _ui_with_monitor_stopped _ui_select_handler
}

# Prompt for multiple selections
# Usage: choices=$(ui_prompt_multiselect "Choose options" opt1 opt2 opt3)
#        Returns selections separated by newlines
ui_prompt_multiselect() {
    local question="$1"
    shift
    local options=("$@")

    # Fallback for multiselect (number-based selection)
    _ui_multiselect_fallback() {
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
    }

    if _ui_is_simple_mode; then
        _ui_multiselect_fallback
        return 0
    fi

    # Handler function
    _ui_multiselect_handler() {
        if command -v gum &>/dev/null; then
            gum choose --no-limit "${options[@]}" --header "$question"
        else
            _ui_multiselect_fallback
        fi
    }

    _ui_with_monitor_stopped _ui_multiselect_handler
}

# Prompt for text input
# Usage: value=$(ui_prompt_input "Enter value" "default")
ui_prompt_input() {
    local question="$1"
    local default="${2:-}"

    # Fallback for input
    _ui_input_fallback() {
        if [ -n "$default" ]; then
            read -p "$question [$default]: " -r value
            echo "${value:-$default}"
        else
            read -p "$question: " -r value
            echo "$value"
        fi
    }

    if _ui_is_simple_mode; then
        _ui_input_fallback
        return 0
    fi

    # Handler function
    _ui_input_handler() {
        if command -v gum &>/dev/null; then
            if [ -n "$default" ]; then
                gum input --placeholder "$default" --prompt "$question: " --value "$default"
            else
                gum input --prompt "$question: "
            fi
        else
            _ui_input_fallback
        fi
    }

    _ui_with_monitor_stopped _ui_input_handler
}

# Check if we're in simple mode (no fancy UI)
_ui_is_simple_mode() {
    [ $UI_IS_TTY -eq 0 ] || [ $UI_ENABLED -eq 0 ]
}

# Wrapper to execute a function with monitor temporarily stopped
# Usage: _ui_with_monitor_stopped function_name [args...]
_ui_with_monitor_stopped() {
    local func=$1
    shift
    
    _ui_stop_monitor
    local result
    "$func" "$@"
    result=$?
    _ui_start_monitor
    
    return $result
}

# Cleanup and restore terminal
ui_cleanup() {
    if [ $UI_ENABLED -eq 0 ]; then
        return
    fi

    _ui_stop_monitor
    
    # Show cursor
    printf "%s" "$ANSI_SHOW_CURSOR"
    
    # Restore original screen buffer (only if fancy UI was enabled)
    if [ $UI_IS_TTY -eq 1 ]; then
        tput rmcup 2>/dev/null || printf "\033[?1049l"
    fi

    # Remove FIFO
    if [ -n "$UI_FIFO" ] && [ -p "$UI_FIFO" ]; then
        rm -f "$UI_FIFO"
    fi

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

# Send update message to monitor via FIFO
# Usage: _ui_send_update "MESSAGE_TYPE|data|more_data"
_ui_send_update() {
    if [ -z "$UI_FIFO" ] || [ ! -p "$UI_FIFO" ]; then
        return
    fi

    # Send message, ignore errors if monitor is not reading
    echo "$1" >"$UI_FIFO" 2>/dev/null || true
}

# Start background monitor process
_ui_start_monitor() {
    if [ $UI_IS_TTY -eq 0 ] || [ -n "$UI_MONITOR_PID" ]; then
        return
    fi

    (
        # Open FIFO for reading (non-blocking)
        exec 3<"$UI_FIFO"

        # Local state (isolated from parent process)
        local -a local_history=()
        local local_current_cmd=""
        local local_current_start=0
        local local_current_step=0
        local local_total_steps=$UI_TOTAL_STEPS
        local local_term_lines=$UI_TERM_LINES
        local local_term_cols=$UI_TERM_COLS

        while true; do
            # Read all pending updates from FIFO (non-blocking)
            while true; do
                if IFS='|' read -r -t 0.01 -u 3 msg_type rest; then
                    # Successfully read a message
                    case "$msg_type" in
                    INIT)
                        # Full state initialization
                        IFS='|' read -r local_current_step local_total_steps local_term_lines local_term_cols <<<"$rest"
                        ;;
                    CMD)
                        # Current command update
                        IFS='|' read -r local_current_cmd local_current_start <<<"$rest"
                        ;;
                    HISTORY)
                        # Add history entry
                        local_history+=("$rest")
                        ;;
                    STEP)
                        # Update step counter
                        IFS='|' read -r local_current_step local_total_steps <<<"$rest"
                        ;;
                    RESIZE)
                        # Terminal resize
                        IFS='|' read -r local_term_lines local_term_cols <<<"$rest"
                        ;;
                    STOP)
                        # Exit signal
                        exec 3<&- # Close FIFO
                        exit 0
                        ;;
                    esac
                else
                    # Timeout - no more data available
                    break
                fi
            done

            # Draw screen with local state
            _ui_draw_screen_local \
                "$local_current_cmd" \
                "$local_current_start" \
                "$local_current_step" \
                "$local_total_steps" \
                "$local_term_lines" \
                "$local_term_cols" \
                "${local_history[@]}"

            sleep 0.1
        done
    ) &
    UI_MONITOR_PID=$!

    # Give monitor time to open FIFO for reading
    sleep 0.05
}

# Stop background monitor process
_ui_stop_monitor() {
    if [ -n "$UI_MONITOR_PID" ]; then
        # Send stop signal via FIFO
        _ui_send_update "STOP"

        # Wait for monitor to exit gracefully
        sleep 0.1
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
    else
        # Send resize notification to monitor
        _ui_send_update "RESIZE|$UI_TERM_LINES|$UI_TERM_COLS"
    fi
}

# Draw the entire screen (called by background monitor with local state)
_ui_draw_screen_local() {
    local current_cmd=$1
    local current_start=$2
    local current_step=$3
    local total_steps=$4
    local term_lines=$5
    local term_cols=$6
    shift 6
    local -a history=("$@")

    # Calculate region heights (as percentage of terminal)
    local history_lines=$((term_lines * 20 / 100))
    local status_lines=3
    local output_lines=$((term_lines - history_lines - status_lines - 2)) # -2 for separators

    # Ensure minimum sizes
    [ $history_lines -lt 3 ] && history_lines=3
    [ $output_lines -lt 5 ] && output_lines=5

    # Build complete frame using array-based assembly
    local sections=(
        "$(_ui_draw_history_local "$history_lines" "$current_cmd" "$current_start" "$term_cols" "${history[@]}")"
        "$(_ui_draw_separator_local "$term_cols")"
        "$(_ui_draw_output_local "$output_lines" "$term_cols")"
        "$(_ui_draw_status_local "$current_step" "$total_steps" "$term_cols" "$term_lines")"
    )
    
    # Atomic display: move to top, clear screen, print entire frame
    tput cup 0 0 2>/dev/null || printf "\033[H"
    tput ed 2>/dev/null || printf "\033[J"
    printf '%s\n' "${sections[@]}"
}

# Draw command history region (with local state)
_ui_draw_history_local() {
    local max_lines=$1
    local current_cmd=$2
    local current_start=$3
    local term_cols=$4
    shift 4
    local -a history=("$@")

    local output=""
    
    # Calculate how many history entries to show
    local history_count=${#history[@]}
    local start=0

    if [ $history_count -gt $max_lines ]; then
        start=$((history_count - max_lines))
    fi

    # Show history entries
    for ((i = start; i < history_count; i++)); do
        local entry="${history[$i]}"
        IFS='|' read -r icon desc time status <<<"$entry"

        # Set color based on icon
        local color=""
        case $icon in
        ✓) color="$UI_COLOR_SUCCESS" ;;
        ✗) color="$UI_COLOR_ERROR" ;;
        ⊙) color="$UI_COLOR_PENDING" ;;
        esac

        # Format and truncate if needed
        local line="$icon $desc ${time:+($time)}"
        if [ ${#line} -gt $term_cols ]; then
            line="${line:0:$((term_cols - 3))}..."
        fi

        output+="${color}${line}${UI_COLOR_RESET}"$'\n'
    done

    # Show current command if running
    if [ -n "$current_cmd" ]; then
        local elapsed=$(($(_get_time) - current_start))
        local elapsed_str=$(_format_duration $elapsed)

        local line="⊙ $current_cmd ($elapsed_str)"
        if [ ${#line} -gt $term_cols ]; then
            line="${line:0:$((term_cols - 3))}..."
        fi
        output+="${UI_COLOR_PENDING}${line}${UI_COLOR_RESET}"$'\n'
    fi
    
    printf "%s" "$output"
}

# Draw separator line (with local state)
_ui_draw_separator_local() {
    local term_cols=$1

    printf "%s%s%s" "${UI_COLOR_MUTED}" "$(printf "─%.0s" $(seq 1 $term_cols))" "${UI_COLOR_RESET}"
}

# Draw command output region (with local state)
_ui_draw_output_local() {
    local max_lines=$1
    local term_cols=$2

    local output=""
    
    # Read last N lines from log file
    if [ -f "$UI_LOG_FILE" ]; then
        mapfile -t lines < <(tail -n "$max_lines" "$UI_LOG_FILE" 2>/dev/null || true)

        for line in "${lines[@]}"; do
            # Truncate if too long
            if [ ${#line} -gt $((term_cols - 2)) ]; then
                line="${line:0:$((term_cols - 5))}..."
            fi

            # Append to output string instead of printing
            output+="${UI_COLOR_MUTED}  ${line}${UI_COLOR_RESET}"$'\n'
        done
    fi
    
    printf "%s" "$output"
}

# Draw status bar (progress and keybindings) (with local state)
_ui_draw_status_local() {
    local current_step=$1
    local total_steps=$2
    local term_cols=$3
    local term_lines=$4

    local output=""
    
    # Position cursor at bottom of terminal (3 lines from bottom for separator + 2 status lines)
    # Status occupies last 2 lines: progress bar + keybindings
    # Line before that is the separator

    # Move cursor to position for bottom separator (3rd line from bottom)
    output+="$(tput cup $((term_lines - 3)) 0 2>/dev/null || printf "\033[%d;0H" $((term_lines - 2)))"

    # Draw bottom separator
    output+="${UI_COLOR_MUTED}"
    output+="$(printf "─%.0s" $(seq 1 $term_cols))"
    output+="${UI_COLOR_RESET}"$'\n'

    # Progress bar (2nd line from bottom)
    output+="$(tput cup $((term_lines - 2)) 0 2>/dev/null || printf "\033[%d;0H" $((term_lines - 1)))"

    local percent=0
    if [ $total_steps -gt 0 ]; then
        percent=$((current_step * 100 / total_steps))
    fi

    local bar_width=$((term_cols - 20))
    [ $bar_width -lt 10 ] && bar_width=10

    local filled=$((bar_width * percent / 100))
    local empty=$((bar_width - filled))

    output+="${UI_COLOR_INFO}"
    output+="$(printf "━%.0s" $(seq 1 $filled))"
    output+="$(printf "─%.0s" $(seq 1 $empty))"
    output+=" $(printf "%3d" $percent)% (${current_step}/${total_steps})${UI_COLOR_RESET}"$'\n'

    # Keybindings (last line - bottom of terminal)
    output+="$(tput cup $((term_lines - 1)) 0 2>/dev/null || printf "\033[%d;0H" $term_lines)"
    output+="${ANSI_DIM}^C Cancel  ^Z Background${UI_COLOR_RESET}"
    
    printf "%s" "$output"
}

#──────────────────────────────────────────────────────────────────────────────
# Internal Helper Functions
#──────────────────────────────────────────────────────────────────────────────

# Get unix time in milliseconds
_get_time() {
    echo $(($(date +%s%N) / 1000000))
}

# Format duration in human-readable format
_format_duration() {
    local milliseconds=$1

    if [ "$milliseconds" -lt 1000 ]; then
        # Less than 1 second: show milliseconds
        echo "${milliseconds} ms"
    elif [ "$milliseconds" -lt 60000 ]; then
        # Less than 60 seconds: show seconds with 3 decimal places (millisecond precision)
        local secs
        secs=$(awk "BEGIN {printf \"%.3f\", ${milliseconds}/1000}")
        echo "${secs} s"
    else
        # 60 seconds or more: show minutes and seconds without millisecond precision
        local total_secs=$((milliseconds / 1000))
        local mins=$((total_secs / 60))
        local secs=$((total_secs % 60))
        echo "${mins} min ${secs} s"
    fi
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
