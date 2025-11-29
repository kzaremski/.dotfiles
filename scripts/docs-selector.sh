#!/bin/bash
# docs-selector.sh
# dmenu-based documentation/reference viewer
# Opens selected doc in kitty with less

DOCS_DIR="${DOCS_DIR:-$HOME/.dotfiles/docs}"

# Check if docs directory exists
if [ ! -d "$DOCS_DIR" ]; then
    notify-send "Docs Selector" "Docs directory not found: $DOCS_DIR"
    exit 1
fi

# Find all files in docs directory and get basenames
selected=$(find "$DOCS_DIR" -type f -name "*.md" -o -name "*.txt" | \
    sed "s|$DOCS_DIR/||" | \
    sort | \
    dmenu -i -l 20 -p "Docs:" -fn "CaskaydiaCove Nerd Font Mono-10")

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Full path to selected file
doc_path="$DOCS_DIR/$selected"

# Check if file exists
if [ ! -f "$doc_path" ]; then
    notify-send "Docs Selector" "File not found: $doc_path"
    exit 1
fi

# Open in kitty with less (or bat if available for syntax highlighting)
if command -v bat &> /dev/null; then
    kitty --title "Docs: $selected" bat --paging=always "$doc_path"
else
    kitty --title "Docs: $selected" less "$doc_path"
fi
