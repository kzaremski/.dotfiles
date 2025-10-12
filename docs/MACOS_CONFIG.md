# macOS Configuration Guide

This document covers macOS-specific configuration and tweaks needed for the dotfiles setup.

## Window Management with Aerospace

### Install Aerospace

```bash
brew install --cask nikitabobko/tap/aerospace
```

### Enable Click-and-Drag Window Moving

Aerospace (and other tiling window managers) benefit from being able to click and drag windows anywhere, not just the title bar:

```bash
defaults write -g NSWindowShouldDragOnGesture -bool true
```

After running this, **log out and log back in** for the change to take effect.

Now you can hold `Ctrl+Cmd` and click-and-drag anywhere on a window to move it.

### Disable Conflicting macOS Keyboard Shortcuts

Aerospace (and i3-style workflows) use Control+Arrow keys for navigation. You need to disable macOS system shortcuts that conflict:

**System Settings → Keyboard → Keyboard Shortcuts → Mission Control:**

Disable these shortcuts:
- ✗ **Mission Control:** `Control + Up Arrow` (uncheck)
- ✗ **Application Windows:** `Control + Down Arrow` (uncheck)
- ✗ **Move left a space:** `Control + Left Arrow` (uncheck)
- ✗ **Move right a space:** `Control + Right Arrow` (uncheck)

### Aerospace Configuration

The dotfiles repository includes a complete `.aerospace.toml` configuration that will be symlinked when you run `python3 dotfiles.py`.

**Quick Start:**
1. Make sure Aerospace is installed: `brew install --cask nikitabobko/tap/aerospace`
2. Run the dotfiles manager: `python3 dotfiles.py`
3. Select `.aerospace.toml` to symlink it to your home directory
4. Launch Aerospace or restart it to load the config

