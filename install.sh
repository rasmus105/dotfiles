#!/bin/bash
set -e

# Non-interactive mode support
# Set to 1 to skip all prompts and use defaults
USE_DEFAULT_OPTIONS="${USE_DEFAULT_OPTIONS:-0}"

DOTFILES_DIR="$HOME/.dotfiles/"
REPO_URL="https://github.com/rasmus105/dotfiles.git"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Simple prompt function that respects USE_DEFAULT_OPTIONS
prompt_confirm() {
    local prompt="$1"
    local default="${2:-y}"
    
    if [[ "$USE_DEFAULT_OPTIONS" == "1" ]]; then
        echo -e "${BLUE}$prompt${NC} (auto: $default)"
        [[ "$default" =~ ^[Yy] ]]
        return $?
    fi
    
    read -r -p "$(echo -e "${BLUE}$prompt [Y/n]${NC} ")" answer
    answer=${answer:-$default}
    [[ $answer =~ ^[Yy] ]]
}

echo "Starting installation..."
echo

if [ -d "$DOTFILES_DIR" ]; then
    echo -e "${YELLOW}Warning:${NC} '$DOTFILES_DIR' already exists!"
    
    if [[ "$USE_DEFAULT_OPTIONS" == "1" ]]; then
        # Non-interactive: create backup and continue
        BACKUP_PATH="$HOME/.dotfiles.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${YELLOW}Creating backup (auto)...${NC}"
        mv "$DOTFILES_DIR" "$BACKUP_PATH"
        echo -e "${GREEN}✓${NC} Backup created at: $BACKUP_PATH"
    else
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
                    read -r -p "$(echo -e "${BLUE}Enter new directory path: ${NC}")" DOTFILES_DIR
                    DOTFILES_DIR="${DOTFILES_DIR/#\~/$HOME}"
                    echo -e "${GREEN}✓${NC} New directory: $DOTFILES_DIR"
                    break
                    ;;
            esac
        done
    fi
fi

echo "Selected dotfiles directory: '$DOTFILES_DIR'"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing git..."
    sudo pacman -S --noconfirm git
    echo -e "${GREEN}✓${NC} Git installed successfully!"
fi

echo "Cloning dotfiles directory..."
git clone "$REPO_URL" "$DOTFILES_DIR"

echo 
echo -e "${GREEN}✓${NC} Repository has been cloned succesfully!"

if prompt_confirm "Proceed with setup?" "y"; then
    echo
    # Export for setup.sh to use
    export USE_DEFAULT_OPTIONS
    bash "$DOTFILES_DIR/install/setup.sh"
else
    echo -e "${YELLOW}Setup skipped. Run 'bash $DOTFILES_DIR/install/setup.sh' when ready.${NC}"
fi
