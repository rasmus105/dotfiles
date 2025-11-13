# Dockerfile for testing dotfiles installation
FROM archlinux:latest

# Update package database and install required tools
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    git \
    curl \
    sudo \
    expect

# Create a test user (installation shouldn't be run as root)
RUN useradd -m -G wheel -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set working directory
WORKDIR /home/testuser

# Copy the dotfiles repository into the container
COPY --chown=testuser:testuser . /home/testuser/dotfiles

# Switch to test user
USER testuser

# Set environment variables for non-interactive installation
ENV DOTFILES_AUTO_YES=1
ENV DOTFILES_SKIP_INTERACTIVE=1

# The test will be run by the test script, not in the build
CMD ["/bin/bash"]
