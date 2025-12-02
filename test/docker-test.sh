#!/usr/bin/env bash
#
# Docker-based installation test
# Tests that the dotfiles installation works in a clean environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Source gum utilities from dotfiles directory
source "$DOTFILES_DIR/local/lib/shell/common.sh"

# Test configuration
IMAGE_NAME="dotfiles-test"
BASE_IMAGE_NAME="dotfiles-test-base"
CONTAINER_NAME="dotfiles-test-container"

# Note: Multi-stage build strategy for fast iteration:
# - Base image (dotfiles-test-base): Arch Linux + packages + pacman cache (cached, rarely changes)
# - Test image (dotfiles-test): Base + dotfiles repo (rebuilt every test)
# - .dockerignore excludes test/ directory to avoid copying large VM images
# - Local pacman cache (~11GB) is temporarily copied during base image build to speed up installations
#
# Test modes:
# - Default: Clones from GitHub (simulates real user installation)
# - --local: Uses local dotfiles copied during build (faster, tests local changes)

# Parse arguments
REBUILD_BASE=false
USE_LOCAL=false
while [[ $# -gt 0 ]]; do
    case $1 in
    --rebuild-base)
        REBUILD_BASE=true
        shift
        ;;
    --local)
        USE_LOCAL=true
        shift
        ;;
    --keep-container)
        KEEP_CONTAINER=true
        shift
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--rebuild-base] [--local] [--keep-container]"
        echo "  --rebuild-base:     Force rebuild of base image (includes copying pacman cache)"
        echo "  --local:            Use local dotfiles instead of cloning from GitHub"
        echo "  --keep-container:   Keep container after test"
        echo ""
        echo "Note: The base image includes your local pacman cache (~11GB) to speed up"
        echo "      package installations. The cache is temporarily copied during base image build."
        exit 1
        ;;
    esac
done

# Cleanup function
cleanup() {
    gum_info "Cleaning up container: $CONTAINER_NAME"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
}

# Set up cleanup trap
trap cleanup EXIT

# Check if Docker is installed and running
if ! command -v docker &>/dev/null; then
    gum_error "Docker not found. Install with:"
    gum_muted "  Arch Linux: sudo pacman -S docker"
    gum_muted "  Ubuntu/Debian: sudo apt install docker.io"
    gum_muted "  macOS: brew install docker"
    echo ""
    gum_info "Then start the Docker service:"
    gum_muted "  sudo systemctl start docker"
    exit 1
fi

if ! docker info &>/dev/null; then
    gum_error "Docker daemon is not running"
    gum_info "Start it with: sudo systemctl start docker"
    exit 1
fi

gum_header "Docker Installation Test" "Testing dotfiles installation in clean Arch container"
echo ""

# Prepare pacman cache for Docker build
CACHE_DIR="$DOTFILES_DIR/.cache/pacman/pkg"
CACHE_CREATED=false

