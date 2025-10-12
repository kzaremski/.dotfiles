# Dotfiles

Personal Linux configuration files for my i3wm-based desktop environment.

## Overview

This repository contains my dotfiles and configuration for a keyboard-driven Linux setup centered around i3 window manager. Originally configured for a ThinkPad running Arch Linux.

## Components

### Window Manager & Desktop
- **i3wm** - Tiling window manager with custom keybindings (Linux)
- **Aerospace** - i3-style tiling window manager (macOS)
- **i3status** - Status bar
- **picom** - Compositor for transparency effects
- **dunst** - Notification daemon
- **feh** - Wallpaper manager

### Terminal & Shell
- **URxvt** - Terminal emulator with transparency
- **Zsh** - Shell with Oh-My-Zsh (junkfood theme)
- **Vim** - Text editor with NERDTree

### Applications & Tools
- **dmenu** - Application launcher (Linux) / Alfred/Spotlight (macOS)
- **PCManFM** - File manager (Linux) / Finder (macOS)
- **htop/bpytop** - System monitors
- **Firefox** - Web browser
- **WezTerm** - Modern GPU-accelerated terminal
- **Skim** - PDF viewer with vim-like keybindings (macOS)

### Utilities
- **maim** - Screenshot tool
- **playerctl** - Media key support
- **brightnessctl** - Brightness control
- **NetworkManager** - Network management

## Key Features

### i3 Keybindings

**Applications**
- `Mod+Enter` - Terminal (urxvt/WezTerm)
- `Mod+Shift+Enter` - VSCode
- `Mod+d` - dmenu launcher (Spotlight/Alfred on macOS)
- `Mod+F1` - File manager (PCManFM/Finder)
- `Mod+F2` - Firefox (Safari on macOS by default)
- `Mod+F3` - PDF viewer (Skim on macOS)
- `Mod+F7` - Screen layout selector
- `Mod+F12` - htop

**Window Management**
- `Mod+Shift+q` - Kill window
- `Mod+Arrow Keys` - Focus windows
- `Mod+Shift+Arrow Keys` - Move windows
- `Mod+f` - Fullscreen
- `Mod+r` - Resize mode
- `Mod+1-10` - Switch workspaces

**System**
- `Mod+Shift+e` - System menu (lock/suspend/exit/reboot/shutdown)
- `Print` - Screenshot
- `Shift+Print` - Screenshot selection
- Media keys for volume/brightness/playback

### Custom Scripts

**System Setup Scripts:**

**setup-arch.sh**
- Automated Arch Linux system setup
- Installs all packages, fonts, and tools
- Sets up yay (AUR helper), Oh-My-Zsh, and Vim-Plug
- Usage: `./scripts/setup-arch.sh`

**setup-macos.sh**
- Automated macOS system setup
- Installs Homebrew and all required packages
- Applies macOS-specific tweaks
- Usage: `./scripts/setup-macos.sh`

**Application Scripts:**

**set-vim-default.sh**
- Creates WezTermVim.app wrapper and sets it as default for text files
- Files double-clicked in Finder open directly in vim via WezTerm
- Automatically runs `create-wezterm-vim-app.sh` if needed
- Usage: `./scripts/set-vim-default.sh` (requires: `brew install duti`)

**create-wezterm-vim-app.sh**
- Creates a macOS .app bundle that launches `wezterm start vim <file>`
- Installs to `/Applications/WezTermVim.app`
- Called automatically by `set-vim-default.sh`

**appimage-launcher.sh**
- dmenu-based launcher for AppImage files in `~/Applications/`

**thinkpad-hotspot.py**
- Turn your ThinkPad into a WiFi hotspot
- Manages hostapd, dnsmasq, and iptables configuration
- Relies on second wifi card being mounted internally if you want to do a wifi-to-wifi bridge, can even be done with a USB Wi-Fi card on some X220 models.
- Usage: `sudo thinkpad-hotspot.py --enable` or `--disable`
- *Note: Very unreliable, use at your own risk.*

