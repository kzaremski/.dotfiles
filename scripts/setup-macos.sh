#!/bin/bash
# Konstantin Zaremski's macOS Setup Script
# Sets up a fresh macOS installation with all necessary packages

set -e  # Exit on error

echo "=========================================="
echo "  macOS System Setup"
echo "=========================================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ $(uname -m) == 'arm64' ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
else
  echo "==> Homebrew already installed"
  echo "==> Updating Homebrew..."
  brew update
fi

# Core terminal tools
echo ""
echo "==> Installing terminal and shell tools..."
brew install tmux
brew install zsh zsh-completions

# Core utilities
echo ""
echo "==> Installing core utilities..."
brew install vim git curl wget
brew install htop btop
brew install ripgrep fd bat exa fzf
brew install tree

# Modern Unix tools
echo ""
echo "==> Installing modern Unix replacements..."
brew install dust      # Better du
brew install duf       # Better df
brew install procs     # Better ps

# Development tools
echo ""
echo "==> Installing development tools..."
brew install python
brew install rust
brew install node

# Window management
echo ""
echo "==> Installing window manager (Aerospace)..."
brew install --cask nikitabobko/tap/aerospace

# Applications
echo ""
echo "==> Installing applications..."
brew install --cask visual-studio-code
brew install --cask firefox
brew install --cask wezterm            # Modern GPU-accelerated terminal
brew install --cask skim               # PDF viewer with vim-like keybindings
# brew install --cask iterm2           # Uncomment if you prefer iTerm2
# brew install --cask spotify          # Uncomment if you want Spotify
# brew install --cask rectangle        # Alternative window manager

# Fonts
echo ""
echo "==> Installing fonts..."
brew tap homebrew/cask-fonts
brew install --cask font-caskaydia-cove-nerd-font
brew install --cask font-hack-nerd-font
brew install --cask font-jetbrains-mono-nerd-font

# Optional: Recommended tools
echo ""
echo "==> Installing optional recommended tools..."
brew install --cask alfred          # Better Spotlight
brew install duti                   # File association manager
# brew install --cask karabiner-elements  # Keyboard customization
# brew install stats                # Menu bar system monitor

# Install Oh-My-Zsh
echo ""
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "==> Installing Oh-My-Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "==> Oh-My-Zsh already installed, skipping..."
fi

# Install Vim-Plug
echo ""
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "==> Installing Vim-Plug..."
  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
  echo "==> Vim-Plug already installed, skipping..."
fi

# Set zsh as default shell (if not already)
echo ""
echo "==> Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s $(which zsh)
  echo "Default shell changed to zsh."
else
  echo "zsh is already the default shell."
fi

# macOS-specific tweaks
echo ""
echo "==> Applying macOS tweaks..."

# Enable click-and-drag windows with Ctrl+Cmd
defaults write -g NSWindowShouldDragOnGesture -bool true
echo "  ✓ Enabled click-and-drag anywhere on windows (Ctrl+Cmd)"

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true
echo "  ✓ Enabled showing hidden files in Finder"

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
echo "  ✓ Disabled press-and-hold (enables key repeat)"

# Set faster key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
echo "  ✓ Set faster key repeat"

# Restart Finder to apply changes
killall Finder 2>/dev/null || true

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Log out and log back in (for shell and defaults changes)"
echo "2. Disable conflicting macOS keyboard shortcuts:"
echo "   System Settings → Keyboard → Keyboard Shortcuts → Mission Control"
echo "   - Uncheck 'Mission Control' (Control + Up)"
echo "   - Uncheck 'Application Windows' (Control + Down)"
echo "   - Uncheck 'Move left/right a space' (Control + Left/Right)"
echo ""
echo "3. Run the dotfiles manager:"
echo "   cd ~/.dotfiles && python3 dotfiles.py --install-deps"
echo "   python3 dotfiles.py"
echo ""
echo "4. Install Vim plugins:"
echo "   vim +PlugInstall +qall"
echo ""
echo "5. Configure Aerospace:"
echo "   See: ~/.dotfiles/docs/MACOS_CONFIG.md"
echo ""
echo "Optional next steps:"
echo "- Set WezTerm as your default terminal (System Settings → Default Terminal)"
echo "- Set WezTerm as default for text files: ./scripts/set-vim-default.sh"
echo "- Configure Aerospace: ~/.aerospace.toml (already in dotfiles)"
echo "- Install Alfred for better app launcher (already installed)"
echo "- Install Karabiner-Elements for advanced keyboard customization"
echo ""
echo "Aerospace keybindings (i3-style):"
echo "- Cmd + Arrow Keys (or h/j/k/l) - Focus windows"
echo "- Cmd + Shift + Arrow Keys - Move windows"
echo "- Cmd + 1-9,0 - Switch workspaces"
echo "- Cmd + F - Fullscreen"
echo "- Cmd + R - Resize mode"
echo "See docs/MACOS_CONFIG.md for complete Aerospace documentation"
