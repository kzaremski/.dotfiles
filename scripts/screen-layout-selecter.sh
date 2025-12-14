#!/bin/sh
# screen-layout-selecter.sh
# Select and apply monitor layout via dmenu

LAYOUTS_DIR="$HOME/.dotfiles/screenlayout"

# Build list of layouts with descriptions
layout_list=""
for layout in "$LAYOUTS_DIR"/*.sh; do
    [ -f "$layout" ] || continue
    name=$(basename "$layout" .sh)

    # Extract description from line 3 (after shebang and filename)
    desc=$(sed -n '3s/^#\s*//p' "$layout" 2>/dev/null)

    if [ -n "$desc" ]; then
        layout_list="$layout_list$name | $desc
"
    else
        layout_list="$layout_list$name
"
    fi
done

# Show dmenu and get selection
selected=$(echo -n "$layout_list" | dmenu -i -l 10 -p "Layout:" -fn "Terminus-10")

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Extract layout name (before the | if present)
layout_name=$(echo "$selected" | cut -d'|' -f1 | xargs)

echo "Switching layout to: $layout_name.sh"
# Run the chosen screen layout set script
sh "$LAYOUTS_DIR/$layout_name.sh"
# Reapply wallpaper with user's settings
"$HOME/.dotfiles/scripts/wallpaper-selector.sh" -r