if ! docker image inspect "$BASE_IMAGE_NAME" &>/dev/null || [ "$REBUILD_BASE" = true ]; then
    gum_section "Preparing package cache..."
    
    # Create cache directory structure
    mkdir -p "$CACHE_DIR"
    CACHE_CREATED=true
    
    # Copy local pacman cache to dotfiles directory for Docker build
    if [ -d "/var/cache/pacman/pkg" ] && [ -n "$(ls -A /var/cache/pacman/pkg/*.pkg.tar.zst 2>/dev/null)" ]; then
        gum_info "Copying local pacman cache (~11GB, this may take a few minutes)..."
        sudo rsync -ah --info=progress2 /var/cache/pacman/pkg/*.pkg.tar.zst "$CACHE_DIR/" || {
            gum_warning "Failed to copy pacman cache, continuing without cache"
            # Create empty cache dir so Docker build doesn't fail
            mkdir -p "$CACHE_DIR"
        }
        gum_success "Package cache prepared ($(du -sh "$CACHE_DIR" | cut -f1))"
    else
        gum_warning "No local pacman cache found at /var/cache/pacman/pkg/"
        gum_info "Creating empty cache directory"
        mkdir -p "$CACHE_DIR"
    fi
    
    echo ""
    gum_section "Building base image (this will be cached)..."
    cd "$DOTFILES_DIR"

    # Use BuildKit for better caching
    DOCKER_BUILDKIT=1 docker build \
        --target base \
        -t "$BASE_IMAGE_NAME" \
        -f test/Dockerfile . || {
        gum_error "Failed to build base image"
        # Clean up cache on failure
        if [ "$CACHE_CREATED" = true ]; then
            rm -rf "$CACHE_DIR"
        fi
        exit 1
    }
    gum_success "Base image built and cached"
else
    gum_success "Using cached base image"
    # Still need to create an empty cache directory for the full image build
    # (in case Docker needs to rebuild base stage for some reason)
    if [ ! -d "$CACHE_DIR" ]; then
        mkdir -p "$CACHE_DIR"
        CACHE_CREATED=true
    fi
fi

# Build full Docker image (only copies dotfiles, very fast)
echo ""
gum_section "Building test image with dotfiles..."
cd "$DOTFILES_DIR"

DOCKER_BUILDKIT=1 docker build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t "$IMAGE_NAME" \
    -f test/Dockerfile . || {
    gum_error "Failed to build Docker image"
    # Clean up cache on failure if we created it
    if [ "$CACHE_CREATED" = true ]; then
        rm -rf "$CACHE_DIR"
    fi
    exit 1
}
gum_success "Test image built"

# Clean up cache directory after all builds complete (only if we created it this run)
if [ "$CACHE_CREATED" = true ] && [ -d "$CACHE_DIR" ]; then
    gum_info "Cleaning up temporary cache directory..."
    rm -rf "$CACHE_DIR"
fi

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

if [ "$USE_LOCAL" = true ]; then
    # Test the local installation (dotfiles were copied during build)
    gum_header "Testing with local dotfiles (already copied to container)"
    # Run without -t to avoid terminal query escape codes being sent back
    docker exec -i -t -u testuser "$CONTAINER_NAME" bash -c "
        cd /home/testuser/dotfiles
        export USE_DEFAULT_OPTIONS=1
        # Skip install.sh and run setup.sh directly since dotfiles are already present
        bash install/setup.sh
    " || {
        gum_header "Installation test failed!"
        echo ""
        gum_info "Container logs:"
        docker logs "$CONTAINER_NAME"
        exit 1
    }
else
    # Test by cloning from GitHub (simulates real installation)
    gum_header "Testing with GitHub clone (simulates real installation)"
    docker exec -i -t -u testuser "$CONTAINER_NAME" bash -c "
        export USE_DEFAULT_OPTIONS=1
        curl -fsSL https://raw.githubusercontent.com/rasmus105/dotfiles/main/install.sh | bash
    " || {
        gum_header "Installation test failed!"
        echo ""
        gum_info "Container logs:"
        docker logs "$CONTAINER_NAME"
        exit 1
    }
fi

gum_header "Installation completed successfully!"

# Verify key files were installed
echo ""
gum_section "Verifying installation..."

docker exec -i -t -u testuser "$CONTAINER_NAME" bash -c "
    set -e
    
    # Check that dotfiles directory exists
    test -d ~/.dotfiles || { echo '✗ dotfiles directory not found'; exit 1; }
    echo '✓ dotfiles directory exists'
    
    # Check if stow was run (config directory should be linked)
    test -d ~/.config || { echo '✗ .config directory not found'; exit 1; }
    echo '✓ .config directory exists'
    
    # Check for specific symlinks created by stow
    if [ -L ~/.config/nvim ] || [ -d ~/.config/nvim ]; then
        echo '✓ nvim config present'
    fi
    
    if [ -L ~/.zshrc ] || [ -f ~/.zshrc ]; then
        echo '✓ zshrc present'
    fi
    
    # Check that shell was changed to zsh
    if getent passwd testuser | grep -q zsh; then
        echo '✓ Default shell set to zsh'
    else
        echo '⚠ Default shell not set to zsh (expected for test)'
    fi
    
    # Check for dotfiles_env file
    test -f ~/.dotfiles_env && echo '✓ dotfiles_env file created'
    
    echo '✓ All verification checks passed'
" || {
    gum_error "Verification failed"
    exit 1
}

gum_success "All Tests Passed! ✓"

# Optional: keep container running for inspection
if [[ "${KEEP_CONTAINER:-}" == "true" ]]; then
    gum_info "Container kept running for inspection:"
    gum_muted "  docker exec -it $CONTAINER_NAME bash"
    gum_muted "  docker rm -f $CONTAINER_NAME  # when done"
    trap - EXIT # Remove cleanup trap
fi
