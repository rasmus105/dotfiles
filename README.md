# Dotfiles

Personal configuration files and bash scripts for Arch Linux + Hyprland.

## Installation

A fully automated setup is intended at some point, but for now, the best way to
install is by cloning the repository, and running the `local/bin/run-setup`
script.

For the future, the main installation method will be like this:

```bash
curl -fsSL https://raw.githubusercontent.com/rasmus105/.dotfiles/main/install.sh | bash
```
> [!WARNING] 
> This installation method has not been tested for a while, and has never really worked.

## Directory Structure

| Directory  | Target          | Method               |
|------------|-----------------|----------------------|
| `config/`  | `~/.config/`    | GNU Stow (symlink)   |
| `home/`    | `~/`            | GNU Stow (symlink)   |
| `local/`   | `~/.local/`     | GNU Stow (symlink)   |
| `system/`  | `/`             | rsync (copied)       |


## Architecture

All bash scripts attempt to follow a 3-layer design:
- **Raw Scripts:** Simple, primitive bash scripts, with minimal output
  (stdout/stderr) by default. Should use the wrapper function `q` for most,
  that allow forwarding all stdout/stderr output by setting `VERBOSE=1`. These
  have no complicated UI; ANSI codes should not be used here.
- **UI:** Simple TUI with 3 parts - history of commands and the currently run
  command, scrollable muted window with verbose command output, and progress
  bar + keybindings.
  ```
  ┌─────────────────────────────────────────┐
  │ ✓ Step 1: Install dependencies          │  history
  │ ✓ Step 2: Deploy configs                │
  │ ● Step 3: Configure shell...            │  current
  ├─────────────────────────────────────────┤
  │ :: Running antidote bundle...           │  verbose output
  │    Cloning zsh-users/zsh-autosugg...    │  (scrollable, muted)
  ├─────────────────────────────────────────┤
  │ [████████░░░░░░░░] 3/10  [r]etry [s]kip │  progress + keys
  └─────────────────────────────────────────┘
  ```
- **Orchestrators:** *Runner* scripts to orchestrate running raw scripts in
  specific orderings, using UI layer to display output in a readable,
  easy-to-follow manner.

I've experimented with various architectures. Mixing UI with logic has always
resulted in scripts that break easily, are hard(er) to test, and generally less
reuseability.

## Scripts (local/bin/ symlinked to ~/.local/bin/)

Most base scripts support autocompletion for bash, zsh, and fish (though I primarily use zsh, so bash and fish may be partly broken).


| Script           | Purpose                                                                                       |
|------------------|-----------------------------------------------------------------------------------------------|
| `run-setup`      | Interactive initial setup (packages, stow, etc.)                                              |
| `run-update`     | Interactive system update (git, pacman, flatpak)                                              |
| `dotfiles`       | Git pull + stow, full system update, fzf package install/remove                               |
| `system-theme`   | Set/list themes, cycle wallpapers, change fonts, toggle nightlight                            |
| `system-refresh` | Restart apps (mako, walker, waybar) and reload configs (hyprctl, terminals)                   |
| `system-setup`   | Install gum/paru/packages, stow, copy system configs, configure shell/systemd/mimetypes       |
| `theme-generator`| Parse `theme.toml` and output configs for 14 apps (terminals, waybar, hyprland, etc.)         |
| `run-notify`     | Wrap any command with desktop notification on success/failure, log errors to `/tmp/dotfiles/` |