**Key Features in the Config:**
- i3-style window management adapted for macOS
- Uses `Cmd` key instead of `Super` (since macOS doesn't have Super)
- 8px gaps between windows
- Mouse follows focus automatically

**Keybindings (i3-style):**

**Focus Windows:**
- `Cmd + Arrow Keys` or `Cmd + h/j/k/l` - Focus window in direction

**Move Windows:**
- `Cmd + Shift + Arrow Keys` or `Cmd + Shift + h/j/k/l` - Move window in direction

**Workspaces:**
- `Cmd + 1-9,0` - Switch to workspace
- `Cmd + Shift + 1-9,0` - Move window to workspace

**Layout:**
- `Cmd + F` - Fullscreen
- `Cmd + Shift + Space` - Toggle floating/tiling
- `Cmd + S` - Split vertically (stack)
- `Cmd + E` - Split horizontally

**Resize Mode:**
- `Cmd + R` - Enter resize mode
- `Arrow Keys` or `h/j/k/l` - Resize window
- `Enter` or `Esc` - Exit resize mode

**Utilities:**
- `Cmd + Shift + R` - Reload Aerospace config
- `Cmd + Shift + Q` - Close window

**Quick Launch Apps:**
- `Cmd + Ctrl + Enter` - WezTerm (note: uses 'enter' not 'return')
- `Cmd + Ctrl + F` - Firefox
- `Cmd + Ctrl + C` - VS Code
- `Cmd + Ctrl + M` - Finder

**Auto-Workspace Assignment:**
The config automatically moves certain apps to specific workspaces:
- Firefox/Safari → Workspace 2
- VS Code → Workspace 3
- System Preferences and Finder dialogs float by default

**Customization:**
Edit `~/.aerospace.toml` to customize:
- Change keybindings (remember: use `cmd` not `super`)
- Adjust gap sizes
- Add more app-specific rules
- Change workspace assignments

## Terminal Configuration

### WezTerm Setup

WezTerm is installed by the setup script and configured in `.wezterm.lua`.

**Features in the config:**
- macOS "Pro" color scheme with black background
- 85% opacity with 20px blur (beautiful transparency)
- GPU-accelerated rendering
- Nerd Font support
- Native macOS decorations
- Built-in split panes (Cmd+D for horizontal, Cmd+Shift+D for vertical)
- Right-click to paste

**Keybindings:**
- `Cmd+D` - Split horizontally
- `Cmd+Shift+D` - Split vertically
- `Cmd+Alt+Arrows` - Navigate between panes
- `Cmd+W` - Close pane
- `Cmd+Ctrl+Enter` - Toggle fullscreen

### Setting WezTerm as Default Terminal

**System Settings Method:**
1. Open System Settings → General → Default web browser dropdown (below it)
2. Look for "Default Terminal" or similar setting
3. Select WezTerm

**Alternative - For Terminal.app Replacement:**
If macOS doesn't show a terminal selector:
1. Applications that launch terminal will use WezTerm if you set it in System Settings
2. Use Spotlight (`Cmd + Space`) and type "WezTerm" instead of "Terminal"
3. Add WezTerm to Dock for quick access

### Making Vim the Default Text Editor

**Automated Method (Recommended):**

The dotfiles repository includes scripts to automatically set vim as the default editor for text files.

**Quick Setup:**
```bash
# Install duti (file association manager)
brew install duti

# Run the setup script (automatically creates WezTermVim.app wrapper)
cd ~/.dotfiles
./scripts/set-vim-default.sh
```

**What This Does:**
1. Creates a `WezTermVim.app` bundle in `/Applications/`
2. This app automatically runs `wezterm start vim <filename>`
3. Sets this app as the default for 25+ text file types
4. Files double-clicked in Finder will now open directly in vim!

**Supported File Types:**
`.txt`, `.md`, `.py`, `.js`, `.json`, `.yaml`, `.sh`, `.bash`, `.zsh`, `.toml`, `.conf`, `.log`, `.xml`, `.html`, `.css`, `.rs`, `.go`, `.c`, `.cpp`, `.h`, `.lua`, `.vim`, and more

**Method 2: Right-Click → Get Info**

For individual file types:
1. Right-click a `.txt` file (or any text file)
2. Select "Get Info"
3. Under "Open with:", select WezTerm
4. Click "Change All..." to apply to all files of this type

**Method 3: Environment Variable**

Set `EDITOR` and `VISUAL` environment variables (already in `.zshrc`):
```bash
export EDITOR=vim
export VISUAL=vim
```

This makes vim the default for:
- Git commit messages
- Command-line tools that open editors
- `crontab -e`, `visudo`, etc.

**Alternative Keyboard-Driven Workflow:**

While double-clicking files now works, a keyboard-driven workflow is often more efficient:
1. Use Aerospace (`Cmd + 1-9`) to switch to your terminal workspace
2. Use `fzf` fuzzy finder (`Ctrl+P` in vim) to open files quickly
3. Use vim-vinegar (press `-` in vim) to browse directories
4. Use `vim filename` from the terminal for precise control

**To Undo File Associations:**
1. Right-click a text file → Get Info
2. Under "Open with:", select TextEdit (or your preferred app)
3. Click "Change All..." to apply to all files of this type
4. Optionally, delete `/Applications/WezTermVim.app` if you no longer need it

### Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Essential Tools

```bash
# Terminal multiplexer
brew install tmux

# Fuzzy finder (required for vim fzf plugin)
brew install fzf ripgrep

# Modern Unix tools
brew install bat exa fd

# Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Font Installation

Install a Nerd Font for proper terminal icons:

```bash
brew tap homebrew/cask-fonts
brew install --cask font-caskaydia-cove-nerd-font
```

Then set your terminal to use "CaskaydiaCove Nerd Font".

## Dotfiles Installation

From this repository root:

```bash
# Install Python dependencies
python3 dotfiles.py --install-deps

# Run interactive dotfiles manager
python3 dotfiles.py

# Select which configs to symlink
# Choose 'all' or select specific numbers
```

## macOS-Specific Notes

### Differences from Linux

1. **No i3wm** - Use Aerospace or yabai instead
2. **Package manager** - Use Homebrew instead of apt/pacman
3. **Path differences** - Uses `/Users/` instead of `/home/`
4. **Clipboard** - `pbcopy` and `pbpaste` instead of `xclip`

### Configs That Work on macOS

These dotfiles work perfectly on macOS:
- `.zshrc` (updated for macOS compatibility)
- `.vimrc` (all plugins work)
- `.tmux.conf` (full mouse support)
- `.bashrc`
- `.profile`

### Configs That Don't Apply on macOS

These are Linux/X11-specific and won't be used:
- `.Xresources` (X11 only)
- `.config/i3` (Linux window manager)
- `.config/picom` (X11 compositor)
- `.config/dunst` (Linux notifications)
- `scripts/thinkpad-hotspot.py` (Linux-specific)

## Troubleshooting

### tmux Mouse Scrolling

If mouse scrolling isn't working in tmux:
1. Make sure `set -g mouse on` is in `.tmux.conf`
2. Reload config: `Ctrl+b` then `r`
3. In vim, mouse should override tmux (scrolls vim buffer, not tmux history)

### Aerospace Not Working

If Aerospace isn't responding:
1. Check that you disabled Mission Control shortcuts
2. Restart Aerospace: Click menu bar icon → Quit, then relaunch
3. Check `~/.aerospace.toml` for syntax errors

### zsh "ps: illegal argument" Error

This has been fixed in the updated `.zshrc`. If you still see it:
```bash
source ~/.zshrc
```

## Recommended macOS Apps

### Essential
- **Aerospace** - i3-like tiling window manager
- **Homebrew** - Package manager
- **WezTerm** - Modern GPU-accelerated terminal (recommended, included in dotfiles)
- **Skim** - PDF viewer with vim-like keybindings (Cmd+F3 in Aerospace)

### Optional
- **Alfred** - Spotlight replacement (better than dmenu alternatives)
- **Karabiner-Elements** - Advanced keyboard customization
- **Stats** - Menu bar system monitor
- **Hidden Bar** - Hide menu bar icons

## Additional Resources

- [Aerospace Documentation](https://github.com/nikitabobko/AeroSpace)
- [Homebrew Package Search](https://brew.sh/)
- [Oh-My-Zsh Plugins](https://github.com/ohmyzsh/ohmyzsh/wiki/Plugins)
