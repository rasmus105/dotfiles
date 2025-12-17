#!/usr/bin/env bash
#
# VM Test Environment for Dotfiles
#
# A QEMU-based test environment for end-to-end dotfiles testing.
# Uses KVM acceleration for near-native performance.
#
# Usage:
#   ./vm.sh check                     Check if host is ready for VM testing
#   ./vm.sh fix [issues]              Auto-fix host setup issues
#   ./vm.sh image create [--force]    Create a fresh VM disk image
#   ./vm.sh image delete              Delete the VM disk image
#   ./vm.sh image info                Show image info and snapshots
#   ./vm.sh run [--iso] [--uefi] [--dry-run]  Start the VM
#   ./vm.sh snapshot list             List all snapshots
#   ./vm.sh snapshot create [name]    Create a snapshot
#   ./vm.sh snapshot load <name>      Revert to a snapshot
#   ./vm.sh snapshot delete <name>    Delete a snapshot
#   ./vm.sh help                      Show this help message
#
# Examples:
#   ./vm.sh check                     # Check host setup
#   ./vm.sh fix                       # Fix all detected issues
#   ./vm.sh image create              # Create fresh 30G disk image
#   ./vm.sh run --iso                 # Boot from ISO for fresh install
#   ./vm.sh run --uefi                # Boot with UEFI firmware
#   ./vm.sh run --dry-run             # Show QEMU command without running
#   ./vm.sh snapshot create base      # Create snapshot "base-2025-12-16T14-30-00"
#   ./vm.sh snapshot load base-2025-12-16T14-30-00
#
# Environment variables:
#   VM_ISO_PATH     Path to Arch ISO (default: test/images/archlinux-x86_64.iso)
#   VM_DISK_SIZE    Disk image size (default: 30G)
#   VM_RAM          RAM allocation (default: 4G)
#   VM_CPUS         CPU cores (default: 4)
#   VM_DISPLAY      Display backend: gtk, sdl, spice-app (default: gtk)
#
# Exit codes:
#   0 - Success
#   1 - Operation failed
#   2 - Invalid usage
#   3 - Image already exists (for 'image create' without --force)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# VM configuration (override via environment variables)
VM_IMAGE_DIR="$SCRIPT_DIR/images"
VM_IMAGE_PATH="$VM_IMAGE_DIR/arch-dotfiles.qcow2"
VM_ISO_PATH="${VM_ISO_PATH:-$VM_IMAGE_DIR/archlinux-x86_64.iso}"
VM_DISK_SIZE="${VM_DISK_SIZE:-30G}"
VM_RAM="${VM_RAM:-4G}"
VM_CPUS="${VM_CPUS:-4}"
VM_DISPLAY="${VM_DISPLAY:-gtk}"

# ------------------------------------------------------------------------------
# Check functions
# ------------------------------------------------------------------------------

# Check host setup for QEMU with KVM acceleration.
#
# Arguments:
#   --parseable  Output in key:status format (for scripting)
#
# Default output: Issue codes only (one per line) for failed checks
# Parseable output: All checks as "key:ok" or "key:missing"
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed
check_host_setup() {
    local parseable=0
    [[ "${1:-}" == "--parseable" ]] && parseable=1

    local -A results=(
        [cpu_virt]="ok"
        [qemu]="ok"
        [kvm_module]="ok"
        [kvm_access]="ok"
        [iso]="ok"
    )
    local has_issues=0

    # Check CPU virtualization support (Intel VMX or AMD SVM)
    if ! grep -qE 'vmx|svm' /proc/cpuinfo; then
        results[cpu_virt]="missing"
        has_issues=1
    fi

    # Check for qemu-system-x86_64 binary
    if ! command -v qemu-system-x86_64 &>/dev/null; then
        results[qemu]="missing"
        has_issues=1
    fi

    # Check KVM kernel module is loaded
    # Note: Use grep >/dev/null instead of grep -q to avoid SIGPIPE issues with pipefail
    if ! lsmod | grep '^kvm' >/dev/null; then
        results[kvm_module]="missing"
        has_issues=1
    fi

    # Check user has read/write access to /dev/kvm
    if [[ ! -e /dev/kvm ]] || [[ ! -r /dev/kvm ]] || [[ ! -w /dev/kvm ]]; then
        results[kvm_access]="missing"
        has_issues=1
    fi

    # Check that the Arch ISO exists
    if [[ ! -f "$VM_ISO_PATH" ]]; then
        results[iso]="missing"
        has_issues=1
    fi

    if [[ $parseable -eq 1 ]]; then
        # Output all checks in consistent order
        echo "cpu_virt:${results[cpu_virt]}"
        echo "qemu:${results[qemu]}"
        echo "kvm_module:${results[kvm_module]}"
        echo "kvm_access:${results[kvm_access]}"
        echo "iso:${results[iso]}"
    else
        # Legacy output: only issue codes for failed checks
        for key in cpu_virt qemu kvm_module kvm_access iso; do
            [[ "${results[$key]}" == "missing" ]] && echo "$key"
        done
    fi

    return $has_issues
}

