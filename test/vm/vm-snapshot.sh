#!/usr/bin/env bash
#
# VM snapshot management for quick testing iterations

set -e

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname $(dirname "$SCRIPT_DIR"))

# Source helpers and initialize gum / PATH
source "$DOTFILES_DIR/common.sh"
ensure_gum
add_dotfiles_bin_to_path

VM_DIR="$SCRIPT_DIR/.vm"
DISK_IMG="$VM_DIR/arch-test.qcow2"

ACTION="${1:-list}"
SNAPSHOT_NAME="${2:-clean-install}"

if [ ! -f "$DISK_IMG" ]; then
    gum_error "VM disk image not found at $DISK_IMG"
    gum_info "Create a VM first with: ./vm.sh"
    exit 1
fi

case "$ACTION" in
    create|snapshot)
        gum_info "Creating snapshot: $SNAPSHOT_NAME"
        qemu-img snapshot -c "$SNAPSHOT_NAME" "$DISK_IMG"
        gum_success "Snapshot '$SNAPSHOT_NAME' created!"
        ;;

    restore|apply)
        gum_info "Restoring snapshot: $SNAPSHOT_NAME"
        qemu-img snapshot -a "$SNAPSHOT_NAME" "$DISK_IMG"
        gum_success "Snapshot '$SNAPSHOT_NAME' restored!"
        gum_muted "You can now run: ./vm.sh"
        ;;

    list|ls)
        gum_section "Available snapshots for VM:"
        qemu-img snapshot -l "$DISK_IMG"
        ;;

    delete|rm)
        gum_info "Deleting snapshot: $SNAPSHOT_NAME"
        qemu-img snapshot -d "$SNAPSHOT_NAME" "$DISK_IMG"
        gum_success "Snapshot '$SNAPSHOT_NAME' deleted!"
        ;;

    help|--help|-h)
        gum_bold "Usage: $0 <action> [snapshot-name]"
        echo ""
        gum_section "Actions:"
        gum_muted "  create [name]   - Create a new snapshot (default: clean-install)"
        gum_muted "  restore [name]  - Restore to a snapshot"
        gum_muted "  list            - List all snapshots"
        gum_muted "  delete [name]   - Delete a snapshot"
        gum_muted "  help            - Show this help"
        echo ""
        gum_section "Examples:"
        gum_muted "  $0 create fresh-arch        # Create snapshot named 'fresh-arch'"
        gum_muted "  $0 restore fresh-arch       # Restore to 'fresh-arch'"
        gum_muted "  $0 list                     # Show all snapshots"
        ;;

    *)
        gum_error "Unknown action: $ACTION"
        gum_info "Use '$0 help' for usage information"
        exit 1
        ;;
esac
