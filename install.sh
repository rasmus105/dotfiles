#!/bin/bash
set -e

DOTFILES_DIR="$HOME/.dotfiles/"
REPO_URL="https://github.com/rasmus105/dotfiles.git"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "Starting installation..."
echo

if [ -d "$DOTFILES_DIR" ]; then
    echo -e "${YELLOW}Warning:${NC} '$DOTFILES_DIR' already exists!"
    
    options=(
        "Abort"
        "Overwrite (creates backup at ~/.dotfiles.backup)"
        "Choose different directory"
    )
    
    # Add color to prompt - note the trailing space before closing quote
    PS3="$(echo -e "${BLUE}Select an option (1-${#options[@]}): ${NC}")"
    
    COLUMNS=12 # show options on seperate lines
    select choice in "${options[@]}"; do
        if [[ -z "$choice" ]]; then
            echo -e "${RED}Invalid selection. Please enter a number between 1 and ${#options[@]}${NC}"
            continue
        fi
        
        case $choice in
            "Abort")
                echo -e "${RED}Installation aborted.${NC}"
                exit 1
                ;;
            "Overwrite (creates backup at ~/.dotfiles.backup)")
                BACKUP_PATH="$HOME/.dotfiles.backup.$(date +%Y%m%d_%H%M%S)"
                echo -e "${YELLOW}Creating backup...${NC}"
                mv "$DOTFILES_DIR" "$BACKUP_PATH"
                echo -e "${GREEN}✓${NC} Backup created at: $BACKUP_PATH"
                break
                ;;
            "Choose different directory")
                read -p "$(echo -e "${BLUE}Enter new directory path: ${NC}")" DOTFILES_DIR
                DOTFILES_DIR="${DOTFILES_DIR/#\~/$HOME}"
                echo -e "${GREEN}✓${NC} New directory: $DOTFILES_DIR"
                break
                ;;
        esac
    done
fi

echo "Selected dotfiles directory: '$DOTFILES_DIR'"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing git..."
    sudo pacman -S --noconfirm git
    echo -e "${GREEN}✓${NC} Git installed successfully!"
fi

echo "Cloning dotfiles directory..."
git clone $REPO_URL $DOTFILES_DIR

echo 
echo "${GREEN}✓${NC} Repository has been cloned succesfully!"
read -p "Proceed with setup? [Y/n] " answer; answer=${r:-y}; [[ $answer =~ ^[Yy] ]]
echo

bash "$DOTFILES_DIR/install/setup.sh"