**screen-layout-selector.sh**
- dmenu interface for selecting monitor layouts

**install.sh**
- Installs custom scripts to `/usr/bin/` for system-wide access
- Makes scripts available in PATH

### Display Configuration

Multi-monitor setups defined in `screenlayout/`:
- `laptop.sh` - Laptop display only
- `hdmi_1080_only.sh` - External HDMI only
- `hdmi_1080_right.sh` - HDMI as secondary display
- `main.sh` - Primary configuration

## Installation

### Prerequisites

**Quick Setup (Recommended):**

We provide automated setup scripts for fresh installations:

```bash
# For Arch Linux
./scripts/setup-arch.sh

# For macOS
./scripts/setup-macos.sh
```

These scripts install all required packages, fonts, and tools needed for the dotfiles.

**Manual Installation (Arch Linux example):**

```bash
# Core window manager
sudo pacman -S i3-wm i3status dmenu

# Terminal and shell
sudo pacman -S rxvt-unicode zsh tmux

# Utilities
sudo pacman -S feh picom dunst maim xclip brightnessctl playerctl
sudo pacman -S network-manager-applet blueman pasystray
sudo pacman -S ripgrep fd bat exa fzf

# Applications
sudo pacman -S firefox pcmanfm htop vim

# Fonts
sudo pacman -S ttf-cascadia-code-nerd
```

### Setup

#### 1. Clone this repository

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

#### 2. Install dependencies (optional but recommended)

The dotfiles manager requires PyYAML and optionally uses Rich for a better interface:

```bash
python3 dotfiles.py --install-deps
```

This creates a local `.venv` and installs dependencies there. If you decline, the script will prompt you when you run it.

#### 3. Run the interactive dotfiles manager

```bash
python3 dotfiles.py
```

**What it does:**
- Shows all available dotfiles from `manifest.yaml` with current status
- Lets you select which configs to symlink (or choose 'all')
- Automatically backs up existing files to `~/.dotfiles-backup/` with timestamps
- Creates necessary directories (`mkdir -p`)
- Creates symlinks from repo to your home directory
- Supports "yes to all" for batch operations (`y/n/a`)

**Usage examples:**
```bash
# Interactive mode (default)
python3 dotfiles.py

# Install dependencies first
python3 dotfiles.py --install-deps

# Get help
python3 dotfiles.py --help
```

#### 4. Platform-specific setup

**For Linux users:**

```bash
# Install Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Vim plugins
vim +PlugInstall +qall

# Load Xresources
xrdb ~/.Xresources

# Restart i3
# Mod+Shift+r or log out and back in
```

**For macOS users:**

See [docs/MACOS_CONFIG.md](docs/MACOS_CONFIG.md) for complete macOS-specific setup including:
- Homebrew and essential tools
- Aerospace window manager setup
- Font installation
- Fixing macOS keyboard shortcuts
- Differences from Linux setup

## Customization

### Changing Mod Key
Edit `.config/i3/config`:
```
set $mod Mod4  # Windows key
# or
set $mod Mod1  # Alt key
```

### Wallpaper
Place your wallpaper at `~/Pictures/wallpaper.jpg` or edit the path in i3 config.

### Colors & Theme
- Terminal colors: `.Xresources`
- i3 appearance: `.config/i3/config` (gaps, borders, colors)

### Font
Currently using CaskaydiaCove Nerd Font. Change in:
- `.config/i3/config`
- `.Xresources`

## Hardware-Specific Notes

### ThinkPad WiFi Hotspot
The `thinkpad-hotspot.py` script is configured for specific network interfaces:
- `wlp0s26u1u4` - External ASUS WiFi adapter (AP)
- `wlp3s0` - Internal WiFi (WAN)

Edit the script to match your interface names (find with `ip link`).

### Multi-Monitor Setup
Screen layouts assume specific monitor configurations. Run `xrandr` to see your outputs and adjust scripts in `screenlayout/` accordingly.

