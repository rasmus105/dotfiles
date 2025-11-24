#!/bin/bash

install_paru() {
    gum_info "Installing paru (AUR helper)..."

    if ! is_installed "base-devel"; then
        gum_run "Installing base-devel" "sudo pacman --noconfirm -S base-devel"
    fi

    if ! is_installed "git"; then
        gum_run "Installing git" "sudo pacman --noconfirm -S git"
    fi

    # install paru (AUR helper)
    gum_run "Cloning paru from AUR" "rm -rf /tmp/paru && git clone https://aur.archlinux.org/paru-bin.git /tmp/paru"
    cd /tmp/paru || exit
    gum_run "Building and installing paru" "makepkg -si --noconfirm"
    cd ~ || exit
    gum_run_quiet "rm -rf /tmp/paru"
    gum_success "Paru installed successfully"
    echo ""
}

install_packages() {
    local package_file=$1

    if [[ -z "$package_file" ]]; then
        gum_error "No package list specified"
        return 1
    fi

    if [[ ! -f "$package_file" ]]; then
        gum_error "Package file not found: $package_file"
        return 1
    fi

    # Read packages from file, filter out comments and empty lines
    local packages=()
    while IFS= read -r line; do
        # Remove leading/trailing whitespace
        line=$(echo "$line" | xargs)

        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[#//] ]]; then
            continue
        fi

        packages+=("$line")
    done <"$package_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        gum_warning "No packages found in $package_file"
        return 0
    fi

    gum_info "Found ${#packages[@]} packages to install"
    echo

    # Install packages one by one to continue even if some fail
    local installed=0
    local failed=0
    local skipped=0

    for package in "${packages[@]}"; do
        if paru -Si "$package" &>/dev/null || paru -Sg "$package" &>/dev/null; then
            if paru -Q "$package" &>/dev/null; then
                gum_info "Package '$package' is already installed"
                ((skipped++))
            else
                gum_run "Installing $package" "paru -S --needed --noconfirm $package" || true
                # Verify installation by checking if package is now installed
                if paru -Q "$package" &>/dev/null; then
                    installed=$((installed + 1))
                else
                    gum_warning "Failed to install: $package"
                    failed=$((failed + 1))
                fi
            fi
        else
            gum_warning "Package not found: $package"
            failed=$((failed + 1))
        fi
    done

    echo
    gum_success "Installation complete: $installed installed, $skipped already installed, $failed failed/not found"
}
