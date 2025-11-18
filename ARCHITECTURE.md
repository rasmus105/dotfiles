# Architecture Documentation

## Overview

This dotfiles repository provides an automated and reproducible system configuration for Arch Linux with Hyprland. The architecture emphasizes modularity, testability, and ease of maintenance.

## System Architecture

### Directory Structure

```
dotfiles/
├── bin/                    # Custom utility scripts
├── common/                 # Shared utilities
│   └── gum_utils.sh       # UI/UX utilities using gum
├── config/                 # Application configurations (.config/)
│   ├── hypr/              # Hyprland configuration
│   ├── nvim/              # Neovim configuration
│   ├── alacritty/         # Alacritty terminal
│   ├── waybar/            # Waybar status bar
│   └── ...                # Other app configs
├── home/                   # Home directory files
│   ├── .zshrc             # Zsh configuration
│   ├── .gitconfig         # Git configuration
│   └── .zsh_plugins.txt   # Zsh plugins list
├── install/                # Installation scripts
│   ├── setup.sh           # Main setup orchestrator
│   ├── stow.sh            # GNU Stow symlink manager
│   ├── install_packages.sh # Package installation logic
│   ├── setup_zsh.sh       # Zsh-specific setup
│   └── packages.txt       # List of packages to install
├── local/                  # .local directory files
├── system/                 # System-level configurations
├── themes/                 # Color schemes and themes
│   ├── gruvbox/           # Gruvbox theme (default)
│   ├── catppuccin/        # Catppuccin theme
│   └── ...                # Additional themes
├── test/                   # Testing infrastructure
│   ├── Dockerfile         # Docker test environment
│   ├── docker-test.sh     # Docker-based tests
│   └── vm/                # VM testing scripts
├── install.sh              # Entry point installer
└── common.sh              # Common functions and setup

```

## Core Components

### 1. Installation System

#### Entry Point (`install.sh`)
- **Purpose**: Initial bootstrap script that users run to install dotfiles
- **Responsibilities**:
  - Checks if dotfiles directory exists
  - Handles conflicts (backup, overwrite, or choose different directory)
  - Clones repository from GitHub
  - Invokes setup.sh for configuration
- **Features**:
  - Non-interactive mode (`USE_DEFAULT_OPTIONS=1`)
  - Colored output for better UX
  - Automatic backup creation on conflicts

#### Setup Orchestrator (`install/setup.sh`)
- **Purpose**: Main configuration script that installs packages and applies settings
- **Workflow**:
  1. Initialize logging
  2. Install paru (AUR helper) if not present
  3. Install packages from packages.txt
  4. Configure zsh (set as default shell, install antidote plugin manager)
  5. Run GNU Stow to create symlinks
  6. Configure mimetype associations
- **Design Pattern**: Modular sourcing of specialized scripts

#### Package Manager (`install/install_packages.sh`)
- **Purpose**: Handles package installation from lists
- **Features**:
  - Reads package list from file
  - Filters comments and empty lines
  - Installs packages individually for fault tolerance
  - Reports success/failure statistics
  - Checks for package existence before installation

#### Symlink Manager (`install/stow.sh`)
- **Purpose**: Creates symlinks using GNU Stow
- **Strategy**:
  - `config/` → `~/.config/`
  - `home/` → `~`
  - `local/` → `~/.local/`
  - `themes/gruvbox` → `~/.config/theme` (default)
  - `themes/` → `~/.config/themes/` (all themes)
- **Benefits**: 
  - Easy rollback (unstow)
  - No file duplication
  - Version control friendly

### 2. Testing Infrastructure

#### Docker-Based Testing (`test/docker-test.sh`)
- **Purpose**: Automated, fast testing in clean container
- **Architecture**: Multi-stage build
  - **Base stage**: Arch Linux + system packages (cached)
  - **Dotfiles stage**: Base + dotfiles repository (rebuilt frequently)
- **Test Modes**:
  - **GitHub mode** (default): Clones from GitHub to simulate real user experience
  - **Local mode** (`--local`): Uses local dotfiles for faster iteration
