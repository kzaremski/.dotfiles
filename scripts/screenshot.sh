#!/bin/bash
# screenshot.sh
# Screenshot utility with dmenu interface or direct capture
# Dependencies: maim, xclip, xdotool, dmenu (for menu mode)

SCREENSHOT_DIR="$HOME/Pictures"
TIMESTAMP=$(date --iso-8601=seconds)
FILENAME="Screenshot $TIMESTAMP.png"

# Check dependencies
for cmd in maim xclip; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed"
        exit 1
    fi
done

# Function to notify (GUI or terminal)
notify() {
    if [ -n "$DISPLAY" ] && command -v notify-send &> /dev/null; then
        notify-send "Screenshot" "$1"
    fi
    echo "$1"
}

# Function to take screenshot
# Args: $1 = mode (fullscreen|area|window), $2 = output (disk|clipboard|both)
take_screenshot() {
    local mode="$1"
    local output="$2"
    local maim_args=""
    local filepath="$SCREENSHOT_DIR/$FILENAME"

    case "$mode" in
        fullscreen)
            maim_args=""
            ;;
        area)
            maim_args="--select"
            ;;
        window)
            if ! command -v xdotool &> /dev/null; then
                notify "Error: xdotool required for window capture"
                exit 1
            fi
            maim_args="--window $(xdotool getactivewindow) --nodecorations=0"
            ;;
        *)
            notify "Error: Invalid mode"
            exit 1
            ;;
    esac

    case "$output" in
        disk)
            maim $maim_args "$filepath"
            [ $? -eq 0 ] && notify "Saved: $FILENAME"
            ;;
        clipboard)
            maim $maim_args | xclip -selection clipboard -t image/png
            [ $? -eq 0 ] && notify "Copied to clipboard"
            ;;
        both)
            maim $maim_args | tee "$filepath" | xclip -selection clipboard -t image/png
            [ $? -eq 0 ] && notify "Saved & copied: $FILENAME"
            ;;
        *)
            notify "Error: Invalid output"
            exit 1
            ;;
    esac
}

# Direct mode (non-interactive)
if [ -n "$1" ]; then
    mode="$1"
    output="${2:-both}"
    take_screenshot "$mode" "$output"
    exit 0
fi

# Interactive dmenu mode
if [ -z "$DISPLAY" ] || ! command -v dmenu &> /dev/null; then
    echo "Error: dmenu mode requires X display and dmenu"
    exit 1
fi

# Select capture mode
modes="Fullscreen
Area (select)
Window (active)"

selected_mode=$(echo "$modes" | dmenu -i -l 3 -p "Capture:" -fn "Terminus-10")
[ -z "$selected_mode" ] && exit 0

case "$selected_mode" in
    "Fullscreen") mode="fullscreen" ;;
    "Area (select)") mode="area" ;;
    "Window (active)") mode="window" ;;
esac

# Select output destination
outputs="Both (save & clipboard)
Clipboard only
Save to disk only"

selected_output=$(echo "$outputs" | dmenu -i -l 3 -p "Output:" -fn "Terminus-10")
[ -z "$selected_output" ] && exit 0

case "$selected_output" in
    "Both (save & clipboard)") output="both" ;;
    "Clipboard only") output="clipboard" ;;
    "Save to disk only") output="disk" ;;
esac

take_screenshot "$mode" "$output"
