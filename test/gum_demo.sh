#!/bin/bash

# Demo script for gum_utils.sh formatting
# Sources common.sh which includes gum_utils.sh

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")

source "$HOME/.local/lib/shell/common.sh"

echo "Demonstrating gum_utils.sh formatting:"
echo

gum_header "Gum Utils Demo" "Color and Style Examples"

gum_section "Color Examples"
gum_success "This is a success message"
gum_error "This is an error message"
gum_warning "This is a warning message"
gum_info "This is an info message"
gum_muted "This is a muted message"

echo
gum_section "Formatting Examples"
gum_bold "This is bold text"
gum_italic "This is italic text"
gum_format "This is formatted text" "$GUM_COLOR_ACCENT"

echo
gum_section "Box Examples"
gum_box "This is a simple box"
gum_box_colored "This is a colored box" "$GUM_COLOR_WARNING"

gum_show
