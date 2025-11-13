# Dotfiles
For storing all configuration files


## How to
```
sudo pacman -S stow
stow .
```

## Testing

Test the installation in a clean Docker environment:

```bash
# Quick test (uses cached base image)
./test/docker-test.sh

# Full rebuild including Arch packages
./test/docker-test.sh --rebuild-base

# Keep container running for debugging
KEEP_CONTAINER=true ./test/docker-test.sh
```

The test uses a multi-stage Docker build for fast iteration:
- Base image is cached (Arch Linux + packages)
- Only dotfiles are copied on each test run
- Large files in `test/` directory are excluded via `.dockerignore`


# TODO

- Ensure disk is encrypted.
- Clipboard manager??

# TODO

- [x] pacman configuration: colors, (maybe other options?)
- [ ] use omarchy themes and backgrounds?
- [ ] add .desktop applications (bluetui, wiremix, pamala)
- [ ] default applications
- [ ] switch to networkmanager and add vpn support
- [ ] CLEAN README.md history from git and write new (think it contains sensitive information)
- [ ] Clean git configuration history (contains sensitive information)

- [ ] Ubuntu-like menu in top bar:
    - [ ] Select WiFi
    - [ ] Select bluetooth
    - [ ] Pause/play audio
    - [ ] See system info: (RAM usage, CPU usage, disk usage), battery, screen brightness, sound level, selected sound output?
    - [ ] Selected Hyprland desktop (possibly just a single number indicating current?
    - [ ] Time warrior integration
    - [ ] High performance
    - [ ] Toggleable (hence quick start-up time)

- [ ] Easier installation?
    - [ ] Script to stow basics?

- [ ] Default apps: 
    - Text editor: Neovim
    - Zathura: Pdf viewer
    - Terminal: Ghostty

- [ ] Menus
    - [ ] Basic calculator and hex converter
    - [ ] Ask AI in tmp chat.

- [ ] Think about keybindings (does everything make sense?)
    - Ctrl + g in neovim doesn't feel quite right?

## Top bar

Non-generic
- Bar
- Background
- Ordering of modules


Generics:
- Modules
- Popups

**On Click Menus:**
    - Trigger UI upon clicking module.


**Modules**:

UI: 
    - Number such as FONT
    - Icon/symbol 
    - Image (music viewer)
    - Graph
    - Volume bar
On Click: ?UIElement

Examples:
- Hyprland workspaces
- Bluetooth
- WiFi
- CPU usage
- RAM usage
- Battery
- Disk usage

Neovim theme modifications:


- Add neovim persistance

- Timer (visual, maybe in top bar?
- [x] Use white for hyprland

- [x] Fix zsh: Root user can't use alias'? (Maybe use functions instead of alias)

- [ ] Menu for colors (hex, rgb,...)

- [ ] Neovim: colors displayed in editor (new nigthly feature??)
- [x] Neovim: noice.nvim or notification thing 
- [x] Use makoctl notification manager instead of dunst
    - [x] keybind for dismissing notification

- [ ] Nightlight
- [x] Colorscheme (neovim, ghostty, hyprland)
    - Background: #292522
    - Red: #FB4934

- [ ] Figure out better default: file manager, 
- [x] Hyprexpo


- [ ] Write README.md for setup, and create automatic installation scripts.

