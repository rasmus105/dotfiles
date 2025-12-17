#!/usr/bin/env bash
#
# VM Test Environment Orchestrator
#
# Interactive TUI for managing the QEMU-based VM test environment.
# Wraps vm.sh with a user-friendly gum-based interface.
#
# Usage:
#   ./run_vm.sh              Start interactive menu
#   ./run_vm.sh --help       Show this help message
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Core module
VM_SCRIPT="$SCRIPT_DIR/vm.sh"

# Image/ISO paths (must match vm.sh)
VM_IMAGE_PATH="$SCRIPT_DIR/images/arch-dotfiles.qcow2"
VM_ISO_PATH="$SCRIPT_DIR/images/archlinux-x86_64.iso"

#──────────────────────────────────────────────────────────────────────────────
# Gum UI Helpers (future: move to local/lib/shell/gum.sh)
#──────────────────────────────────────────────────────────────────────────────

# Color constants (matching gum's style)
readonly UI_PINK="212"
readonly UI_GREEN="2"
readonly UI_RED="1"
readonly UI_GRAY="245"
readonly UI_CYAN="6"

# Clear screen properly
ui_clear() {
    printf '\033[2J\033[H'
}

# Styled header with border
ui_header() {
    gum style --border rounded --border-foreground "$UI_PINK" --padding "0 1" --bold "$1"
}

# Muted info text
ui_muted() {
    gum style --foreground "$UI_GRAY" "$1"
}

# Success text
ui_success() {
    gum style --foreground "$UI_GREEN" "✓ $1"
}

# Error text
ui_error() {
    gum style --foreground "$UI_RED" "✗ $1"
}

# Info text
ui_info() {
    gum style --foreground "$UI_CYAN" "$1"
}

# Menu selection with consistent styling
ui_choose() {
    local header="$1"
    shift
    gum choose --cursor.foreground "$UI_PINK" --header "$header" --header.foreground "$UI_GRAY" "$@"
}

# Confirmation dialog
ui_confirm() {
    gum confirm --prompt.foreground "$UI_PINK" "$1"
}

# Text input
ui_input() {
    local header="$1"
    local default="${2:-}"
    if [[ -n "$default" ]]; then
        gum input --header "$header" --header.foreground "$UI_GRAY" --cursor.foreground "$UI_PINK" --value "$default"
    else
        gum input --header "$header" --header.foreground "$UI_GRAY" --cursor.foreground "$UI_PINK"
    fi
}

# Spinner for long operations
ui_spin() {
    local title="$1"
    shift
    gum spin --spinner dot --spinner.foreground "$UI_PINK" --title "$title" -- "$@"
}

# Pause and wait for user
ui_pause() {
    local message="${1:-Press Enter to continue...}"
    gum input --placeholder "$message" --width 40 >/dev/null 2>&1 || true
}