# Print human-readable description of issue codes
describe_issue() {
    local issue="$1"
    case "$issue" in
    cpu_virt)
        echo "CPU virtualization not supported or not enabled in BIOS"
        echo "  Manual fix: Enable VT-x (Intel) or AMD-V (AMD) in BIOS settings"
        ;;
    qemu)
        echo "qemu-system-x86_64 not found"
        echo "  Manual fix: sudo pacman -S qemu-desktop"
        ;;
    kvm_module)
        echo "KVM kernel module not loaded"
        echo "  Manual fix: sudo modprobe kvm_intel  # or kvm_amd for AMD CPUs"
        ;;
    kvm_access)
        echo "No read/write access to /dev/kvm"
        echo "  Manual fix: sudo usermod -aG kvm $USER && newgrp kvm"
        ;;
    iso)
        echo "Arch Linux ISO not found at $VM_ISO_PATH"
        echo "  Manual fix: Download from https://archlinux.org/download/"
        ;;
    *)
        echo "Unknown issue: $issue"
        ;;
    esac
}

# Get human-readable name for issue codes (for table display)
get_issue_name() {
    local issue="$1"
    case "$issue" in
    cpu_virt) echo "CPU Virtualization" ;;
    qemu) echo "QEMU Installed" ;;
    kvm_module) echo "KVM Module" ;;
    kvm_access) echo "KVM Access" ;;
    iso) echo "Arch ISO" ;;
    *) echo "$issue" ;;
    esac
}

# ------------------------------------------------------------------------------
# Fix functions
# ------------------------------------------------------------------------------

fix_qemu() {
    echo "Installing qemu-desktop..."
    if sudo pacman -S --noconfirm qemu-desktop; then
        echo "qemu-desktop installed successfully."
        return 0
    else
        echo "Failed to install qemu-desktop."
        return 1
    fi
}

fix_kvm_module() {
    echo "Loading KVM kernel module..."

    # Detect CPU vendor and load appropriate module
    if grep -q 'vendor_id.*GenuineIntel' /proc/cpuinfo; then
        if sudo modprobe kvm_intel; then
            echo "kvm_intel module loaded successfully."
            return 0
        fi
    elif grep -q 'vendor_id.*AuthenticAMD' /proc/cpuinfo; then
        if sudo modprobe kvm_amd; then
            echo "kvm_amd module loaded successfully."
            return 0
        fi
    else
        echo "Unknown CPU vendor, trying generic kvm module..."
        if sudo modprobe kvm; then
            echo "kvm module loaded successfully."
            return 0
        fi
    fi

    echo "Failed to load KVM module."
    return 1
}

fix_kvm_access() {
    echo "Adding user to kvm group..."
    if sudo usermod -aG kvm "$USER"; then
        echo "User added to kvm group."
        echo "NOTE: You must log out and back in (or run 'newgrp kvm') for this to take effect."
        return 0
    else
        echo "Failed to add user to kvm group."
        return 1
    fi
}

fix_iso() {
    local iso_url="https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"

    echo "Downloading Arch Linux ISO..."
    echo "  URL: $iso_url"
    echo "  Destination: $VM_ISO_PATH"

    if command -v curl &>/dev/null; then
        if curl -fL --progress-bar -o "$VM_ISO_PATH" "$iso_url"; then
            echo "ISO downloaded successfully."
            return 0
        fi
    elif command -v wget &>/dev/null; then
        if wget --show-progress -O "$VM_ISO_PATH" "$iso_url"; then
            echo "ISO downloaded successfully."
            return 0
        fi
    else
        echo "Neither curl nor wget found. Cannot download ISO."
        return 1
    fi

    echo "Failed to download ISO."
    return 1
}

