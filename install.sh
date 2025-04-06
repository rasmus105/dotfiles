#!/bin/zsh

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Set default values
if [[ -z $DOTFILES ]]; then
    DOTFILES=$HOME/.dotfiles
fi

# Detect OS
OS=""
if [[ -f /etc/arch-release ]]; then
    OS="arch"
elif [[ -f /etc/lsb-release ]] && grep -q "Ubuntu" /etc/lsb-release; then
    OS="ubuntu"
else
    echo -e "${YELLOW}Unsupported OS detected. Proceeding with limited functionality.${NC}"
    OS="unknown"
fi
echo -e "${BLUE}${BOLD}Detected OS:${NC} ${CYAN}$OS${NC}\n"

# Function to print section headers
print_header() {
    echo -e "\n${MAGENTA}${BOLD}$1${NC}"
    echo -e "${MAGENTA}$(printf '=%.0s' {1..50})${NC}"
}

# Function to ask yes/no questions
ask() {
    local prompt=$1
    local default=$2
    local reply
    
    if [[ "$default" = "Y" ]]; then
        prompt="${prompt} [Y/n] "
    else
        prompt="${prompt} [y/N] "
    fi
    
    echo -ne "${YELLOW}${prompt}${NC}"
    read reply
    
    if [[ -z "$reply" ]]; then
        reply=$default
    fi
    
    if [[ "$reply" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to install packages based on OS
install_packages() {
    print_header "Installing Required Packages"
    
    local common_packages="stow git curl wget zsh"
    local arch_packages="yay hyprland waybar alacritty tmux neovim dunst"
    local ubuntu_packages="i3 polybar alacritty tmux neovim dunst"
    
    if [[ "$OS" == "arch" ]]; then
        echo -e "${CYAN}Installing Arch Linux packages...${NC}"
        if ask "Do you want to install the following packages? \n${arch_packages}" "Y"; then
            echo -e "${GREEN}Installing packages with pacman...${NC}"
            sudo pacman -S --needed $common_packages $arch_packages
            
            # Check if yay is installed, if not install it
            if ! command -v yay &> /dev/null; then
                echo -e "${YELLOW}Installing yay AUR helper...${NC}"
                git clone https://aur.archlinux.org/yay.git /tmp/yay
                (cd /tmp/yay && makepkg -si --noconfirm)
                rm -rf /tmp/yay
            fi
        fi
    elif [[ "$OS" == "ubuntu" ]]; then
        echo -e "${CYAN}Installing Ubuntu packages...${NC}"
        if ask "Do you want to install the following packages? \n${ubuntu_packages}" "Y"; then
            echo -e "${GREEN}Installing packages with apt...${NC}"
            sudo apt update
            sudo apt install -y $common_packages $ubuntu_packages
            
            # Install Hyprland if desired (for Ubuntu)
            if ask "Do you want to install Hyprland? (requires additional steps on Ubuntu)" "N"; then
                echo -e "${YELLOW}Installing Hyprland dependencies...${NC}"
                sudo apt install -y meson cmake gcc ninja-build libwayland-dev libwlroots-dev
                git clone https://github.com/hyprwm/Hyprland /tmp/hyprland
                (cd /tmp/hyprland && make && sudo make install)
                rm -rf /tmp/hyprland
            fi
        fi
    else
        echo -e "${RED}Automatic package installation not supported for your OS.${NC}"
        echo -e "${YELLOW}Please install required packages manually.${NC}"
    fi
}

# Function to select which dotfiles to install
select_dotfiles() {
    print_header "Selecting Dotfiles to Install"
    
    # Default options
    local default_folders="alacritty,dunst,hypr,nvim,tmux,waybar,zsh"
    
    # Adjust based on OS
    if [[ "$OS" == "ubuntu" ]]; then
        default_folders="alacritty,dunst,i3,nvim,tmux,polybar,zsh"
    fi
    
    # Ask user for custom selection
    echo -e "${CYAN}Default dotfiles:${NC} ${default_folders}"
    if ask "Do you want to customize which dotfiles to install?" "N"; then
        echo -e "${YELLOW}Available dotfiles:${NC}"
        ls -ld */ 2>/dev/null | cut -d/ -f1 | grep -v "^.$" | sort | column
        echo -e "${YELLOW}Enter comma-separated list of folders:${NC}"
        read -r STOW_FOLDERS
    else
        STOW_FOLDERS=$default_folders
    fi
    
    echo -e "${GREEN}Selected dotfiles:${NC} ${STOW_FOLDERS}"
}

# Function to stow dotfiles
stow_dotfiles() {
    print_header "Symlinking Dotfiles"
    
    # Make sure DOTFILES is set correctly
    DOTFILES=$(pwd)
    echo -e "${BLUE}Dotfiles directory:${NC} ${DOTFILES}"
    
    # Process each folder
    local count=0
    local total=$(echo $STOW_FOLDERS | tr ',' ' ' | wc -w)
    
    for folder in $(echo $STOW_FOLDERS | sed "s/,/ /g"); do
        ((count++))
        echo -e "${YELLOW}[${count}/${total}]${NC} Processing ${CYAN}${folder}${NC}..."
        
        # Check if folder exists
        if [[ ! -d "$folder" ]]; then
            echo -e "  ${RED}Folder not found, skipping${NC}"
            continue
        fi
        
        # Delete existing symlinks
        echo -e "  ${BLUE}Removing existing symlinks...${NC}"
        stow -D $folder 2>/dev/null
        
        # Create new symlinks
        echo -e "  ${GREEN}Creating new symlinks...${NC}"
        stow $folder
        
        # Verify installation
        if [[ $? -eq 0 ]]; then
            echo -e "  ${GREEN}✓ Successfully installed ${folder}${NC}"
        else
            echo -e "  ${RED}✗ Failed to install ${folder}${NC}"
        fi
    done
}

# Function to setup additional configurations
setup_extras() {
    print_header "Setting Up Additional Configurations"
    
    # Set zsh as default shell if desired
    if ask "Do you want to set zsh as your default shell?" "Y"; then
        echo -e "${GREEN}Setting zsh as default shell...${NC}"
        chsh -s $(which zsh)
    fi
}

# Main script execution
print_header "Linux System Setup"
echo -e "${BOLD}This script will set up your Linux environment with your dotfiles.${NC}"

# Ask if user wants to install packages
if ask "Do you want to install required packages?" "Y"; then
    install_packages
fi

# Select which dotfiles to install
select_dotfiles

# Stow the selected dotfiles
stow_dotfiles

# Setup additional configurations
if ask "Do you want to set up additional configurations?" "Y"; then
    setup_extras
fi

print_header "Setup Complete"
echo -e "${GREEN}${BOLD}Your system has been successfully configured!${NC}"
echo -e "${YELLOW}You may need to log out and back in for all changes to take effect.${NC}"
