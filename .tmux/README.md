# Tmux Layout System

A simple, dependency-free tmux layout management system for quickly launching predefined pane configurations.

## Usage

### Basic Commands

```bash
# List available layouts
tmux-layout list

# Launch a specific layout
tmux-layout dev
tmux-layout monitor
tmux-layout simple

# Launch with custom session name and directory
tmux-layout dev myproject ~/projects/myproject
```

### Quick Aliases

After linking your dotfiles, these aliases are available:

```bash
tmux-dev        # Launch development layout
tmux-monitor    # Launch monitoring layout
tmux-simple     # Launch simple split layout
```

## Available Layouts

### dev
- **Structure**: 60/40 vertical split with left pane split 70/30 horizontally
- **Use case**: Development with main editor, terminal, and logs/monitoring
- **Panes**:
  - Top-left (60% width, 70% height): Main editor
  - Bottom-left (60% width, 30% height): Terminal/testing
  - Right (40% width): Logs/monitoring

### monitor
- **Structure**: 4 equal panes in a grid
- **Use case**: Monitoring multiple services or logs
- **Panes**: 4 equal-sized panes for different monitoring tasks

### simple
- **Structure**: Horizontal 50/50 split
- **Use case**: Basic editor + terminal setup
- **Panes**:
  - Top: Editor/main work
  - Bottom: Terminal

## Creating New Layouts

1. Create a new shell script in `.tmux/layouts/`:

```bash
#!/bin/bash
# tmux [layout_name] layout
# Structure: [describe the layout]

SESSION_NAME="${1:-layout_name}"
START_DIR="${2:-$(pwd)}"

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# Create new session
tmux new-session -d -s "$SESSION_NAME" -n main -c "$START_DIR"

# Create your layout with splits
tmux split-window -h -p 40 -c "$START_DIR"  # Vertical split, 40% for right pane
tmux split-window -v -p 30 -c "$START_DIR"  # Horizontal split, 30% for bottom pane

# Attach to session
tmux attach-session -t "$SESSION_NAME"
```

2. Make it executable:
```bash
chmod +x .tmux/layouts/your_layout.sh
```

3. Optionally add an alias to `.zshrc`:
```bash
alias tmux-your-layout="tmux-layout your_layout"
```

## Tips

- Sessions persist until manually killed with `tmux kill-session -t session_name`
- If a session exists with the same name, the script will attach to it instead of creating a new one
- Use `tmux ls` to list active sessions
- Use `Ctrl-b d` to detach from a session without killing it
- Use `tmux attach -t session_name` to reattach to a detached session

## Customization

Each layout script can be customized with:
- Initial commands to run in each pane
- Different split percentages
- Multiple windows within a session
- Pane synchronization for running commands across multiple panes