- **Features**:
  - BuildKit caching for speed
  - `.dockerignore` excludes test/VM files
  - Verification checks post-installation
  - Container cleanup with option to keep for debugging

#### VM-Based Testing (`test/vm/vm.sh`)
- **Purpose**: Full system testing with graphical environment
- **Use Case**: Manual testing of Hyprland and GUI applications
- **Features**:
  - QEMU with KVM acceleration
  - UEFI boot with OVMF
  - Shared folder for dotfiles access
  - Auto-install mode (`--auto-install`)
  - Snapshot support (`vm-snapshot.sh`) for quick rollbacks
- **Configuration**: 20GB disk, 4GB RAM, 4 CPUs

#### Automated VM Installation (`test/vm/vm-auto-install.sh`)
- **Purpose**: Unattended Arch Linux installation in VM
- **Process**:
  1. Partition disk (GPT with EFI)
  2. Format and mount filesystems
  3. Install base system with pacstrap
  4. Configure system (timezone, locale, hostname, users)
  5. Install GRUB bootloader
  6. Configure shared folder auto-mount
  7. Create helper scripts for dotfiles setup

### 3. UI/UX System (`common/gum_utils.sh`)

#### Design Philosophy
- Consistent, beautiful terminal UI using [gum](https://github.com/charmbracelet/gum)
- Non-interactive mode support for automated testing/CI
- Comprehensive logging to `install/log/`

#### Key Functions
- **Styled Messages**: `gum_success()`, `gum_error()`, `gum_warning()`, `gum_info()`
- **Interactive Prompts**: `gum_confirm()`, `gum_choose()`, `gum_input()`
- **Non-Interactive Wrappers**: `gum_confirm_default()`, `gum_choose_default()`, `gum_input_default()`
  - Mandatory default values force conscious decisions about automation behavior
- **Logging**: `gum_run()` executes commands with spinner and logs output
- **Formatting**: Headers, boxes, separators for visual hierarchy

### 4. Theme System

#### Architecture
- **Location**: `themes/` directory contains all color schemes
- **Default**: Gruvbox
- **Integration Points**:
  - Hyprland: Colors, borders, window decorations
  - Terminal: Alacritty, Ghostty
  - Status bar: Waybar
  - Text editor: Neovim
  - System utilities: btop
- **Switching**: `bin/system-set-theme` utility changes theme system-wide
- **Update Scripts**: Individual scripts in `bin/` update specific applications

## Design Patterns

### 1. Separation of Concerns
- **Installation logic** separate from **configuration files**
- **Testing infrastructure** isolated in `test/`
- **Utilities** abstracted into reusable functions

### 2. Fail-Safe Design
- Package installation continues even if individual packages fail
- Backup creation before overwriting existing dotfiles
- Non-destructive operations (symlinks instead of copies)

### 3. Modularity
- Scripts source specialized modules
- Each script has single responsibility
- Easy to add/remove components

### 4. Testability
- Docker tests for quick validation
- VM tests for comprehensive system testing
- Non-interactive mode enables CI/CD

### 5. User Experience
- Clear visual feedback with gum utilities
- Informative error messages
- Interactive prompts with sensible defaults
- Comprehensive logging for debugging

## Data Flow

### Installation Flow
```
install.sh
    ├─→ Check/create dotfiles directory
    ├─→ Clone repository
    └─→ install/setup.sh
            ├─→ Initialize logging (gum_utils.sh)
            ├─→ Install paru (install_packages.sh)
            ├─→ Install packages (install_packages.sh)
            ├─→ Setup zsh (setup_zsh.sh)
            ├─→ Create symlinks (stow.sh)
            └─→ Configure mimetypes (config/mimetypes.sh)
```

### Testing Flow

#### Docker Test
```
test/docker-test.sh
    ├─→ Build base image (cached)
    ├─→ Build dotfiles image (fast)
    ├─→ Run container
    ├─→ Execute installation
    │       └─→ install.sh (or setup.sh for --local mode)
    ├─→ Verify installation
    └─→ Cleanup container
```

#### VM Test
```
test/vm/vm.sh
    ├─→ Download Arch ISO (if needed)
    ├─→ Create disk image (if needed)
    ├─→ Copy dotfiles to shared directory
    ├─→ Launch QEMU with virtio shared folder
    └─→ User performs installation
            ├─→ vm-auto-install.sh (automated)
            └─→ OR manual archinstall
```

## Key Technologies

### Core Tools
- **GNU Stow**: Symlink farm manager
- **Gum**: Terminal UI toolkit
- **Paru**: AUR helper (Arch User Repository)
- **Antidote**: Zsh plugin manager

### System Stack
- **OS**: Arch Linux
- **Display Server**: Wayland
- **Compositor**: Hyprland
- **Shell**: Zsh
- **Terminal**: Alacritty, Ghostty
- **Status Bar**: Waybar
- **Notifications**: Mako
- **Launcher**: Walker
- **Editor**: Neovim

### Testing Stack
- **Docker**: Container-based testing
- **QEMU/KVM**: Full system virtualization
- **ShellCheck**: Static analysis for shell scripts

## Configuration Management

### Symlink Strategy
GNU Stow creates symlinks from repository to home directory:
- Preserves git history in repository
- Changes reflect immediately
- Easy to track and revert
- No manual copying required

### Theme Management
- Centralized theme definitions in `themes/`
- Symlink `~/.config/theme` points to active theme
- Applications read from `~/.config/theme/`
- Update scripts propagate theme changes to all applications

## Error Handling

### Installation Errors
- Package installation continues if individual package fails
- Detailed logging to `install/log/install-TIMESTAMP.log`
- Clear error messages with context
- Exit codes propagate failures

### Testing Errors
- Docker test reports failures with container logs
- VM test provides interactive access for debugging
- Verification steps catch incomplete installations

## Security Considerations

### Sudo Usage
- Minimal sudo requirements
- User prompted for password (cached at setup start)
- Wheel group configured with NOPASSWD (for testing only)

### Private Data
- `.gitignore` excludes `git/` directory for credentials
- `.dockerignore` prevents secrets in Docker images
- Backup files excluded from version control

## Performance Optimizations

### Docker Testing
- Multi-stage builds minimize rebuild time
- Base image cached with system packages
- BuildKit inline caching
- `.dockerignore` excludes large files (VM images)

### Package Installation
- Parallel possible with paru
- Skip already-installed packages
- Continue on individual package failures

## Extensibility

### Adding Configurations
1. Add config to appropriate directory (`config/`, `home/`, `local/`)
2. Stow automatically creates symlinks
3. Add package to `install/packages.txt` if needed

### Adding Themes
1. Create directory in `themes/`
2. Follow naming convention from existing themes
3. Add update logic to `bin/update-*-theme` scripts if needed

### Adding Tests
1. Docker: Extend verification checks in `docker-test.sh`
2. VM: Create additional scripts in `test/vm/`

## Future Considerations

### Potential Improvements
1. **CI/CD Integration**: GitHub Actions workflow for automated testing
2. **Multi-Distribution Support**: Currently Arch-only
3. **Modular Installation**: Optional components (minimal, full, custom)
4. **Update Mechanism**: Pull latest dotfiles and re-stow
5. **Backup System**: Before stowing, backup existing configs
6. **Documentation**: More detailed per-component documentation
7. **Dotfile Templates**: Generate configs from templates for personalization

### Known Limitations
1. Arch Linux only (pacman/paru specific)
2. Hyprland/Wayland focused (no X11 support)
3. Requires sudo access for package installation
4. VM testing requires significant resources (4GB RAM, 20GB disk)

## Contributing

When contributing to this repository:
1. Run `shellcheck` on modified scripts
2. Test with Docker (`test/docker-test.sh --local`)
3. Ensure non-interactive mode works (`USE_DEFAULT_OPTIONS=1`)
4. Update this documentation for architectural changes
5. Follow existing code style and conventions

## References

- [GNU Stow](https://www.gnu.org/software/stow/)
- [Gum - Terminal UI toolkit](https://github.com/charmbracelet/gum)
- [Hyprland Documentation](https://wiki.hyprland.org/)
- [Arch Linux Installation Guide](https://wiki.archlinux.org/title/Installation_guide)
