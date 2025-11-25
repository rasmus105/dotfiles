#!/bin/bash
#
# Interactive Log Viewer Library
# Provides functions for running commands with interactive log viewing
#

# Check if gum is installed
if ! command -v gum &>/dev/null; then
    echo "Error: 'gum' is not installed."
    echo "Install it from: https://github.com/charmbracelet/gum"
    exit 1
fi

# ============================================================================
# Color Configuration
# ============================================================================
# ANSI 256-color codes (matching gum_utils.sh style)
LOG_COLOR_SPINNER=212       # Pink/magenta for spinner
LOG_COLOR_SUCCESS=2         # Green for success messages
LOG_COLOR_ERROR=196         # Red for error messages
LOG_COLOR_TEXT=15           # White for normal text
LOG_COLOR_MUTED=240         # Gray for separators and muted text

# Helper function to output colored text
_log_color() {
    local color="$1"
    local text="$2"
    printf "\033[38;5;%sm%s\033[0m" "$color" "$text"
}

# Setup logging directory
LOG_DIR="${LOG_DIR:-/tmp/gum-log}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/run-$(date +%Y%m%d_%H%M%S).log}"
SIGNAL_FILE="${SIGNAL_FILE:-$LOG_DIR/signal}"
CONTROL_FILE="${CONTROL_FILE:-$LOG_DIR/control}"

# Initialize logging
log_init() {
    mkdir -p "$LOG_DIR"
    echo "Process started at $(date)" >"$LOG_FILE"
    echo "======================================" >>"$LOG_FILE"
    echo "" >>"$LOG_FILE"
    
    # Clean up old signal files
    rm -f "$SIGNAL_FILE" "$CONTROL_FILE"
}

# Setup terminal for non-blocking key detection
_log_setup_terminal() {
    # Save current terminal settings
    SAVED_TTY_SETTINGS=$(stty -g)
    
    # Set terminal to raw mode (no echo, no line buffering)
    stty -echo -icanon min 0 time 0
}

# Restore terminal to normal mode
_log_restore_terminal() {
    # Restore original terminal settings
    if [[ -n "$SAVED_TTY_SETTINGS" ]]; then
        stty "$SAVED_TTY_SETTINGS"
    fi
}

# Check for keypress (non-blocking)
# Returns the key pressed or empty string
_log_check_keypress() {
    local key=""
    # Use dd to read from stdin non-blocking (thanks to stty min 0 time 0)
    key=$(dd bs=1 count=1 2>/dev/null || true)
    echo "$key"
}