fix_cpu_virt() {
    # This cannot be auto-fixed - requires BIOS changes
    echo "CPU virtualization must be enabled in BIOS/UEFI settings."
    echo "  - Intel: Enable VT-x or Intel Virtualization Technology"
    echo "  - AMD: Enable AMD-V or SVM Mode"
    echo "This cannot be fixed automatically."
    return 1
}

# Fix a single issue by code
# Returns 0 on success, 1 on failure
fix_issue() {
    local issue="$1"
    case "$issue" in
    cpu_virt) fix_cpu_virt ;;
    qemu) fix_qemu ;;
    kvm_module) fix_kvm_module ;;
    kvm_access) fix_kvm_access ;;
    iso) fix_iso ;;
    *)
        echo "Unknown issue code: $issue"
        return 1
        ;;
    esac
}

# ------------------------------------------------------------------------------
# Image functions
# ------------------------------------------------------------------------------

# Create a new VM disk image
# Exit codes: 0=success, 1=failed, 3=already exists (without --force)
image_create() {
    local force=0
    if [[ "${1:-}" == "--force" ]]; then
        force=1
    fi

    # Check if image already exists
    if [[ -f "$VM_IMAGE_PATH" ]]; then
        if [[ $force -eq 0 ]]; then
            echo "Image already exists: $VM_IMAGE_PATH"
            echo "Use --force to overwrite."
            return 3
        fi
        echo "Removing existing image..."
        rm -f "$VM_IMAGE_PATH"
    fi

    # Ensure directory exists
    mkdir -p "$VM_IMAGE_DIR"

    echo "Creating VM disk image..."
    echo "  Path: $VM_IMAGE_PATH"
    echo "  Size: $VM_DISK_SIZE"

    if qemu-img create -f qcow2 "$VM_IMAGE_PATH" "$VM_DISK_SIZE"; then
        echo "Image created successfully."
        return 0
    else
        echo "Failed to create image."
        return 1
    fi
}

# Delete the VM disk image
image_delete() {
    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        echo "No image found at: $VM_IMAGE_PATH"
        return 1
    fi

    rm -f "$VM_IMAGE_PATH"
    echo "Image deleted: $VM_IMAGE_PATH"
    return 0
}

# Show image info including snapshots
image_info() {
    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        echo "No image found at: $VM_IMAGE_PATH"
        return 1
    fi

    echo "Image path: $VM_IMAGE_PATH"
    echo ""
    qemu-img info "$VM_IMAGE_PATH"
    return 0
}

# ------------------------------------------------------------------------------
# Snapshot functions
# ------------------------------------------------------------------------------

# Generate snapshot name with ISO 8601 timestamp
# Usage: generate_snapshot_name [prefix]
generate_snapshot_name() {
    local prefix="${1:-}"
    local timestamp
    timestamp="$(date +%Y-%m-%dT%H-%M-%S)"

    if [[ -n "$prefix" ]]; then
        echo "${prefix}-${timestamp}"
    else
        echo "$timestamp"
    fi
}

# List all snapshots
snapshot_list() {
    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        echo "No image found at: $VM_IMAGE_PATH"
        return 1
    fi

    qemu-img snapshot -l "$VM_IMAGE_PATH"
    return 0
}

# Create a new snapshot
# Usage: snapshot_create [name_prefix]
snapshot_create() {
    local name
    name="$(generate_snapshot_name "${1:-}")"

    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        echo "No image found at: $VM_IMAGE_PATH"
        return 1
    fi

    echo "Creating snapshot: $name"
    if qemu-img snapshot -c "$name" "$VM_IMAGE_PATH"; then
        echo "Snapshot created successfully."
        return 0
    else
        echo "Failed to create snapshot."
        return 1
    fi
}

