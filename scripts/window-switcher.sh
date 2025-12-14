#!/bin/bash
# window-switcher.sh
# dmenu-based window switcher (Alt+Tab replacement)

# Get all visible windows with their IDs, class, and title
get_windows() {
    xdotool search --onlyvisible --name "" 2>/dev/null | while read -r wid; do
        # Skip windows without a name (panels, etc)
        name=$(xdotool getwindowname "$wid" 2>/dev/null)
        [ -z "$name" ] && continue

        # Check window type - only show NORMAL or DIALOG windows
        wtype=$(xprop -id "$wid" _NET_WM_WINDOW_TYPE 2>/dev/null)
        case "$wtype" in
            *_NET_WM_WINDOW_TYPE_NORMAL*|*_NET_WM_WINDOW_TYPE_DIALOG*) ;;
            *) continue ;;
        esac

        # Get window class (application name)
        class=$(xprop -id "$wid" WM_CLASS 2>/dev/null | sed 's/.*= "\([^"]*\)".*/\1/')
        [ -z "$class" ] && class="unknown"

        # Skip systray apps and i3 internals
        lclass=$(echo "$class" | tr '[:upper:]' '[:lower:]')
        case "$lclass" in
            *tray*|nextcloud|nm-applet|blueman*|i3*) continue ;;
        esac

        # Format: [class] title | window_id
        printf "[%s] %s\t%s\n" "$class" "$name" "$wid"
    done
}

# Get window list
windows=$(get_windows)

if [ -z "$windows" ]; then
    notify-send "Window Switcher" "No windows found"
    exit 1
fi

# Show dmenu (hide the window ID column)
selected=$(echo "$windows" | cut -f1 | dmenu -i -l 15 -p "Window:" -fn "Terminus-10")

[ -z "$selected" ] && exit 0

# Find the window ID for the selected entry
wid=$(echo "$windows" | grep -F "$selected" | head -1 | cut -f2)

if [ -n "$wid" ]; then
    # Focus the window and switch to its workspace
    i3-msg "[id=$wid]" focus >/dev/null 2>&1
fi
