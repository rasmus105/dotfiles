# Dotfiles with Automatic Installation and Testing

A comprehensive, production-ready dotfiles repository for Arch Linux with Hyprland, featuring automated installation, extensive testing infrastructure, and beautiful terminal UI.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)
![Platform](https://img.shields.io/badge/platform-arch%20linux-blue.svg)

## ✨ Features

- 🚀 **One-Command Installation** - Clone and install with a single curl command
- 🧪 **Comprehensive Testing** - Docker-based CI and VM-based manual testing
- 🎨 **Theme System** - Multiple color schemes with easy switching
- 📦 **Package Management** - Automated installation from curated package list
- 🔗 **GNU Stow Integration** - Clean symlink management for version control
- 💅 **Beautiful UI** - Terminal UI powered by [gum](https://github.com/charmbracelet/gum)
- 🤖 **Non-Interactive Mode** - Full automation support for CI/CD
- 📝 **Comprehensive Logging** - Detailed logs for troubleshooting

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [What's Included](#-whats-included)
- [Installation](#-installation)
- [Testing](#-testing)
- [Theme Management](#-theme-management)
- [Directory Structure](#-directory-structure)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [Documentation](#-documentation)
- [License](#-license)

## 🚀 Quick Start

### One-Line Install (From GitHub)

```bash
curl -fsSL https://raw.githubusercontent.com/rasmus105/dotfiles/main/install.sh | bash
```

### Local Install (For Development)

```bash
git clone https://github.com/rasmus105/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install/setup.sh
```

### Test Before Installing (Docker)

```bash
git clone https://github.com/rasmus105/dotfiles.git
cd dotfiles
./test/docker-test.sh --local
```

## 📦 What's Included

### System Configuration

- **Display Server**: Wayland (Hyprland)
- **Shell**: Zsh with Antidote plugin manager
- **Terminal**: Alacritty, Ghostty
- **Editor**: Neovim with custom configuration
- **Status Bar**: Waybar
- **Launcher**: Walker
- **Notifications**: Mako
- **File Manager**: Nautilus with custom theme

### Development Tools

- Git with custom configuration
- Neovim with plugins
- Visual Studio Code
- Lazygit for Git TUI
- Multiple terminal emulators

### Utilities

- **CLI Tools**: eza, bat, btop, fzf, ripgrep, zoxide, fd
- **Screenshot**: Hyprshot, grim, slurp, satty
- **Screen Recording**: Kooha
- **Color Picker**: Hyprpicker
- **System Monitor**: btop, fastfetch

### Themes (12 Color Schemes)

- Gruvbox (default)
- Catppuccin (Mocha & Latte)
- Tokyo Night
- Nord
- Rose Pine
- Kanagawa
- Everforest
- And more...

## 📥 Installation

### Prerequisites

- Arch Linux (or Arch-based distribution)
- Internet connection
- Sudo access

### Installation Methods

#### Method 1: Remote Installation (Recommended for New Users)

This method clones the repository to `~/.dotfiles` and runs the setup:

```bash
curl -fsSL https://raw.githubusercontent.com/rasmus105/dotfiles/main/install.sh | bash
```

The installer will:
1. Check if `~/.dotfiles` exists (creates backup if it does)
2. Clone the repository
3. Prompt to proceed with setup
4. Install packages and configure system

#### Method 2: Local Installation (Recommended for Developers)

If you already have the repository cloned:

```bash
cd ~/.dotfiles  # or wherever you cloned it
bash install/setup.sh
```

#### Method 3: Non-Interactive Installation (CI/CD)

For automated installations without prompts:

```bash
export USE_DEFAULT_OPTIONS=1
bash install.sh
```

### What Gets Installed

1. **Paru** - AUR helper for package management
2. **Packages** - All packages from `install/packages.txt` (~100 packages)
3. **Zsh Setup** - Antidote plugin manager and configuration
4. **Symlinks** - Configuration files linked via GNU Stow
5. **Theme** - Default Gruvbox theme configured

### Post-Installation

After installation:
- **Log out and back in** for shell changes to take effect
- Check installation logs at `install/log/install-TIMESTAMP.log`
- Start Hyprland session from display manager or with `Hyprland`

## 🧪 Testing

### Docker-Based Testing (Fast, Automated)

Perfect for CI/CD and quick validation:

```bash
# Test with local changes
./test/docker-test.sh --local

# Test by cloning from GitHub (simulates user experience)
./test/docker-test.sh

# Rebuild base image (after Arch updates)
./test/docker-test.sh --rebuild-base

# Keep container for inspection
./test/docker-test.sh --local --keep-container
```

**Benefits:**
- Fast iteration (~10 seconds for rebuild)
- Clean environment every time
- Cached base image with system packages
- CI-ready

### VM-Based Testing (Comprehensive, GUI)

For full system testing with graphical environment:

```bash
# Launch VM for manual testing
./test/vm/vm.sh

# Launch VM with auto-install
./test/vm/vm.sh --auto-install

# Start fresh (delete existing VM)
./test/vm/vm.sh --fresh
```

**VM Features:**
- Full Arch Linux installation
- QEMU with KVM acceleration
- Shared folder for dotfiles access
- Snapshot support for quick rollbacks
- 4GB RAM, 4 CPUs, 20GB disk

**VM Snapshot Management:**
```bash
cd test/vm

# Create snapshot after clean install
./vm-snapshot.sh create clean-install

# Restore to snapshot
./vm-snapshot.sh restore clean-install

# List snapshots
./vm-snapshot.sh list
```

## 🎨 Theme Management

### Available Themes

- **Gruvbox** (default) - Retro groove color scheme
- **Catppuccin Mocha** - Soothing pastel theme
- **Catppuccin Latte** - Light variant
- **Tokyo Night** - Clean, dark theme
- **Nord** - Arctic-inspired palette
- **Rose Pine** - Natural pine, subtle dawn
- **Kanagawa** - Dark theme inspired by Japanese paintings
- **Everforest** - Green comfortable theme
- **Flexoki Light** - Light theme with organic colors
- **Matte Black** - Pure dark theme
- **Osaka Jade** - Jade-inspired colors
- **Ristretto** - Coffee-inspired theme

### Switching Themes

```bash
# Interactive theme selector
system-set-theme

# Apply theme to all applications
update-hyprpaper-background
update-nvim-theme
update-browser-theme
update-vscode-theme
update-terminal-theme
```

### Theme Architecture

Themes are stored in `themes/` directory. Active theme is symlinked:
```
~/.config/theme -> ~/.dotfiles/themes/gruvbox
```

Each theme contains:
- `colors.conf` - Color definitions
- `hyprland.conf` - Hyprland-specific settings
- `btop.theme` - btop color scheme
- `background/` - Wallpapers

Applications read from `~/.config/theme/` for theming.

## 📁 Directory Structure

```
dotfiles/
├── bin/                    # User utilities and scripts
│   ├── system-set-theme           # Theme switcher
│   ├── update-*-theme             # Individual app theme updaters
│   └── create-tui-application     # TUI app creator
├── common/                 # Shared libraries
│   └── gum_utils.sh              # Terminal UI utilities
├── config/                 # Application configs (→ ~/.config/)
│   ├── hypr/                     # Hyprland configuration
│   ├── nvim/                     # Neovim configuration
│   ├── alacritty/                # Alacritty terminal
│   ├── waybar/                   # Waybar status bar
│   ├── mako/                     # Notification daemon
│   └── ...                       # Other app configs
├── home/                   # Home directory files (→ ~/)
│   ├── .zshrc                    # Zsh configuration
│   ├── .gitconfig                # Git configuration
│   └── .zsh_plugins.txt          # Zsh plugins list
├── install/                # Installation scripts
│   ├── setup.sh                  # Main setup script
│   ├── install_packages.sh       # Package installer
│   ├── stow.sh                   # Symlink manager
│   ├── setup_zsh.sh              # Zsh setup
│   └── packages.txt              # Package list
├── local/                  # .local directory files (→ ~/.local/)
├── system/                 # System-level configurations
├── themes/                 # Color schemes
│   ├── gruvbox/                  # Default theme
│   ├── catppuccin/               # Catppuccin Mocha
│   └── ...                       # Other themes
├── test/                   # Testing infrastructure
│   ├── Dockerfile                # Docker test environment
│   ├── docker-test.sh            # Docker test runner
│   └── vm/                       # VM testing scripts
├── install.sh              # Entry point installer
└── common.sh              # Common functions

```

## ⚙️ Configuration

### Customizing Package List

Edit `install/packages.txt`:
```bash
# Add your packages (one per line)
neovim
git
htop

# Comments and empty lines are ignored
```

### Modifying Configurations

All configurations are version-controlled:
```bash
# Edit configuration
vim ~/.config/hypr/hyprland.conf

# Changes are immediately reflected (symlinked to repo)
cd ~/.dotfiles
git status  # Shows your changes
```

### Adding New Configurations

1. Add files to appropriate directory:
   - `config/` for `~/.config/` files
   - `home/` for `~/` files
   - `local/` for `~/.local/` files

2. Re-run stow:
   ```bash
   cd ~/.dotfiles
   bash install/stow.sh
   ```

### Customizing Theme

1. Create new theme directory:
   ```bash
   mkdir themes/mytheme
   ```

2. Copy structure from existing theme:
   ```bash
   cp -r themes/gruvbox/* themes/mytheme/
   ```

3. Modify colors in `themes/mytheme/colors.conf`

4. Switch to your theme:
   ```bash
   system-set-theme
   ```

## 🔧 Troubleshooting

### Installation Issues

#### Package Installation Fails
```bash
# Check logs
cat install/log/install-*.log

# Try manual installation
paru -S package-name

# Update package database
paru -Sy
```

#### Symlink Conflicts
```bash
# Check what's conflicting
stow -n -v -t ~/.config config

# Remove conflicting files
rm ~/.config/conflicting-file

# Re-run stow
bash install/stow.sh
```

#### Git Clone Fails
```bash
# Check internet connection
ping github.com

# Try alternative repo URL
git clone git@github.com:rasmus105/dotfiles.git ~/.dotfiles
```

### Runtime Issues

#### Shell Changes Don't Apply
```bash
# Log out and back in, or
exec zsh
```

#### Theme Not Applied
```bash
# Relink theme
ln -sf ~/.dotfiles/themes/gruvbox ~/.config/theme

# Update applications
update-hyprpaper-background
update-nvim-theme
```

#### Hyprland Won't Start
```bash
# Check Hyprland logs
cat /tmp/hypr/*/hyprland.log

# Validate configuration
hyprctl reload

# Start Hyprland with verbose logging
Hyprland -c ~/.config/hypr/hyprland.conf
```

### Getting Help

1. Check logs in `install/log/`
2. Run installation with verbose mode
3. Test in Docker first: `./test/docker-test.sh --local`
4. Open an issue with log files

## 🤝 Contributing

Contributions are welcome! Please:

1. **Test your changes** with Docker:
   ```bash
   ./test/docker-test.sh --local
   ```

2. **Run ShellCheck**:
   ```bash
   shellcheck install.sh install/*.sh test/*.sh
   ```

3. **Ensure non-interactive mode works**:
   ```bash
   USE_DEFAULT_OPTIONS=1 bash install/setup.sh
   ```

4. **Follow code style**:
   - Use 4 spaces for indentation
   - Quote all variables
   - Check all `cd` operations
   - Add comments for complex logic

5. **Update documentation** for architectural changes

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📚 Documentation

- [Architecture Documentation](ARCHITECTURE.md) - System design and components
- [Design Review](DESIGN_REVIEW.md) - Comprehensive analysis and recommendations
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute

### Key Concepts

- **GNU Stow**: Symlink farm manager for dotfile organization
- **Gum**: Terminal UI toolkit for beautiful interfaces
- **Paru**: AUR helper for Arch package management
- **Antidote**: Fast Zsh plugin manager

## 🎯 Roadmap

- [ ] CI/CD with GitHub Actions
- [ ] Multi-distribution support (Ubuntu, Fedora)
- [ ] Modular installation (minimal, full, custom)
- [ ] Update mechanism for pulling latest dotfiles
- [ ] Backup system for existing configurations
- [ ] Web-based theme preview
- [ ] Plugin system for optional components

## 🙏 Acknowledgments

- [Hyprland](https://hyprland.org/) - Amazing Wayland compositor
- [GNU Stow](https://www.gnu.org/software/stow/) - Symlink farm manager
- [Gum](https://github.com/charmbracelet/gum) - Beautiful terminal UI
- [Arch Linux](https://archlinux.org/) - The best Linux distribution
- All the amazing open-source projects included in this setup

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/rasmus105/dotfiles/issues)
- **Discussions**: [GitHub Discussions](https://github.com/rasmus105/dotfiles/discussions)

---

<div align="center">

**[⬆ Back to Top](#dotfiles-with-automatic-installation-and-testing)**

Made with ❤️ for the Arch Linux and Hyprland community

</div>
