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

# Show log in fullscreen pager
# Uses alternate screen buffer to preserve terminal history
_log_show_pager() {
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

    echo "🔄 $title"
    echo "   (Press 'l' to view logs)"
    
    # Setup terminal for key detection
    _log_setup_terminal
    
    # Disable job control messages
    set +m
    
    # Run the command in background and capture output to log
    eval "$cmd" >>"$LOG_FILE" 2>&1 &
    local cmd_pid=$!
    
    # Disown the job to prevent shell messages
    disown "$cmd_pid" 2>/dev/null || true
    
    # Monitor for both command completion and keypresses
    while kill -0 "$cmd_pid" 2>/dev/null; do
        # Check for keypress
        local key=$(_log_check_keypress)
        
        if [[ "$key" == "l" ]]; then
            # Show log in pager
            _log_show_pager
            # No need to redraw - alternate screen buffer preserves everything
        fi
        
        sleep 0.1
    done
    
    # Get command exit code
    wait "$cmd_pid" 2>/dev/null
    local exit_code=$?
    
    # Re-enable job control
    set -m
    
    # Restore terminal
    _log_restore_terminal
    
    # Show result
    if [[ $exit_code -eq 0 ]]; then
        echo "✓ $title"
        {
            echo ">>> Success"
            echo ""
        } >>"$LOG_FILE"
        return 0
    else
        echo "✗ $title (failed)"
        {
            echo ">>> Exit code: $exit_code"
            echo ">>> FAILED"
            echo ""
        } >>"$LOG_FILE"
        return $exit_code
    fi
}