# Display a status table for check results
# Usage: ui_check_table "check1:status1" "check2:status2" ...
# Returns 0 if all checks pass, 1 otherwise
ui_check_table() {
    local -a rows=("$@")
    local all_ok=true
    local max_label_len=0

    # Human-readable names for checks
    declare -A check_names=(
        [cpu_virt]="CPU Virtualization"
        [qemu]="QEMU Installed"
        [kvm_module]="KVM Module"
        [kvm_access]="KVM Access"
        [iso]="Arch ISO"
    )

    # Find max label length for alignment
    for row in "${rows[@]}"; do
        local key="${row%%:*}"
        local name="${check_names[$key]:-$key}"
        ((${#name} > max_label_len)) && max_label_len=${#name}
    done

    # Build table content
    local table=""
    for row in "${rows[@]}"; do
        local key="${row%%:*}"
        local status="${row#*:}"
        local name="${check_names[$key]:-$key}"
        local icon color

        if [[ "$status" == "ok" ]]; then
            icon="✓"
            color="$UI_GREEN"
        else
            icon="✗"
            color="$UI_RED"
            all_ok=false
        fi

        local colored_icon
        colored_icon=$(gum style --foreground "$color" "$icon")
        table+="$(printf "  %-${max_label_len}s  %s\n" "$name" "$colored_icon")"
    done

    # Determine border color based on overall status
    local border_color
    if [[ "$all_ok" == true ]]; then
        border_color="$UI_GREEN"
    else
        border_color="$UI_RED"
    fi

    # Display with border
    echo "$table" | gum style --border rounded --border-foreground "$border_color" --padding "0 1"

    [[ "$all_ok" == true ]]
}

#──────────────────────────────────────────────────────────────────────────────
# Helper Functions
#──────────────────────────────────────────────────────────────────────────────

# Check if gum is available, install if not
ensure_gum() {
    if command -v gum &>/dev/null; then
        return 0
    fi

    echo "gum is required for the interactive menu."
    echo "Installing gum..."

    if command -v paru &>/dev/null; then
        paru -S --noconfirm gum
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm gum
    else
        echo "Error: Cannot install gum. Please install it manually."
        return 1
    fi
}

# Get list of snapshot names (just the names, one per line)
get_snapshots() {
    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        return 0
    fi

    # Parse qemu-img snapshot -l output
    # Format: ID TAG VM_SIZE DATE VM_CLOCK
    # Skip header lines (first 2 lines)
    "$VM_SCRIPT" snapshot list 2>/dev/null | tail -n +3 | awk '{print $2}' | grep -v '^$' || true
}

# Check if disk image exists
image_exists() {
    [[ -f "$VM_IMAGE_PATH" ]]
}

# Run a command with spinner and error handling
# On failure, shows output and prompts user for retry/continue/abort
# Usage: run_with_retry "Description" command args...
run_with_retry() {
    local desc="$1"
    shift

    local output
    local exit_code=0

    # Run with spinner, capture output
    output=$(ui_spin "$desc" "$@" 2>&1) || exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        ui_success "$desc"
        return 0
    fi

    # Command failed - show output and prompt
    ui_error "$desc failed"
    echo ""
    if [[ -n "$output" ]]; then
        ui_muted "Output:"
        echo "$output" | tail -n 15
    fi
    echo ""

    local choice
    choice=$(ui_choose "What would you like to do?" \
        "🔄 Retry" \
        "⏭ Continue anyway" \
        "⛔ Abort")

    case "$choice" in
        "🔄 Retry")
            run_with_retry "$desc" "$@"
            return $?
            ;;
        "⏭ Continue anyway")
            return 0
            ;;
        "⛔ Abort")
            return 1
            ;;
    esac
}

#──────────────────────────────────────────────────────────────────────────────
# Pre-check: Ensure host is ready
#──────────────────────────────────────────────────────────────────────────────

run_precheck() {
    ui_clear
    ui_header "Host Setup Check"
    echo ""

    # Run check with parseable output
    local check_output
    local exit_code=0
    check_output=$("$VM_SCRIPT" check --parseable 2>&1) || exit_code=$?

    # Parse into array
    local -a checks=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && checks+=("$line")
    done <<< "$check_output"

    # Only show table if there are issues
    if [[ $exit_code -ne 0 ]]; then
        ui_muted "Some checks failed:"
        echo ""
        ui_check_table "${checks[@]}" || true
        echo ""

        if ui_confirm "Attempt to fix issues automatically?"; then
            echo ""
            # Extract failed checks
            local -a failed=()
            for check in "${checks[@]}"; do
                local key="${check%%:*}"
                local status="${check#*:}"
                [[ "$status" != "ok" ]] && failed+=("$key")
            done

            # Run fixes with spinners
            local fix_failed=false
            for issue in "${failed[@]}"; do
                local issue_name
                case "$issue" in
                    cpu_virt)   issue_name="CPU virtualization" ;;
                    qemu)       issue_name="QEMU" ;;
                    kvm_module) issue_name="KVM module" ;;
                    kvm_access) issue_name="KVM access" ;;
                    iso)        issue_name="Arch ISO" ;;
                    *)          issue_name="$issue" ;;
                esac

                if ! ui_spin "Fixing $issue_name..." "$VM_SCRIPT" fix "$issue"; then
                    ui_error "Failed to fix $issue_name"
                    fix_failed=true
                else
                    ui_success "Fixed $issue_name"
                fi
            done

            if [[ "$fix_failed" == true ]]; then
                echo ""
                ui_muted "Some issues could not be fixed automatically."
                if ! ui_confirm "Continue anyway?"; then
                    return 1
                fi
            else
                echo ""
                ui_success "All issues fixed!"
                sleep 1
            fi
        else
            if ! ui_confirm "Continue without fixing?"; then
                return 1
            fi
        fi
    else
        ui_success "All checks passed"
        sleep 0.5
    fi

    return 0
}

#──────────────────────────────────────────────────────────────────────────────
# Submenus
#──────────────────────────────────────────────────────────────────────────────

