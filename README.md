# About

```bash
./setup.sh
```

Configuration files are split:
```
common/ # configuration shared by macOS and Ubuntu
macos/  # macOS-specific configuration
ubuntu/ # Ubuntu-specific configuration
```

Each directory is a GNU Stow package whose contents mirror `$HOME`. For example:

```
common/.zshrc
common/.config/nvim/init.lua
macos/.zshrc
macos/.config/ghostty/config
```

`setup.sh` stows `common/` first, then stows the platform package. Platform
files override files at the same path in `common/`.

On Linux, the platform name comes from `ID` in `/etc/os-release`. To support a
new distribution, add a matching Stow package and setup script, such as
`arch/` and `bin/arch-setup.sh`.