# Load (revert to) a snapshot
# Usage: snapshot_load <name>
snapshot_load() {
    local name="${1:-}"

    if [[ -z "$name" ]]; then
        echo "Usage: ./vm.sh snapshot load <name>"
        return 2
    fi

    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        echo "No image found at: $VM_IMAGE_PATH"
        return 1
    fi

    echo "Reverting to snapshot: $name"
    if qemu-img snapshot -a "$name" "$VM_IMAGE_PATH"; then
        echo "Snapshot loaded successfully."
        return 0
    else
        echo "Failed to load snapshot. Does it exist?"
        echo "Run './vm.sh snapshot list' to see available snapshots."
        return 1
    fi
}

# Delete a snapshot
# Usage: snapshot_delete <name>
snapshot_delete() {
    local name="${1:-}"

    if [[ -z "$name" ]]; then
        echo "Usage: ./vm.sh snapshot delete <name>"
        return 2
    fi

    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        echo "No image found at: $VM_IMAGE_PATH"
        return 1
    fi

    echo "Deleting snapshot: $name"
    if qemu-img snapshot -d "$name" "$VM_IMAGE_PATH"; then
        echo "Snapshot deleted successfully."
        return 0
    else
        echo "Failed to delete snapshot. Does it exist?"
        echo "Run './vm.sh snapshot list' to see available snapshots."
        return 1
    fi
}

# ------------------------------------------------------------------------------
# Commands
# ------------------------------------------------------------------------------

cmd_check() {
    local parseable=0
    [[ "${1:-}" == "--parseable" ]] && parseable=1

    if [[ $parseable -eq 1 ]]; then
        # Parseable output for scripting
        check_host_setup --parseable
        return $?
    fi

    # Human-readable output
    echo "Checking host setup for VM testing..."
    echo ""

    local issues
    if issues=$(check_host_setup); then
        echo "All checks passed. Host is ready for VM testing."
        return 0
    fi

    echo "Found issues:"
    echo ""
    for issue in $issues; do
        echo "[$issue]"
        describe_issue "$issue"
        echo ""
    done

    echo "Run './vm.sh fix' to attempt automatic fixes."
    return 1
}