menu_start_vm() {
    ui_clear
    ui_header "Start VM"
    echo ""

    local options=()

    if image_exists; then
        options+=("💿 Boot from disk (BIOS)")
        options+=("💿 Boot from disk (UEFI)")
    else
        options+=("💿 Boot from disk (will create image)")
    fi

    options+=("📀 Fresh install from ISO (BIOS)")
    options+=("📀 Fresh install from ISO (UEFI)")
    options+=("← Back")

    local choice
    choice=$(ui_choose "Select boot option:" "${options[@]}")

    case "$choice" in
        "💿 Boot from disk"*) 
            if ! image_exists; then
                echo ""
                if ui_confirm "No disk image exists. Create one now?"; then
                    if ! run_with_retry "Creating disk image" "$VM_SCRIPT" image create; then
                        ui_pause
                        return 0
                    fi
                else
                    return 0
                fi
            fi
            echo ""
            local run_args=()
            [[ "$choice" == *"UEFI"* ]] && run_args+=(--uefi)
            ui_info "Starting VM..."
            "$VM_SCRIPT" run "${run_args[@]}" || true
            ;;
        "📀 Fresh install from ISO"*)
            if ! image_exists; then
                echo ""
                if ui_confirm "No disk image exists. Create one now?"; then
                    if ! run_with_retry "Creating disk image" "$VM_SCRIPT" image create; then
                        ui_pause
                        return 0
                    fi
                else
                    return 0
                fi
            fi
            echo ""
            local run_args=(--iso)
            [[ "$choice" == *"UEFI"* ]] && run_args+=(--uefi)
            ui_info "Starting VM (booting from ISO)..."
            "$VM_SCRIPT" run "${run_args[@]}" || true
            ;;
        "← Back")
            return 0
            ;;
    esac
}

menu_snapshots() {
    while true; do
        ui_clear
        ui_header "Snapshots"
        echo ""

        local -a snapshots
        mapfile -t snapshots < <(get_snapshots)
        local snap_count=${#snapshots[@]}

        # Show status
        if [[ $snap_count -gt 0 ]]; then
            ui_muted "$snap_count snapshot(s) available"
        else
            ui_muted "No snapshots"
        fi
        echo ""

        local options=()

        # Load options (if snapshots exist)
        if [[ $snap_count -gt 0 ]]; then
            for snap in "${snapshots[@]}"; do
                [[ -n "$snap" ]] && options+=("📂 Load: $snap")
            done
        fi

        # Action options
        options+=("➕ Create snapshot")
        [[ $snap_count -gt 0 ]] && options+=("🗑 Delete snapshot")
        options+=("📋 List details")
        options+=("← Back")

        local choice
        choice=$(ui_choose "Select action:" "${options[@]}")

        case "$choice" in
            "📂 Load: "*)
                local snap_name="${choice#📂 Load: }"
                echo ""
                if ui_confirm "Load snapshot '$snap_name'? This will revert the VM state."; then
                    if run_with_retry "Loading snapshot '$snap_name'" "$VM_SCRIPT" snapshot load "$snap_name"; then
                        ui_pause
                    fi
                fi
                ;;
            "➕ Create snapshot")
                if ! image_exists; then
                    echo ""
                    ui_error "No disk image exists. Create an image first."
                    ui_pause
                    continue
                fi
                echo ""
                local prefix
                prefix=$(ui_input "Snapshot name prefix (optional, timestamp added)")
                if run_with_retry "Creating snapshot" "$VM_SCRIPT" snapshot create "$prefix"; then
                    ui_pause
                fi
                ;;
            "🗑 Delete snapshot")
                if [[ $snap_count -eq 0 ]]; then
                    echo ""
                    ui_error "No snapshots to delete."
                    ui_pause
                    continue
                fi

                local del_options=()
                for snap in "${snapshots[@]}"; do
                    [[ -n "$snap" ]] && del_options+=("$snap")
                done
                del_options+=("← Cancel")

                local to_delete
                to_delete=$(ui_choose "Select snapshot to delete:" "${del_options[@]}")

                if [[ "$to_delete" != "← Cancel" ]]; then
                    echo ""
                    if ui_confirm "Delete snapshot '$to_delete'? This cannot be undone."; then
                        if run_with_retry "Deleting snapshot '$to_delete'" "$VM_SCRIPT" snapshot delete "$to_delete"; then
                            ui_pause
                        fi
                    fi
                fi
                ;;
            "📋 List details")
                ui_clear
                ui_header "Snapshot Details"
                echo ""
                "$VM_SCRIPT" snapshot list || ui_muted "No snapshots or no image."
                echo ""
                ui_pause
                ;;
            "← Back")
                return 0
                ;;
        esac
    done
}

