#!/bin/bash
# Set vim (via WezTerm) as default editor for common text file types
# Requires: brew install duti

# Check if duti is installed
if ! command -v duti &> /dev/null; then
  echo "Error: duti is not installed."
  echo "Install it with: brew install duti"
  exit 1
fi

# Check if WezTermVim.app exists, if not, create it
if [ ! -d "/Applications/WezTermVim.app" ]; then
  echo "WezTermVim.app not found. Creating it..."
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  "$SCRIPT_DIR/create-wezterm-vim-app.sh"
  echo ""
fi

echo "Setting WezTermVim as default application for text file types..."
echo "Files will automatically open in WezTerm with vim!"
echo ""

# Use the WezTermVim wrapper app instead of plain WezTerm
duti -s com.local.weztermvim .txt all
duti -s com.local.weztermvim .md all
duti -s com.local.weztermvim .markdown all
duti -s com.local.weztermvim .sh all
duti -s com.local.weztermvim .bash all
duti -s com.local.weztermvim .zsh all
duti -s com.local.weztermvim .py all
duti -s com.local.weztermvim .js all
duti -s com.local.weztermvim .json all
duti -s com.local.weztermvim .yaml all
duti -s com.local.weztermvim .yml all
duti -s com.local.weztermvim .toml all
duti -s com.local.weztermvim .conf all
duti -s com.local.weztermvim .config all
duti -s com.local.weztermvim .log all
duti -s com.local.weztermvim .xml all
duti -s com.local.weztermvim .html all
duti -s com.local.weztermvim .css all
duti -s com.local.weztermvim .rs all
duti -s com.local.weztermvim .go all
duti -s com.local.weztermvim .c all
duti -s com.local.weztermvim .cpp all
duti -s com.local.weztermvim .h all
duti -s com.local.weztermvim .hpp all
duti -s com.local.weztermvim .lua all
duti -s com.local.weztermvim .vim all

# Set Skim as default PDF viewer
if [ -d "/Applications/Skim.app" ]; then
  duti -s net.sourceforge.skim-app.skim .pdf all
  echo "✓ Set Skim as default PDF viewer"
fi

echo ""
echo "✓ File associations set!"
echo ""
echo "Text files will now open directly in vim (via WezTerm) when double-clicked!"
if [ -d "/Applications/Skim.app" ]; then
  echo "PDF files will now open in Skim!"
fi
echo ""
echo "The WezTermVim.app wrapper has been installed to /Applications/"
echo "This automatically launches: wezterm start vim <filename>"
echo ""
echo "Supported file types:"
echo "  Text: .txt, .md, .py, .js, .json, .yaml, .sh, .toml,"
echo "        .conf, .log, .xml, .html, .css, .rs, .go, .c, .cpp, .lua, .vim, and more"
if [ -d "/Applications/Skim.app" ]; then
  echo "  PDF: .pdf → Skim"
fi
echo ""
echo "To undo these changes:"
echo "  1. Right-click a file → Get Info"
echo "  2. Change 'Open with' back to your preferred app"
echo "  3. Click 'Change All...'"
