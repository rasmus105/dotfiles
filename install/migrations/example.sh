#!/bin/bash
#
# Example migration script
# Copy this template when creating a new migration
#

set -e

# ==== Verify and Source common.sh ====

COMMON_SH="$HOME/.local/lib/shell/common.sh"
if [[ ! -f "$COMMON_SH" ]]; then
    echo "✗ Error: Required file not found: $COMMON_SH"
    echo ""
    echo "This indicates your dotfiles are not properly installed."
    echo "The common.sh file should be symlinked during dotfiles installation."
    echo ""
    echo "Please run dotfiles installation/stow:"
    echo "  cd \$DOTFILES_DIR"
    echo "  bash install/stow.sh"
    echo ""
    exit 1
fi

# Source helper functions (provides gum utilities and common functions)
source "$COMMON_SH"

# ==== DOTFILES_DIR Setup ====

# Check if DOTFILES_DIR is set in environment
if [[ -z "$DOTFILES_DIR" ]]; then
    gum_warning "DOTFILES_DIR environment variable is not set"
    gum_info "This could indicate incorrect setup (should be set in .bashrc/.zshrc)"
    echo ""
    
    # Determine fallback path
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
    FALLBACK_DOTFILES_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
    
    gum_info "What would you like to do?"
    CHOICE=$(gum choose "Abort migration" "Add DOTFILES_DIR to shell configs" "Ignore and use fallback ($FALLBACK_DOTFILES_DIR)")
    
    case "$CHOICE" in
        "Abort migration")
            gum_info "Migration aborted by user"
            exit 1
            ;;
        "Add DOTFILES_DIR to shell configs")
            echo ""
            gum_info "Adding DOTFILES_DIR to ~/.bashrc and ~/.zshrc..."
            
            # Add to .bashrc
            if ! grep -q "export DOTFILES_DIR=" "$HOME/.bashrc" 2>/dev/null; then
                echo "export DOTFILES_DIR=\"$FALLBACK_DOTFILES_DIR\"" >> "$HOME/.bashrc"
                gum_success "Added to ~/.bashrc"
            else
                sed -i "s|export DOTFILES_DIR=.*|export DOTFILES_DIR=\"$FALLBACK_DOTFILES_DIR\"|" "$HOME/.bashrc"
                gum_success "Updated in ~/.bashrc"
            fi
            
            # Add to .zshrc
            if ! grep -q "export DOTFILES_DIR=" "$HOME/.zshrc" 2>/dev/null; then
                echo "export DOTFILES_DIR=\"$FALLBACK_DOTFILES_DIR\"" >> "$HOME/.zshrc"
                gum_success "Added to ~/.zshrc"
            else
                sed -i "s|export DOTFILES_DIR=.*|export DOTFILES_DIR=\"$FALLBACK_DOTFILES_DIR\"|" "$HOME/.zshrc"
                gum_success "Updated in ~/.zshrc"
            fi
            
            # Use the fallback for this script
            DOTFILES_DIR="$FALLBACK_DOTFILES_DIR"
            export DOTFILES_DIR
            echo ""
            gum_success "DOTFILES_DIR set for this session and added to shell configs"
            gum_info "Note: You may need to restart your shell for changes to take effect"
            echo ""
            ;;
        "Ignore and use fallback ($FALLBACK_DOTFILES_DIR)")
            DOTFILES_DIR="$FALLBACK_DOTFILES_DIR"
            gum_info "Using fallback: $DOTFILES_DIR"
            echo ""
            ;;
    esac
fi

# ==== Migration Logic ====

gum_info "Running example migration..."

# Example: Check if something exists before creating it
if [[ ! -f "$HOME/.config/example/config" ]]; then
    gum_info "Creating example config..."
    mkdir -p "$HOME/.config/example"
    echo "example=true" > "$HOME/.config/example/config"
    gum_success "Config created"
else
    gum_info "Config already exists, skipping"
fi

# Example: Install a package if not present
if ! is_installed "example-package"; then
    gum_info "Installing example-package..."
    # paru -S --noconfirm example-package
    gum_success "Package installed"
else
    gum_info "Package already installed"
fi

gum_success "Migration complete!"
