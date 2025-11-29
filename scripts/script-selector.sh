#!/bin/bash
# script-selector.sh
# dmenu-based launcher for scripts in ~/.dotfiles/scripts/

SCRIPTS_DIR="${SCRIPTS_DIR:-$HOME/.dotfiles/scripts}"

# Check if scripts directory exists
if [ ! -d "$SCRIPTS_DIR" ]; then
    notify-send "Script Selector" "Scripts directory not found: $SCRIPTS_DIR"
    exit 1
fi

# Build list of scripts with descriptions
script_list=""
while IFS= read -r script; do
    name=$(basename "$script")

    # Skip self and install script
    [[ "$name" == "script-selector.sh" ]] && continue
    [[ "$name" == "install.sh" ]] && continue

    # Skip scripts marked with launcher-ignore in first 5 lines
    if head -5 "$script" 2>/dev/null | grep -q "launcher-ignore"; then
        continue
    fi

    # Extract description from line 3 (after shebang and filename)
    # Expected format:
    #   #!/bin/bash
    #   # script-name.sh
    #   # Description here
    desc=$(sed -n '3s/^#\s*//p' "$script" 2>/dev/null)

    if [ -n "$desc" ]; then
        script_list+="$name | $desc"$'\n'
    else
        script_list+="$name"$'\n'
    fi
done < <(find "$SCRIPTS_DIR" -maxdepth 1 -type f -executable | sort)

# Show dmenu and get selection
selected=$(echo -n "$script_list" | dmenu -i -l 20 -p "Scripts:" -fn "CaskaydiaCove Nerd Font Mono-10")

# Exit if nothing selected
[ -z "$selected" ] && exit 0

# Extract script name (before the | if present)
script_name=$(echo "$selected" | cut -d'|' -f1 | xargs)

# Full path to selected script
script_path="$SCRIPTS_DIR/$script_name"

# Check if file exists and is executable
if [ ! -x "$script_path" ]; then
    notify-send "Script Selector" "Script not found: $script_path"
    exit 1
fi

# Execute the script
exec "$script_path"