menu_disk_image() {
    while true; do
        ui_clear
        ui_header "Disk Image"
        echo ""

        # Show status
        if image_exists; then
            ui_success "Image exists"
            ui_muted "$VM_IMAGE_PATH"
        else
            ui_muted "No image created"
        fi
        echo ""

        local options=()

        if image_exists; then
            options+=("ℹ️ Show image info")
            options+=("🗑 Delete image")
            options+=("🔄 Recreate image")
        else
            options+=("➕ Create image")
        fi

        options+=("← Back")

        local choice
        choice=$(ui_choose "Select action:" "${options[@]}")

        case "$choice" in
            "ℹ️ Show image info")
                ui_clear
                ui_header "Image Info"
                echo ""
                "$VM_SCRIPT" image info || ui_error "Failed to get image info."
                echo ""
                ui_pause
                ;;
            "➕ Create image")
                echo ""
                if run_with_retry "Creating disk image" "$VM_SCRIPT" image create; then
                    ui_pause
                fi
                ;;
            "🗑 Delete image")
                echo ""
                if ui_confirm "Delete disk image? All data and snapshots will be lost!"; then
                    if run_with_retry "Deleting disk image" "$VM_SCRIPT" image delete; then
                        ui_pause
                    fi
                fi
                ;;
            "🔄 Recreate image")
                echo ""
                if ui_confirm "Delete and recreate disk image? All data and snapshots will be lost!"; then
                    if run_with_retry "Recreating disk image" "$VM_SCRIPT" image create --force; then
                        ui_pause
                    fi
                fi
                ;;
            "← Back")
                return 0
                ;;
        esac
    done
}

#──────────────────────────────────────────────────────────────────────────────
# Main Menu
#──────────────────────────────────────────────────────────────────────────────

main_menu() {
    while true; do
        ui_clear

        # Styled header
        ui_header "VM Test Environment"
        echo ""

        # Status info
        if image_exists; then
            local snap_count
            snap_count=$(get_snapshots | wc -l)
            ui_muted "Image: ✓ exists  •  Snapshots: $snap_count"
        else
            ui_muted "Image: not created"
        fi
        echo ""

        local choice
        choice=$(ui_choose "Select an option:" \
            "▶ Start VM" \
            "📸 Snapshots" \
            "💾 Disk Image" \
            "🔍 Check Host" \
            "⏻ Exit")

        case "$choice" in
            "▶ Start VM")
                menu_start_vm
                ;;
            "📸 Snapshots")
                menu_snapshots
                ;;
            "💾 Disk Image")
                menu_disk_image
                ;;
            "🔍 Check Host")
                ui_clear
                ui_header "Host Readiness Check"
                echo ""

                local check_output
                local exit_code=0
                check_output=$("$VM_SCRIPT" check --parseable 2>&1) || exit_code=$?

                local -a checks=()
                while IFS= read -r line; do
                    [[ -n "$line" ]] && checks+=("$line")
                done <<< "$check_output"

                ui_check_table "${checks[@]}" || true
                echo ""

                if [[ $exit_code -eq 0 ]]; then
                    ui_success "All checks passed!"
                else
                    ui_error "Some checks failed"
                    echo ""
                    if ui_confirm "Attempt to fix issues?"; then
                        run_precheck
                    fi
                fi
                ui_pause
                ;;
            "⏻ Exit")
                ui_clear
                ui_muted "Goodbye!"
                exit 0
                ;;
        esac
    done
}

#──────────────────────────────────────────────────────────────────────────────
# Help
#──────────────────────────────────────────────────────────────────────────────

print_help() {
    cat <<'EOF'
VM Test Environment Orchestrator

Interactive TUI for managing the QEMU-based VM test environment.

Usage:
  ./run_vm.sh              Start interactive menu
  ./run_vm.sh --help       Show this help message

The menu provides access to:
  • Start VM (boot from disk or fresh install from ISO)
  • Snapshot management (create, load, delete)
  • Disk image management (create, delete, info)
  • Host readiness checks

On startup, the script checks if the host is ready for VM testing
and offers to fix any issues automatically.

Requirements:
  • gum (will be installed automatically if missing)
  • QEMU with KVM support
  • CPU virtualization enabled in BIOS

EOF
}

#──────────────────────────────────────────────────────────────────────────────
# Entry Point
#──────────────────────────────────────────────────────────────────────────────

main() {
    # Handle --help
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        print_help
        exit 0
    fi

    # Bootstrap gum
    if ! ensure_gum; then
        exit 1
    fi

    # Run pre-checks
    if ! run_precheck; then
        echo "Cannot continue without a ready host environment."
        exit 1
    fi

    # Show main menu
    main_menu
}

main "$@"
