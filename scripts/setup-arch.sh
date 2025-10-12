#!/bin/bash
# Konstantin Zaremski's Arch Linux Setup Script
# Sets up a fresh Arch installation with all necessary packages

set -e  # Exit on error

echo "=========================================="
echo "  Arch Linux System Setup"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo "Error: Do not run this script as root!"
  echo "Run as normal user with sudo privileges."
  exit 1
fi

# Update system
echo "==> Updating system..."
sudo pacman -Syu --noconfirm

# Core window manager and X11
echo ""
echo "==> Installing i3 window manager and X11..."
sudo pacman -S --noconfirm i3-wm i3status i3lock dmenu
sudo pacman -S --noconfirm xorg-server xorg-xinit xorg-xrandr xorg-xsetroot
sudo pacman -S --noconfirm picom dunst feh maim xclip

# Terminal and shell
echo ""
echo "==> Installing terminal and shell..."
sudo pacman -S --noconfirm rxvt-unicode zsh tmux
sudo pacman -S --noconfirm alacritty  # Alternative terminal

# Core utilities
echo ""
echo "==> Installing core utilities..."
sudo pacman -S --noconfirm vim git curl wget base-devel
sudo pacman -S --noconfirm htop bpytop
sudo pacman -S --noconfirm ripgrep fd bat exa fzf
sudo pacman -S --noconfirm brightnessctl playerctl

# Network management
echo ""
echo "==> Installing network tools..."
sudo pacman -S --noconfirm networkmanager network-manager-applet
sudo pacman -S --noconfirm blueman pulseaudio pasystray

# File managers
echo ""
echo "==> Installing file managers..."
sudo pacman -S --noconfirm pcmanfm ranger krusader

# Applications
echo ""
echo "==> Installing applications..."
sudo pacman -S --noconfirm firefox thunderbird
sudo pacman -S --noconfirm libreoffice-fresh

# Fonts
echo ""
echo "==> Installing fonts..."
sudo pacman -S --noconfirm ttf-cascadia-code-nerd
sudo pacman -S --noconfirm ttf-dejavu ttf-liberation noto-fonts

# Development tools
echo ""
echo "==> Installing development tools..."
sudo pacman -S --noconfirm python python-pip
sudo pacman -S --noconfirm rust cargo
sudo pacman -S --noconfirm nodejs npm

# Install yay (AUR helper) if not present
echo ""
if ! command -v yay &> /dev/null; then
  echo "==> Installing yay (AUR helper)..."
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ~
else
  echo "==> yay already installed, skipping..."
fi

# AUR packages
echo ""
echo "==> Installing AUR packages..."
yay -S --noconfirm visual-studio-code-bin
# yay -S --noconfirm spotify  # Uncomment if you want Spotify

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

# Enable NetworkManager
echo ""
echo "==> Enabling NetworkManager..."
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# Set zsh as default shell
echo ""
echo "==> Setting zsh as default shell..."
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s $(which zsh)
  echo "Default shell changed to zsh. You'll need to log out and back in."
else
  echo "zsh is already the default shell."
fi

echo ""
echo "=========================================="
echo "  Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Log out and log back in"
echo "2. Run the dotfiles manager: cd ~/.dotfiles && python3 dotfiles.py"
echo "3. Install Vim plugins: vim +PlugInstall +qall"
echo "4. Configure i3: copy the example i3 config or use dotfiles"
echo ""
echo "Optional:"
echo "- Install a display manager (lightdm, gdm, sddm)"
echo "- Configure monitor layouts in ~/.screenlayout/"
echo "- Set up wallpaper in ~/Pictures/wallpaper.jpg"
