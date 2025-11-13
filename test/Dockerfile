# Dockerfile for testing dotfiles installation
# Multi-stage build for better caching

# Stage 1: Base image with dependencies (this layer is cached)
FROM archlinux:latest AS base

# Update package database and install required tools
# This layer will be cached unless Arch updates significantly
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    git \
    curl \
    sudo \
    expect && \
    # Clean pacman cache to reduce image size
    pacman -Scc --noconfirm

# Create a test user (installation shouldn't be run as root)
RUN useradd -m -G wheel -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Stage 2: Add dotfiles (this layer changes frequently)
FROM base AS dotfiles

# Set working directory
WORKDIR /home/testuser

# Copy the dotfiles repository into the container
# .dockerignore will exclude test/ directory and other large files
COPY --chown=testuser:testuser . /home/testuser/dotfiles

# Switch to test user
USER testuser

# Set environment variables for non-interactive installation
ENV USE_DEFAULT_OPTIONS=1

# The test will be run by the test script, not in the build
CMD ["/bin/bash"]