# Combined spinner + inline log viewer
# Shows spinner at top with live logs below
_log_spinner_with_inline() {
    local title="$1"
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local delay=0.1
    local i=0
    
    # Switch to alternate screen buffer (preserves main screen)
    tput smcup 2>/dev/null || true
    
    # Get terminal dimensions
    local term_height=$(tput lines)
    local log_lines=$((term_height - 5))  # Reserve lines for spinner, separator, and margin
    
    if [[ $log_lines -lt 5 ]]; then
        log_lines=5
    fi
    
    # Hide cursor
    tput civis 2>/dev/null || true
    
    # Initial clear and draw header once
    clear
    
    # Show spinner at top with colored spinner and white text
    local char="${spinner_chars:0:1}"
    _log_color "$LOG_COLOR_SPINNER" "$char"
    printf " "
    _log_color "$LOG_COLOR_TEXT" "$title"
    printf " "
    _log_color "$LOG_COLOR_MUTED" "(Press 'l' for fullscreen, space to hide logs)"
    echo
    
    # Show gray separator
    _log_color "$LOG_COLOR_MUTED" "────────────────────────────────────────────────────────────────"
    echo
    
    # Save cursor position (start of log area)
    tput sc 2>/dev/null || true
    
    while true; do
        # Return to saved position (start of log area)
        tput rc 2>/dev/null || true
        
        # Clear from cursor to end of screen
        tput ed 2>/dev/null || true
        
        # Show last N lines of log
        tail -n "$log_lines" "$LOG_FILE" 2>/dev/null || true
        
        # Update spinner character on first line
        tput cup 0 0 2>/dev/null || true
        local char="${spinner_chars:$i:1}"
        _log_color "$LOG_COLOR_SPINNER" "$char"
        
        i=$(( (i + 1) % ${#spinner_chars} ))
        sleep "$delay"
    done
    
    # Show cursor and return to main screen buffer (cleanup)
    tput cnorm 2>/dev/null || true
    tput rmcup 2>/dev/null || true
}

# No longer needed - inline view is handled by combined spinner

# Show log in fullscreen pager
# Uses alternate screen buffer to preserve terminal history
_log_show_pager() {
    local spinner_pid="$1"
    
    # Kill the spinner if running
    if [[ -n "$spinner_pid" ]] && kill -0 "$spinner_pid" 2>/dev/null; then
        kill "$spinner_pid" 2>/dev/null || true
        wait "$spinner_pid" 2>/dev/null || true
    fi
    
    # Restore terminal to normal mode for pager
    _log_restore_terminal
    
    # Switch to alternate screen buffer (preserves main screen)
    tput smcup 2>/dev/null || true
    
    # Show log with gum pager
    gum pager < "$LOG_FILE"
    
    # Return to main screen buffer (restores everything as it was)
    tput rmcup 2>/dev/null || true
    
    # Re-setup terminal for key detection
    _log_setup_terminal
}

# Custom spinner implementation that allows keypress detection
# Runs in background and can be killed when needed
_log_spinner() {
    local title="$1"
    local show_inline_hint="${2:-false}"
    local fixed_position="${3:-false}"  # If true, spinner stays at top with logs below
    local spinner_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local delay=0.1
    local i=0
    
    # Hide cursor
    tput civis 2>/dev/null || true
    
    if [[ "$fixed_position" == "true" ]]; then
        # Fixed position mode: save position and always return to it
        # This is used when inline logs are visible
        tput sc 2>/dev/null || true
        while true; do
            local char="${spinner_chars:$i:1}"
            # Return to saved position and overwrite spinner line
            tput rc 2>/dev/null || true
            printf "\033[38;5;%sm%s\033[0m " "$LOG_COLOR_SPINNER" "$char"
            printf "\033[38;5;%sm%s\033[0m " "$LOG_COLOR_TEXT" "$title"
            printf "\033[38;5;%sm%s\033[0m     " "$LOG_COLOR_MUTED" "(Press 'l' for fullscreen, space to hide logs)"
            tput sc 2>/dev/null || true
            i=$(( (i + 1) % ${#spinner_chars} ))
            sleep "$delay"
        done
    else
        # Normal mode: simple carriage return
        while true; do
            local char="${spinner_chars:$i:1}"
            if [[ "$show_inline_hint" == "true" ]]; then
                printf "\r\033[38;5;%sm%s\033[0m " "$LOG_COLOR_SPINNER" "$char"
                printf "\033[38;5;%sm%s\033[0m " "$LOG_COLOR_TEXT" "$title"
                printf "\033[38;5;%sm%s\033[0m" "$LOG_COLOR_MUTED" "(Press 'l' for fullscreen, space to hide logs)"
            else
                printf "\r\033[38;5;%sm%s\033[0m " "$LOG_COLOR_SPINNER" "$char"
                printf "\033[38;5;%sm%s\033[0m " "$LOG_COLOR_TEXT" "$title"
                printf "\033[38;5;%sm%s\033[0m" "$LOG_COLOR_MUTED" "(Press 'l' for fullscreen, space for inline logs)"
            fi
            i=$(( (i + 1) % ${#spinner_chars} ))
            sleep "$delay"
        done
    fi
    
    # Show cursor (cleanup)
    tput cnorm 2>/dev/null || true
}

# Cleanup function to kill background processes
_log_cleanup() {
    local spinner_pid="$1"
    local cmd_pid="$2"
    
    # Kill spinner if it exists
    if [[ -n "$spinner_pid" ]] && kill -0 "$spinner_pid" 2>/dev/null; then
        kill -9 "$spinner_pid" 2>/dev/null || true
        wait "$spinner_pid" 2>/dev/null || true
    fi
    
    # Kill command if it exists
    if [[ -n "$cmd_pid" ]] && kill -0 "$cmd_pid" 2>/dev/null; then
        kill -9 "$cmd_pid" 2>/dev/null || true
        wait "$cmd_pid" 2>/dev/null || true
    fi
    
    # Restore terminal
    _log_restore_terminal
    tput cnorm 2>/dev/null || true
    
    # Clear the spinner line completely (use terminal width)
    printf "\r"
    tput el 2>/dev/null || printf "%*s" "$(tput cols 2>/dev/null || echo 120)" ""
    printf "\r"
    echo
    
    # Re-enable job control
    set -m 2>/dev/null || true
}

# Test function - runs a command with a dummy spinner
# Usage: log_run "Description" "command to run"
log_run() {
    local title="$1"
    local cmd="$2"

    # Ensure log file exists
    if [[ ! -f "$LOG_FILE" ]]; then
        log_init
    fi

    # Log the command being run
    {
        echo ""
        echo ">>> Running: $title"
        echo ">>> Command: $cmd"
        echo ">>> Time: $(date)"
        echo "---"
    } >>"$LOG_FILE"

    # Setup terminal for key detection
    _log_setup_terminal
    
    # Disable job control messages
    set +m
    
    # Start custom spinner in background
    _log_spinner "$title" &
    local spinner_pid=$!
    disown "$spinner_pid" 2>/dev/null || true
    
    # Run the command in background and capture output to log
    eval "$cmd" >>"$LOG_FILE" 2>&1 &
    local cmd_pid=$!
    
    # Disown the job to prevent shell messages
    disown "$cmd_pid" 2>/dev/null || true
    
    # Set up trap to cleanup on exit or interrupt (must be after PIDs are set)
    trap "_log_cleanup '$spinner_pid' '$cmd_pid'; trap - INT TERM; return 130" INT TERM
    
    # Track inline view state
    local inline_view_visible="false"
    
    # Monitor for both command completion and keypresses
    while kill -0 "$cmd_pid" 2>/dev/null; do
        # Check for keypress
        local key=$(_log_check_keypress)
        
        if [[ "$key" == "l" ]]; then
            # Show log in fullscreen pager (will kill spinner temporarily)
            
            # If inline view is visible, hide it first
            if [[ "$inline_view_visible" == "true" ]]; then
                kill "$spinner_pid" 2>/dev/null || true
                wait "$spinner_pid" 2>/dev/null || true
                _log_stop_inline_view "$tail_pid"
                inline_view_visible="false"
            fi
            
            _log_show_pager "$spinner_pid"
            
            # Restart spinner after pager closes
            _log_spinner "$title" &
            spinner_pid=$!
            disown "$spinner_pid" 2>/dev/null || true
            
            # Update trap with new spinner PID
            trap "_log_cleanup '$spinner_pid' '$cmd_pid'; trap - INT TERM; return 130" INT TERM
            
        elif [[ "$key" == " " ]]; then
            # Toggle inline live log view
            if [[ "$inline_view_visible" == "false" ]]; then
                # Show inline view
                kill "$spinner_pid" 2>/dev/null || true
                wait "$spinner_pid" 2>/dev/null || true
                
                # Temporarily restore terminal for clear/tput commands
                _log_restore_terminal
                
                # Start combined spinner with inline logs
                _log_spinner_with_inline "$title" &
                spinner_pid=$!
                disown "$spinner_pid" 2>/dev/null || true
                
                # Re-setup raw mode
                _log_setup_terminal
                
                # Update trap with new spinner PID
                trap "_log_cleanup '$spinner_pid' '$cmd_pid'; trap - INT TERM; return 130" INT TERM
                
                inline_view_visible="true"
            else
                # Hide inline view
                kill "$spinner_pid" 2>/dev/null || true
                wait "$spinner_pid" 2>/dev/null || true
                
                # Temporarily restore terminal
                _log_restore_terminal
                
                # Return to main screen buffer (restores everything as it was)
                tput rmcup 2>/dev/null || true
                
                # Re-setup raw mode
                _log_setup_terminal
                
                # Restart normal spinner
                _log_spinner "$title" &
                spinner_pid=$!
                disown "$spinner_pid" 2>/dev/null || true
                
                # Update trap with new spinner PID
                trap "_log_cleanup '$spinner_pid' '$cmd_pid'; trap - INT TERM; return 130" INT TERM
                
                inline_view_visible="false"
            fi
        fi
        
        sleep 0.1
    done
    
    # Remove traps before cleanup
    trap - INT TERM
    
    # Kill the spinner
    if kill -0 "$spinner_pid" 2>/dev/null; then
        kill "$spinner_pid" 2>/dev/null || true
        wait "$spinner_pid" 2>/dev/null || true
    fi
    
    # Clean up inline view if it's visible (return to main screen)
    if [[ "$inline_view_visible" == "true" ]]; then
        _log_restore_terminal
        tput rmcup 2>/dev/null || true
        _log_setup_terminal
    fi
    
    # Clear the spinner line completely (use terminal width)
    printf "\r"
    tput el 2>/dev/null || printf "%*s" "$(tput cols 2>/dev/null || echo 120)" ""
    printf "\r"
    
    # Get command exit code
    wait "$cmd_pid" 2>/dev/null
    local exit_code=$?
    
    # Re-enable job control
    set -m
    
    # Restore terminal and show cursor
    _log_restore_terminal
    tput cnorm 2>/dev/null || true
    
    # Show result with colors
    if [[ $exit_code -eq 0 ]]; then
        _log_color "$LOG_COLOR_SUCCESS" "✓ $title"
        echo
        {
            echo ">>> Success"
            echo ""
        } >>"$LOG_FILE"
        return 0
    else
        _log_color "$LOG_COLOR_ERROR" "✗ $title (failed)"
        echo
        {
            echo ">>> Exit code: $exit_code"
            echo ">>> FAILED"
            echo ""
        } >>"$LOG_FILE"
        return $exit_code
    fi
}