## File Structure

```
.
├── dotfiles.py            # Interactive dotfiles manager with TUI
├── manifest.yaml          # Configuration file defining which dotfiles to manage
├── docs/
│   └── MACOS_CONFIG.md    # macOS-specific setup guide
├── .bashrc                # Bash configuration
├── .zshrc                 # Zsh configuration
├── .vimrc                 # Vim configuration (with custom F1 manual)
├── .tmux.conf             # tmux configuration
├── .Xresources            # X resources (URxvt colors/fonts)
├── .profile               # Shell profile
├── .wezterm.lua           # WezTerm config
├── .aerospace.toml        # Aerospace window manager config (macOS)
├── .config/
│   ├── i3/                # i3 window manager config
│   ├── i3status/          # Status bar config
│   ├── picom/             # Compositor config
│   ├── dunst/             # Notification daemon config
│   ├── alacritty/         # Alacritty terminal config
│   ├── htop/              # htop config
│   ├── bpytop/            # bpytop config
│   ├── pcmanfm/           # File manager config
│   └── conky/             # Conky config
├── scripts/
│   ├── setup-arch.sh            # Arch Linux automated setup
│   ├── setup-macos.sh           # macOS automated setup
│   ├── set-vim-default.sh       # Set vim as default editor (macOS)
│   ├── create-wezterm-vim-app.sh # Create WezTermVim.app bundle (macOS)
│   ├── appimage-launcher.sh
│   ├── screen-layout-selector.sh
│   ├── thinkpad-hotspot.py
│   └── install.sh
└── screenlayout/          # Monitor layout scripts
```

## Dotfiles Manager

The `dotfiles.py` script provides an interactive TUI for managing your dotfiles:

**Features:**
- Interactive selection of which dotfiles to link
- Configuration via `manifest.yaml` - no code changes needed
- Automatic detection and status checking
- Timestamped backups of existing files
- "Yes to all" option (`y/n/a`) for batch operations
- Continuous prompting - validates input and keeps asking until valid
- Automatic directory creation (`mkdir -p`)
- Local virtual environment (`.venv`) for isolated dependencies
- Rich library support for enhanced TUI (optional)
- Graceful fallback to basic mode without dependencies

**Usage:**
```bash
python3 dotfiles.py              # Interactive mode
python3 dotfiles.py --install-deps  # Create .venv and install dependencies
python3 dotfiles.py --help          # Show help
```

**Dependency Management:**
- The script automatically creates a `.venv` directory in the repo
- Dependencies (PyYAML and Rich) are installed in this isolated environment
- Falls back to `pip install --user` if venv creation fails
- The `.venv` directory is gitignored automatically

**Status indicators:**
- `✓ Not linked` - Ready to link
- `→ Already linked` - Currently linked correctly
- `⚠ File exists` - File exists but isn't a symlink
- `→ Links elsewhere` - Symlink points to different location

### Manifest Configuration

The `manifest.yaml` file defines which dotfiles to manage. To add or remove dotfiles, simply edit this file:

```yaml
dotfiles:
  - source: .bashrc           # Path relative to dotfiles repo
    dest: .bashrc             # Path relative to home directory
    description: Bash configuration

  - source: .config/i3        # Can be files or directories
    dest: .config/i3
    description: i3 window manager config
```

**Adding a new dotfile:**
1. Edit `manifest.yaml`
2. Add a new entry with `source`, `dest`, and `description`
3. Run `python3 dotfiles.py` to link it

**Format:**
- `source`: Path relative to the dotfiles repository
- `dest`: Path relative to your home directory
- `description`: Human-readable description shown in the TUI

No need to modify the Python script - just update the manifest!

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Notes

- Originally configured on Arch Linux (July 2024)
- Optimized for ThinkPad hardware but adaptable to other systems
- **macOS users:** See [docs/MACOS_CONFIG.md](docs/MACOS_CONFIG.md) for macOS-specific setup and configuration
