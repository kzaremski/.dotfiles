<p align="center">
  <img src="banner.png" alt="Omarchski" width="100%">
</p>

# Dotfiles

Personal configuration files for a keyboard-driven Linux desktop.

## Overview

This repository contains my dotfiles for a keyboard-driven setup, built up over
two eras:

- **i3wm on Arch + X11** — the original ThinkPad setup, and still what most of
  the configs in this repo describe.
- **Hyprland on Omarchy + Wayland** — where I'm moving day-to-day.

Most of the cross-platform pieces (shell, Vim, tmux, Helix, ranger, git, GPG)
carry over unchanged. The X11-specific parts — i3, i3status, picom, dunst,
`.Xresources`, `screenlayout` — are kept for the machines still running them.

macOS is also covered via Aerospace, an i3-style tiling WM.

## Rebuilding this machine

Omarchy ISO plus this repo. Order matters.

```bash
# 1. Clone
git clone git@github.com:kzaremski/.dotfiles.git ~/.dotfiles && cd ~/.dotfiles

# 2. Packages (explicit installs only; pacman pulls deps back itself)
./.local/bin/dotfiles-packages --install

# 3. User config -- symlinks into $HOME
python3 dotfiles.py --label omarchy --yes

# 4. System files -- copied as root, never symlinked (see "System files" below)
python3 dotfiles.py --import-system

# 5. Services
systemctl --user daemon-reload
```

The `default.target.wants` enable-symlinks are tracked, so user services come
back already enabled.

### Manual steps that cannot be automated

| | |
|---|---|
| Fingerprint | `fprintd-enroll -f right-index-finger` (biometric, must be re-enrolled) |
| Tailscale | `tailscale up --ssh` (node must re-authenticate) |
| DaVinci Resolve | Install the Studio AUR package with its zip, activate, then `pkexec resolve-perms "$USER"` |
| ollama models | `ollama pull qwen3:14b` (~9 GB, deliberately not in git) |
| SSH / GPG keys | Restore from your own secure backup. Never in this repo. |

See `packages/README.md` for the AUR packages that need a human, and
`.config/comrade/contexts/` for the accumulated notes on why things are the way
they are.

### System files

Config outside `$HOME` lives in `root/` and is handled by plain copy, never
symlinked -- `/etc/pam.d` files must stay root-owned, and a symlink into this
user-writable repo would let an unprivileged user rewrite their own auth rules.

```bash
python3 dotfiles.py --import-system    # repo  -> system (needs root)
python3 dotfiles.py --export-system    # system -> repo  (plain read)
```

Import batches everything into a single elevated call, keeps a `.dotfiles-orig`
backup the first time it touches a file, and prefers `pkexec` in a graphical
session so the polkit agent can take a fingerprint. `--unlink` never touches
system entries.

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
- `Mod+Enter` - Terminal (kitty)
- `Mod+Shift+Enter` - VSCode
- `Mod+d` - dmenu launcher (Spotlight/Alfred on macOS)
- `Mod+Shift+d` - Docs/reference selector
- `Mod+Ctrl+d` - Script selector
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

**docs-selector.sh**
- dmenu-based quick reference documentation viewer
- Searches `.md` and `.txt` files in `~/.dotfiles/docs/`
- Opens selected doc in kitty with syntax highlighting (bat) or less
- Usage: `Mod+Shift+d` or `./scripts/docs-selector.sh`

**script-selector.sh**
- dmenu-based launcher for scripts in `~/.dotfiles/scripts/`
- Shows script name and description from header comment
- Usage: `Mod+Ctrl+d` or `./scripts/script-selector.sh`

**tailscale-devices.sh**
- Display Tailscale devices with names, IPs, and full MagicDNS names
- Shows online/offline status and device count
- Usage: `./scripts/tailscale-devices.sh`

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

> **Note:** the section below is from the X230 / i3 / X11 era and is kept for the
> `x230` and `legacy` labels. For rebuilding the current Omarchy machine, use
> **Rebuilding this machine** above.


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

**Omarchy / Wayland extras (current setup):**

