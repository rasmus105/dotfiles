#!/usr/bin/bash
#
# Automated Arch Linux installation for VM testing
# Run this from the Arch ISO after mounting the shared folder
#
# Usage:
#   mount -t 9p -o trans=virtio shared /mnt
#   bash /mnt/vm-auto-install.sh

set -e

# If running from /mnt, copy to /tmp and re-exec from there
if [[ "$0" == /mnt/* ]]; then
    TEMP_SCRIPT="/tmp/vm-auto-install.sh"
    cp "$0" "$TEMP_SCRIPT"
    chmod +x "$TEMP_SCRIPT"
    exec "$TEMP_SCRIPT" "$@"
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_step() {
    echo ""
    echo -e "${BLUE}==>${NC} ${YELLOW}$1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Helper to pad a line to specific width for box alignment
# Usage: pad_line "content" width
pad_line() {
    local content="$1"
    local width="${2:-56}"  # Default width for the box content area
    
    # Strip ANSI color codes for length calculation
    local clean_content=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g')
    local content_len=${#clean_content}
    local padding=$((width - content_len - 2))
    
    # Print content with padding
    printf "%s%*s" "$content" "$padding" ""
}

# Configuration
DISK="/dev/vda"
HOSTNAME="archtest"
USERNAME="testuser"
PASSWORD="1234"
ROOT_PASSWORD="${PASSWORD}"
TIMEZONE="UTC"

# Check if running in Arch ISO
if ! grep -q "archiso" /etc/hostname 2>/dev/null; then
    print_error "This script must be run from the Arch Linux ISO!"
    exit 1
fi

# Confirmation
BOX_WIDTH=56
echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "Automated Arch Linux Installation" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}╠════════════════════════════════════════════════════════╣${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "This will install Arch Linux with:" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "  • Disk: $DISK" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "  • Hostname: $HOSTNAME" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "  • User: $USERNAME (password: $PASSWORD)" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "  • Timezone: $TIMEZONE" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}║${NC}  $(pad_line "${RED}WARNING: This will ERASE $DISK!${NC}" $BOX_WIDTH)${YELLOW}║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Installation cancelled."
    exit 0
fi

# Step 1: Partition disk
print_step "Step 1/10: Partitioning disk..."
parted "$DISK" --script mklabel gpt
parted "$DISK" --script mkpart primary fat32 1MiB 512MiB
parted "$DISK" --script set 1 esp on
parted "$DISK" --script mkpart primary ext4 512MiB 100%
print_success "Disk partitioned"

# Step 2: Format partitions
print_step "Step 2/10: Formatting partitions..."
mkfs.fat -F32 "${DISK}1"
mkfs.ext4 -F "${DISK}2"
print_success "Partitions formatted"

# Step 3: Mount filesystems
print_step "Step 3/10: Mounting filesystems..."
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot
print_success "Filesystems mounted"

# Step 4: Install base system
print_step "Step 4/10: Installing base system (this may take a while)..."
pacstrap /mnt base linux linux-firmware sudo git base-devel vim networkmanager openssh grub efibootmgr
print_success "Base system installed"

# Step 5: Generate fstab
print_step "Step 5/10: Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab
print_success "fstab generated"

# Step 6: Configure system
print_step "Step 6/10: Configuring system..."
arch-chroot /mnt /bin/bash << CHROOT_SCRIPT
set -e

# Set timezone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Configure hosts file
cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOF

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd

# Configure sudo
echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Enable services
systemctl enable NetworkManager
systemctl enable sshd

echo "System configuration complete"
CHROOT_SCRIPT

print_success "System configured"

# Step 7: Install bootloader
print_step "Step 7/10: Installing bootloader..."
arch-chroot /mnt /bin/bash << CHROOT_SCRIPT
set -e

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "Bootloader installed"
CHROOT_SCRIPT

print_success "Bootloader installed"

# Step 8: Install additional packages (optional but useful)
print_step "Step 8/10: Installing additional packages..."
arch-chroot /mnt /bin/bash << CHROOT_SCRIPT
set -e

# Install useful tools
pacman -S --noconfirm \
    htop \
    wget \
    curl \
    rsync \
    unzip \
    zip \
    man-db \
    man-pages \
    bash-completion

echo "Additional packages installed"
CHROOT_SCRIPT

print_success "Additional packages installed"

# Step 9: Configure shared folder auto-mount
print_step "Step 9/10: Configuring shared folder auto-mount..."
arch-chroot /mnt /bin/bash << CHROOT_SCRIPT
set -e

# Create mount point
mkdir -p /mnt/shared

# Add to fstab for auto-mount on boot
echo "shared /mnt/shared 9p trans=virtio,version=9p2000.L,rw,_netdev 0 0" >> /etc/fstab

# Create a helpful script in user's home
cat > /home/$USERNAME/setup-dotfiles.sh << 'EOF'
#!/bin/bash
# Quick script to setup dotfiles from shared folder

if [ ! -d /mnt/shared/dotfiles ]; then
    echo "Error: Shared folder not mounted or dotfiles not found"
    echo "Try: sudo mount -t 9p -o trans=virtio shared /mnt/shared"
    exit 1
fi

echo "Copying dotfiles..."
cp -r /mnt/shared/dotfiles ~/dotfiles

echo "Running setup script..."
cd ~/dotfiles
bash install/setup.sh

echo "Done! Dotfiles installed."
EOF

chmod +x /home/$USERNAME/setup-dotfiles.sh
chown $USERNAME:$USERNAME /home/$USERNAME/setup-dotfiles.sh

echo "Shared folder configured"
CHROOT_SCRIPT

print_success "Shared folder configured"

# Step 10: Create helpful readme
print_step "Step 10/10: Creating helpful documentation..."
arch-chroot /mnt /bin/bash << CHROOT_SCRIPT
cat > /home/$USERNAME/README.txt << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║  Welcome to Arch Linux - Dotfiles Testing Environment     ║
╠═══════════════════════════════════════════════════════════╣
║                                                           ║
║  Login credentials:                                       ║
║    Username: $USERNAME                                     ║
║    Password: $PASSWORD                                     ║
║                                                           ║
║  Your dotfiles are available in: /mnt/shared/dotfiles/    ║
║                                                           ║
║  Quick start:                                             ║
║    1. Run: ./setup-dotfiles.sh                            ║
║       (This copies dotfiles and runs your setup script)   ║
║                                                           ║
║    2. Or manually:                                        ║
║       cp -r /mnt/shared/dotfiles ~/dotfiles               ║
║       cd ~/dotfiles && bash setup.sh                      ║
║                                                           ║
║  SSH Access:                                              ║
║    From host: ssh -p 2222 $USERNAME@localhost              ║
║                                                           ║
║  Useful commands:                                         ║
║    • Check shared folder: ls /mnt/shared                  ║
║    • Remount shared: sudo mount -a                        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF

chown $USERNAME:$USERNAME /home/$USERNAME/README.txt
CHROOT_SCRIPT

print_success "Documentation created"

# Cleanup
print_step "Cleaning up..."
umount -R /mnt
print_success "Installation complete!"

echo ""
BOX_WIDTH=59
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "Installation Successful!" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}╠═══════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "You can now reboot the VM" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "After reboot:" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "  • Login with: ${USERNAME} / ${PASSWORD}" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "  • Run: ./setup-dotfiles.sh" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "  • Or manually setup your dotfiles" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}║${NC}  $(pad_line "The shared folder will auto-mount at /mnt/shared/" $BOX_WIDTH)${GREEN}║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create marker file to indicate installation is complete
touch /mnt/.installed 2>/dev/null || true

read -p "Press Enter to shutdown (then restart VM without --fresh flag)..."
poweroff
