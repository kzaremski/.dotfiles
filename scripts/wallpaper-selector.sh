#!/bin/bash
# wallpaper-selector.sh
# dmenu/fzf-based wallpaper selector with symlink management

PICTURES_DIR="${PICTURES_DIR:-$HOME/Pictures}"
WALLPAPER_LINK="$HOME/.wallpaper"
STYLE_FILE="$HOME/.wallpaper-display-style"

# Function to notify (GUI or terminal)
notify() {
    if [ -n "$DISPLAY" ] && command -v notify-send &> /dev/null; then
        notify-send "Wallpaper" "$1"
    fi
    echo "$1"
}

# Get current display style (default: fill)
get_style() {
    if [ -f "$STYLE_FILE" ]; then
        cat "$STYLE_FILE"
    else
        echo "fill"
    fi
}

# Function to apply wallpaper with stored style
apply_wallpaper() {
    if ! command -v feh &> /dev/null; then
        notify "Error: feh not installed"
        exit 1
    fi

    local style=$(get_style)
    case "$style" in
        fill)    feh --bg-fill "$WALLPAPER_LINK" ;;
        fit)     feh --bg-max "$WALLPAPER_LINK" ;;
        stretch) feh --bg-scale "$WALLPAPER_LINK" ;;
        span)    feh --bg-fill --no-xinerama "$WALLPAPER_LINK" ;;
        center)  feh --bg-center "$WALLPAPER_LINK" ;;
        tile)    feh --bg-tile "$WALLPAPER_LINK" ;;
        *)       feh --bg-fill "$WALLPAPER_LINK" ;;
    esac
}

# Function to get current wallpaper (relative to PICTURES_DIR)
get_current() {
    if [ -L "$WALLPAPER_LINK" ]; then
        local target=$(readlink -f "$WALLPAPER_LINK")
        # Show path relative to Pictures if possible
        echo "${target#$PICTURES_DIR/}"
    else
        echo "(none)"
    fi
}

# Get list of wallpaper candidates (recursive search)
get_wallpapers() {
    find "$PICTURES_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | \
        sed "s|^$PICTURES_DIR/||" | \
        sort
}

# Reset wallpaper (just reapply current)
if [ "$1" = "reset" ] || [ "$1" = "-r" ]; then
    if [ -L "$WALLPAPER_LINK" ]; then
        apply_wallpaper
        notify "Wallpaper reset: $(get_current)"
    else
        notify "No wallpaper symlink found"
        exit 1
    fi
    exit 0
fi

# Non-interactive mode: set specific wallpaper
if [ -n "$1" ]; then
    target="$PICTURES_DIR/$1"
    if [ -f "$target" ]; then
        ln -sf "$target" "$WALLPAPER_LINK"
        apply_wallpaper
        notify "Wallpaper set: $1"
    else
        notify "File not found: $target"
        exit 1
    fi
    exit 0
fi

# Interactive mode
current=$(get_current)
wallpapers=$(get_wallpapers)

if [ -z "$wallpapers" ]; then
    notify "No wallpapers found in $PICTURES_DIR"
    exit 1
fi

# Build menu with reset option first
menu="[Reset current: $current]"$'\n'"$wallpapers"

# Choose selector: dmenu if in X, fzf otherwise
if [ -n "$DISPLAY" ] && command -v dmenu &> /dev/null; then
    selected=$(echo "$menu" | dmenu -i -l 15 -p "Wallpaper:" -fn "Terminus-10")
else
    if ! command -v fzf &> /dev/null; then
        echo "Error: dmenu or fzf required"
        exit 1
    fi
    selected=$(echo "$menu" | fzf --prompt="Wallpaper: " --height=50%)
fi

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Handle reset option
if [[ "$selected" == "[Reset current:"* ]]; then
    apply_wallpaper
    notify "Wallpaper reset: $current"
    exit 0
fi

# Set new wallpaper (use absolute path for symlink)
target="$PICTURES_DIR/$selected"
if [ ! -f "$target" ]; then
    notify "File not found: $selected"
    exit 1
fi

ln -sf "$target" "$WALLPAPER_LINK"

# Select display style
current_style=$(get_style)
styles="Fill (crop to fill screen) [current: $current_style]
Fit (show entire image, letterboxed)
Stretch (show entire image, distort to fill)
Span (single image across all monitors)
Center (centered, no scaling)
Tile (repeat pattern)"

if [ -n "$DISPLAY" ] && command -v dmenu &> /dev/null; then
    selected_style=$(echo "$styles" | dmenu -i -l 6 -p "Style:" -fn "Terminus-10")
else
    selected_style=$(echo "$styles" | fzf --prompt="Style: " --height=30%)
fi

# Default to fill if nothing selected
case "$selected_style" in
    "Fill"*)    echo "fill" > "$STYLE_FILE" ;;
    "Fit"*)     echo "fit" > "$STYLE_FILE" ;;
    "Stretch"*) echo "stretch" > "$STYLE_FILE" ;;
    "Span"*)    echo "span" > "$STYLE_FILE" ;;
    "Center"*)  echo "center" > "$STYLE_FILE" ;;
    "Tile"*)    echo "tile" > "$STYLE_FILE" ;;
    *)          ;; # Keep existing style if cancelled
esac

apply_wallpaper
notify "Wallpaper set: $selected ($(get_style))"