```bash
# Qt5 apps need this or they silently fall back to XWayland and render at 1x
sudo pacman -S qt5-wayland

# OpenCL - required by DaVinci Resolve, also used by Affinity under Wine
sudo pacman -S rocm-opencl-runtime

# Graphics
sudo pacman -S inkscape gimp krita

# ASCII banners in Omarchy's logo font (see .local/bin/omarchy-ascii)
sudo pacman -S figlet          # plus figlet-fonts from the AUR
```

**Reading Mac disks (APFS):**

```bash
# AUR - github.com/sgan81/apfs-fuse
git clone https://aur.archlinux.org/apfs-fuse-git.git
cd apfs-fuse-git && makepkg -si
```

Provides `apfs-fuse`, `apfs-dump`, `apfs-dump-quick` and `apfsutil`. Mount
read-only with:

```bash
apfs-fuse /dev/sdXN /mnt/point      # -v N to pick a volume on a container
fusermount3 -u /mnt/point           # unmount
```

Two caveats worth knowing: it is **read-only**, and it cannot open
FileVault-encrypted volumes without the password (`-o passwd=...`). For write
support there is `linux-apfs-rw-dkms` in `extra`, but it is explicitly
experimental - don't point it at a disk you care about.

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

- Label filtering, so one repo serves several machines
- `--dry-run` preview and `--unlink` to reverse
- `--yes` for scripted, non-interactive provisioning

**Usage:**
```bash
python3 dotfiles.py                       # Interactive mode
python3 dotfiles.py --labels              # List labels and entry counts
python3 dotfiles.py --link --label omarchy   # Only this machine's config
python3 dotfiles.py --link --label macos -y  # Non-interactive
python3 dotfiles.py --link --exclude-label legacy
python3 dotfiles.py --link --dry-run      # Preview, change nothing
python3 dotfiles.py --unlink              # Remove symlinks into this repo
python3 dotfiles.py --install-deps        # Create .venv, install deps
python3 dotfiles.py --help
```

**Labels:**

Every manifest entry carries labels so a single repo can serve the Omarchy
laptop, the old X11 ThinkPad, and macOS without linking configs for software
that isn't installed.

| Label | Meaning |
| --- | --- |
| `omarchy` `wayland` `current` | The Hyprland/Wayland setup in use today |
| `x11` `x230` `legacy` | The old i3-on-ThinkPad stack |
| `macos` | Works on macOS (Aerospace, Rectangle, cross-platform tools) |
| `common` | Platform-agnostic |
| `wm` `shell` `terminal` `editor` `tools` `fonts` `dev` `apps` | Category |

`--label` takes a union - `--label x11,x230` matches entries with *either*.
`--exclude-label` is applied afterwards, so exclusions always win. An entry
with no labels never matches a `--label` filter.

Provisioning a new Omarchy machine:
```bash
python3 dotfiles.py --link --label omarchy,common --dry-run   # check first
python3 dotfiles.py --link --label omarchy,common -y
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
    labels: [wm, x11, x230, legacy]
```

**Adding a new dotfile:**
1. Edit `manifest.yaml`
2. Add an entry with `source`, `dest`, `description`, and `labels`
3. Run `python3 dotfiles.py --link --label <one of them> --dry-run` to check
4. Drop `--dry-run` to apply

**Format:**
- `source`: Path relative to the dotfiles repository
- `dest`: Path relative to your home directory
- `description`: Human-readable description shown in the TUI
- `labels`: List of tags used by `--label` / `--exclude-label` (optional,
  but an unlabelled entry can only be linked by an unfiltered run)

Prefer file-level entries over directory-level ones where a directory also
holds things that shouldn't be tracked - `~/.local/bin` holds installed
tooling, `~/.local/share/applications` is full of generated launchers, and
`~/.claude` holds history and session data.

No need to modify the Python script - just update the manifest!

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Notes

- Originally configured on Arch Linux (July 2024)
- Optimized for ThinkPad hardware but adaptable to other systems
- Migrating to Omarchy (Arch + Hyprland + Wayland); X11 configs retained for
  existing machines
- Banner is the Tokyo Night `oma-cityscape` wallpaper with the title set in
  Delta Corps Priest 1, the figlet font Omarchy's own logo uses
- **macOS users:** See [docs/MACOS_CONFIG.md](docs/MACOS_CONFIG.md) for macOS-specific setup and configuration
