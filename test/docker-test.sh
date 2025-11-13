#!/usr/bin/env bash
#
# Docker-based installation test
# Tests that the dotfiles installation works in a clean environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source gum utilities
source "$SCRIPT_DIR/../common/gum_utils.sh"

# Test configuration
IMAGE_NAME="dotfiles-test"
CONTAINER_NAME="dotfiles-test-container"

# Cleanup function
cleanup() {
    gum_info "Cleaning up container: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup EXIT

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    gum_error "Docker not found. Install with:"
    gum_muted "  Arch Linux: sudo pacman -S docker"
    gum_muted "  Ubuntu/Debian: sudo apt install docker.io"
    gum_muted "  macOS: brew install docker"
    echo ""
    gum_info "Then start the Docker service:"
    gum_muted "  sudo systemctl start docker"
    exit 1
fi

if ! docker info &> /dev/null; then
    gum_error "Docker daemon is not running"
    gum_info "Start it with: sudo systemctl start docker"
    exit 1
fi

gum_header "Docker Installation Test" "Testing dotfiles installation in clean Arch container"
echo ""

# Build Docker image
gum_section "Building Docker image..."
cd "$DOTFILES_DIR"
docker build -t "$IMAGE_NAME" -f test/Dockerfile . || {
    gum_error "Failed to build Docker image"
    exit 1
}
gum_success "Docker image built"

# Run container
echo ""
gum_section "Starting test container..."
docker run -d --name "$CONTAINER_NAME" "$IMAGE_NAME" sleep infinity || {
    gum_error "Failed to start container"
    exit 1
}
gum_success "Container started"

# Run the installation test
echo ""
gum_section "Running installation test..."
echo ""

# Test the local installation (since we copied the repo)
docker exec -u testuser "$CONTAINER_NAME" bash -c "
    cd /home/testuser/dotfiles
    export USE_DEFAULT_OPTIONS=1
    bash install.sh
" || {
    gum_error "Installation test failed!"
    echo ""
    gum_info "Container logs:"
    docker logs "$CONTAINER_NAME"
    exit 1
}

gum_success "Installation completed successfully!"

# Verify key files were installed
echo ""
gum_section "Verifying installation..."

docker exec -u testuser "$CONTAINER_NAME" bash -c "
    set -e
    
    # Check that dotfiles directory exists
    test -d ~/dotfiles || { echo 'dotfiles directory not found'; exit 1; }
    
    # Check if stow was run (at least some configs should be linked)
    if [ -d ~/.config ]; then
        echo '✓ .config directory exists'
    fi
    
    # Add more specific checks here based on your dotfiles structure
    # Examples:
    # test -L ~/.config/nvim/init.lua && echo '✓ nvim config linked'
    # test -L ~/.zshrc && echo '✓ zshrc linked'
    
    echo 'Basic verification checks passed'
" || {
    gum_error "Verification failed"
    exit 1
}

gum_success "Verification passed"

echo ""
gum_header "All Tests Passed! ✓"
echo ""

# Optional: keep container running for inspection
if [[ "${KEEP_CONTAINER:-}" == "true" ]]; then
    gum_info "Container kept running for inspection:"
    gum_muted "  docker exec -it $CONTAINER_NAME bash"
    gum_muted "  docker rm -f $CONTAINER_NAME  # when done"
    trap - EXIT  # Remove cleanup trap
else
    cleanup
fi
