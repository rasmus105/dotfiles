#!/usr/bin/env bash
#
# Launch a full Arch Linux VM for manual Hyprland testing
# Requires: qemu, wget

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_DIR="$SCRIPT_DIR/.vm"
DISK_SIZE="20G"
RAM="4G"
CPUS="4"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${YELLOW}→${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Create VM directory
mkdir -p "$VM_DIR"

# Check for required tools
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo -e "${YELLOW}QEMU not found. Install with:${NC}"
    echo "  Arch Linux: sudo pacman -S qemu-full"
    echo "  Ubuntu/Debian: sudo apt install qemu-system-x86 qemu-utils"
    echo "  macOS: brew install qemu"
    exit 1
fi

# Download Arch ISO if not present
ARCH_ISO="$VM_DIR/archlinux.iso"
if [ ! -f "$ARCH_ISO" ]; then
    print_info "Downloading Arch Linux ISO..."
    wget -O "$ARCH_ISO" "https://mirror.rackspace.com/archlinux/iso/latest/archlinux-x86_64.iso"
    print_success "ISO downloaded"
fi

# Create disk image if not present
DISK_IMG="$VM_DIR/arch-test.qcow2"
if [ ! -f "$DISK_IMG" ]; then
    print_info "Creating virtual disk ($DISK_SIZE)..."
    qemu-img create -f qcow2 "$DISK_IMG" "$DISK_SIZE"
    print_success "Disk created"
fi

# Create shared folder for dotfiles
SHARED_DIR="$VM_DIR/shared"
mkdir -p "$SHARED_DIR"

# Copy dotfiles to shared directory
print_info "Copying dotfiles to shared directory..."
rsync -av --exclude='.git' --exclude='.vm' --exclude='*.qcow2' \
    "$SCRIPT_DIR/" "$SHARED_DIR/dotfiles/"

print_success "VM setup complete!"
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  Starting Arch Linux VM for Hyprland Testing         ${BLUE}║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  RAM: $RAM                                            ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}  CPUs: $CPUS                                          ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}  Dotfiles available in: /mnt/shared/dotfiles/        ${BLUE}║${NC}"
echo -e "${BLUE}╠════════════════════════════════════════════════════════╣${NC}"
echo -e "${BLUE}║${NC}  Quick Start:                                         ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   1. Install Arch Linux (archinstall or manual)      ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   2. After install, mount shared folder:             ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}      sudo mount -t 9p -o trans=virtio shared /mnt    ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   3. Copy dotfiles: cp -r /mnt/dotfiles ~            ${BLUE}║${NC}"
echo -e "${BLUE}║${NC}   4. Run your setup script                           ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
read -p "Press Enter to launch VM (or Ctrl+C to cancel)..."

# Launch QEMU with graphics
qemu-system-x86_64 \
    -enable-kvm \
    -m "$RAM" \
    -smp "$CPUS" \
    -cpu host \
    -drive file="$DISK_IMG",if=virtio \
    -cdrom "$ARCH_ISO" \
    -boot order=d \
    -virtfs local,path="$SHARED_DIR",mount_tag=shared,security_model=passthrough,id=shared0 \
    -vga virtio \
    -display gtk,gl=on \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -name "Arch Linux - Hyprland Test"

# Alternative without KVM (slower but works everywhere):
# Remove -enable-kvm and -cpu host if not on Linux