cmd_fix() {
    local issues_to_fix=("$@")

    # If no specific issues provided, detect all issues
    if [[ ${#issues_to_fix[@]} -eq 0 ]]; then
        echo "Detecting issues..."
        if issues=$(check_host_setup); then
            echo "No issues detected. Host is ready for VM testing."
            return 0
        fi
        read -ra issues_to_fix <<<"$(echo "$issues" | tr '\n' ' ')"
        echo "Found ${#issues_to_fix[@]} issue(s) to fix: ${issues_to_fix[*]}"
    fi

    local unfixable=()
    local fixed=()

    for issue in "${issues_to_fix[@]}"; do
        echo ""
        echo "=== Fixing: $issue ==="
        if fix_issue "$issue"; then
            fixed+=("$issue")
        else
            unfixable+=("$issue")
        fi
    done

    echo ""
    echo "----------------------------------------"

    if [[ ${#fixed[@]} -gt 0 ]]; then
        echo "Fixed: ${fixed[*]}"
    fi

    if [[ ${#unfixable[@]} -gt 0 ]]; then
        echo "Could not fix: ${unfixable[*]}"
        echo ""
        echo "Manual intervention required for the above issues."
        return 1
    fi

    echo ""
    echo "All issues fixed successfully."
    return 0
}

cmd_run() {
    local boot_iso=0
    local boot_uefi=0
    local dry_run=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --iso)
            boot_iso=1
            shift
            ;;
        --uefi)
            boot_uefi=1
            shift
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./vm.sh run [--iso] [--uefi] [--dry-run]"
            return 2
            ;;
        esac
    done

    # Ensure host is ready
    if ! check_host_setup >/dev/null; then
        echo "Host is not ready for VM testing. Run './vm.sh check' for details."
        return 1
    fi

    # Ensure image exists
    if [[ ! -f "$VM_IMAGE_PATH" ]]; then
        echo "No VM image found. Create one first with './vm.sh image create'"
        return 1
    fi

    # Build QEMU command
    local qemu_args=(
        -enable-kvm
        -cpu host
        -m "$VM_RAM"
        -smp "$VM_CPUS"
        -drive "file=$VM_IMAGE_PATH,format=qcow2,if=virtio"
        -vga virtio
        -display "$VM_DISPLAY"
        -nic user,model=virtio-net-pci
        -virtfs "local,path=$DOTFILES_DIR,mount_tag=dotfiles,security_model=mapped-xattr"
    )

    # UEFI support (requires OVMF)
    if [[ $boot_uefi -eq 1 ]]; then
        local ovmf_code="/usr/share/edk2/x64/OVMF_CODE.fd"
        local ovmf_vars="/usr/share/edk2/x64/OVMF_VARS.fd"
        local vm_vars="$VM_IMAGE_DIR/OVMF_VARS.fd"

        if [[ ! -f "$ovmf_code" ]]; then
            echo "OVMF not found. Install with: sudo pacman -S edk2-ovmf"
            return 1
        fi

        # Create a copy of OVMF_VARS for this VM if it doesn't exist
        if [[ ! -f "$vm_vars" ]]; then
            cp "$ovmf_vars" "$vm_vars"
        fi

        qemu_args+=(
            -drive "if=pflash,format=raw,readonly=on,file=$ovmf_code"
            -drive "if=pflash,format=raw,file=$vm_vars"
        )
    fi

    if [[ $boot_iso -eq 1 ]]; then
        if [[ ! -f "$VM_ISO_PATH" ]]; then
            echo "ISO not found at: $VM_ISO_PATH"
            echo "Run './vm.sh fix iso' to download it."
            return 1
        fi
        qemu_args+=(-cdrom "$VM_ISO_PATH" -boot d)
        echo "Starting VM (booting from ISO)..."
    else
        qemu_args+=(-boot c)
        echo "Starting VM (booting from disk)..."
    fi

    echo "  RAM: $VM_RAM"
    echo "  CPUs: $VM_CPUS"
    echo "  Display: $VM_DISPLAY"
    echo "  Image: $VM_IMAGE_PATH"
    [[ $boot_uefi -eq 1 ]] && echo "  UEFI: enabled"
    echo "  Shared: $DOTFILES_DIR -> mount_tag=dotfiles"
    echo ""

    if [[ $dry_run -eq 1 ]]; then
        echo "Command (dry-run):"
        echo "  qemu-system-x86_64 \\"
        for arg in "${qemu_args[@]}"; do
            echo "    $arg \\"
        done
        echo ""
        return 0
    fi

    qemu-system-x86_64 "${qemu_args[@]}"
}

cmd_image() {
    local subcmd="${1:-}"
    shift || true

    case "$subcmd" in
    create) image_create "$@" ;;
    delete) image_delete ;;
    info) image_info ;;
    *)
        echo "Usage: ./vm.sh image <create|delete|info>"
        echo ""
        echo "Subcommands:"
        echo "  create [--force]  Create a new disk image"
        echo "  delete            Delete the disk image"
        echo "  info              Show image info and snapshots"
        return 2
        ;;
    esac
}

cmd_snapshot() {
    local subcmd="${1:-}"
    shift || true

    case "$subcmd" in
    list) snapshot_list ;;
    create) snapshot_create "$@" ;;
    load) snapshot_load "$@" ;;
    delete) snapshot_delete "$@" ;;
    *)
        echo "Usage: ./vm.sh snapshot <list|create|load|delete>"
        echo ""
        echo "Subcommands:"
        echo "  list              List all snapshots"
        echo "  create [name]     Create a snapshot (name is optional prefix)"
        echo "  load <name>       Revert to a snapshot"
        echo "  delete <name>     Delete a snapshot"
        return 2
        ;;
    esac
}

cmd_help() {
    # Print the header comment from this script
    sed -n '2,/^$/p' "$0" | sed 's/^# \?//'
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

main() {
    local cmd="${1:-help}"
    shift || true

    case "$cmd" in
    check) cmd_check "$@" ;;
    fix) cmd_fix "$@" ;;
    image) cmd_image "$@" ;;
    run) cmd_run "$@" ;;
    snapshot) cmd_snapshot "$@" ;;
    help | --help | -h) cmd_help ;;
    *)
        echo "Unknown command: $cmd"
        echo "Run './vm.sh help' for usage."
        return 1
        ;;
    esac
}

main "$@"
