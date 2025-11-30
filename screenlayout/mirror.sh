#!/bin/sh
# mirror.sh
# Mirror internal display to first connected external monitor
# Automatically detects external monitor and matches its resolution

# Find the internal display (LVDS or eDP)
INTERNAL=$(xrandr --query | grep -E "^(LVDS|eDP)" | grep " connected" | cut -d' ' -f1 | head -1)

# Find first connected external display
EXTERNAL=$(xrandr --query | grep -E "^(HDMI|VGA|DP|DisplayPort)" | grep " connected" | cut -d' ' -f1 | head -1)

if [ -z "$INTERNAL" ]; then
    echo "No internal display found"
    exit 1
fi

if [ -z "$EXTERNAL" ]; then
    echo "No external display connected"
    exit 1
fi

# Get the preferred/native resolution of the external monitor (first mode listed)
EXT_RES=$(xrandr --query | grep -A1 "^$EXTERNAL connected" | tail -1 | awk '{print $1}')

echo "Mirroring $INTERNAL to $EXTERNAL at $EXT_RES"

# Set both displays to same resolution and position (mirror)
xrandr --output "$INTERNAL" --mode "$EXT_RES" --pos 0x0 --output "$EXTERNAL" --mode "$EXT_RES" --pos 0x0 --same-as "$INTERNAL"

# Reset wallpaper
feh --bg-fill ~/Pictures/wallpaper.jpg
