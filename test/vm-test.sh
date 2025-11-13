#!/usr/bin/env bash
#
# Launch a full Arch Linux VM for manual Hyprland testing
# Requires: qemu, wget

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR=$(dirname $SCRIPT_DIR)

# Source gum utilities
source "$SCRIPT_DIR/../common/gum_utils.sh"

VM_DIR="$SCRIPT_DIR/.vm"
DISK_SIZE="20G"
RAM="4G"
CPUS="4"

# Parse arguments
AUTO_INSTALL=false
FRESH_START=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-install)
            AUTO_INSTALL=true
            shift
            ;;
        --fresh)
            FRESH_START=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --auto-install    Run automated Arch installation"
            echo "  --fresh           Delete existing VM and start fresh"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Create VM directory
mkdir -p "$VM_DIR"

# Check for required tools
if ! command -v qemu-system-x86_64 &> /dev/null; then
    gum_error "QEMU not found. Install with:"
    gum_muted "  Arch Linux: sudo pacman -S qemu-full"
    gum_muted "  Ubuntu/Debian: sudo apt install qemu-system-x86 qemu-utils"
    gum_muted "  macOS: brew install qemu"
    exit 1
fi

# Download Arch ISO if not present
ARCH_ISO="$VM_DIR/archlinux.iso"
if [ ! -f "$ARCH_ISO" ]; then
    gum_info "Downloading Arch Linux ISO..."
    wget -O "$ARCH_ISO" "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
    gum_success "ISO downloaded"
fi

# Create disk image if not present or fresh start requested
DISK_IMG="$VM_DIR/arch-test.qcow2"
if [ "$FRESH_START" = true ] && [ -f "$DISK_IMG" ]; then
    gum_info "Removing existing disk image..."
    rm "$DISK_IMG"
fi

if [ ! -f "$DISK_IMG" ]; then
    gum_info "Creating virtual disk ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMG" "$DISK_SIZE"
    gum_success "Disk created"
fi

# Create shared folder for dotfiles
SHARED_DIR="$VM_DIR/shared"
mkdir -p "$SHARED_DIR"

# Copy dotfiles to shared directory
gum_info "Copying dotfiles to shared directory..."
rsync -av --exclude='.git' --exclude='.vm' --exclude='*.qcow2' --exclude='*.iso' \
    "$DOTFILES_DIR/" "$SHARED_DIR/dotfiles/" &> /dev/null

# Copy auto-install script to shared directory if auto-install is requested
if [ "$AUTO_INSTALL" = true ]; then
    if [ -f "$SCRIPT_DIR/vm-auto-install.sh" ]; then
        cp "$SCRIPT_DIR/vm-auto-install.sh" "$SHARED_DIR/"
        gum_success "Auto-install script copied to shared directory"
    else
        gum_error "vm-auto-install.sh not found!"
        exit 1
    fi
fi

gum_success "VM setup complete!"
echo ""
gum_section "VM Configuration:"
gum_muted "  RAM: $RAM"
gum_muted "  CPUs: $CPUS"
gum_muted "  Disk: $DISK_SIZE"
gum_muted "  SSH Port: 2222 (user: testuser, pass: test123)"
echo ""

if [ "$AUTO_INSTALL" = true ]; then
    gum_success "AUTO-INSTALL MODE ENABLED"
    echo ""
    gum_section "After boot, run these commands:"
    gum_muted "  1. Mount shared: mount -t 9p -o trans=virtio shared /mnt"
    gum_muted "  2. Run installer: bash /mnt/vm-auto-install.sh"
    gum_muted "  3. Reboot: reboot"
else
    gum_warning "MANUAL INSTALL MODE"
    echo ""
    gum_section "Quick Start (Manual):"
    gum_muted "  1. Install Arch: archinstall (or manual)"
    gum_muted "  2. After install, mount shared:"
    gum_muted "     sudo mount -t 9p -o trans=virtio shared /mnt"
    gum_muted "  3. Copy dotfiles: cp -r /mnt/dotfiles ~"
    gum_muted "  4. Run setup: cd ~/dotfiles && bash setup.sh"
fi

echo ""
gum_info "Dotfiles available at: /mnt/dotfiles/ (after mounting)"
gum_muted "Use --auto-install flag to enable automated installation"
echo ""

# Determine boot order
if [ -f "$VM_DIR/.installed" ]; then
    BOOT_ORDER="c"  # Boot from disk
    gum_info "Booting from installed system..."
else
    BOOT_ORDER="d"  # Boot from CD
    gum_info "Booting from Arch ISO..."
fi

read -p "Press Enter to launch VM (or Ctrl+C to cancel)..."

# Detect KVM support
KVM_OPTS=""
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    KVM_OPTS="-enable-kvm -cpu host"
    gum_success "KVM acceleration enabled"
else
    gum_info "KVM not available, using software emulation (slower)"
    KVM_OPTS="-cpu qemu64"
fi

# Check for OVMF (UEFI firmware)
OVMF_CODE="/usr/share/edk2/x64/OVMF_CODE.fd"
OVMF_VARS="$VM_DIR/OVMF_VARS.fd"

if [ ! -f "$OVMF_CODE" ]; then
    # Try alternative paths
    if [ -f "/usr/share/ovmf/x64/OVMF_CODE.4m.fd" ]; then
        OVMF_CODE="/usr/share/ovmf/x64/OVMF_CODE.4m.fd"
    elif [ -f "/usr/share/ovmf/x64/OVMF_CODE.fd" ]; then
        OVMF_CODE="/usr/share/ovmf/x64/OVMF_CODE.fd"
    elif [ -f "/usr/share/OVMF/OVMF_CODE.fd" ]; then
        OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
    elif [ -f "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd" ]; then
        OVMF_CODE="/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
    else
        gum_error "OVMF (UEFI firmware) not found!"
        gum_info "Install it with:"
        gum_muted "  Arch Linux: sudo pacman -S edk2-ovmf"
        gum_muted "  Ubuntu/Debian: sudo apt install ovmf"
        exit 1
    fi
fi

# Create OVMF_VARS if it doesn't exist
if [ ! -f "$OVMF_VARS" ]; then
    gum_info "Creating UEFI variables file..."
    # Determine the correct VARS template based on CODE file
    VARS_TEMPLATE="${OVMF_CODE/CODE/VARS}"
    if [ ! -f "$VARS_TEMPLATE" ]; then
        # Some systems have it in a different location
        VARS_TEMPLATE="$(dirname "$OVMF_CODE")/OVMF_VARS.4m.fd"
    fi
    cp "$VARS_TEMPLATE" "$OVMF_VARS"
fi

# Launch QEMU with graphics
qemu-system-x86_64 \
    $KVM_OPTS \
    -m "$RAM" \
    -smp "$CPUS" \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$OVMF_VARS" \
    -drive file="$DISK_IMG",if=virtio \
    -cdrom "$ARCH_ISO" \
    -boot order=$BOOT_ORDER \
    -virtfs local,path="$SHARED_DIR",mount_tag=shared,security_model=passthrough,id=shared0 \
    -vga virtio \
    -display gtk,gl=on \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -name "Arch Linux - Dotfiles Test" \
    # uncomment below for audio on VM (though may degrade audio on system)
    # -device intel-hda \
    # -device hda-duplex

# Note: If the above fails, try without KVM:
# Remove -enable-kvm and change -cpu host to -cpu qemu64
