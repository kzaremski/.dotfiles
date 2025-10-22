#!/bin/bash
# tmux monitor layout
# Structure: 4 equal panes for monitoring different services/logs

SESSION_NAME="${1:-monitor}"
START_DIR="${2:-$(pwd)}"

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# Create new session with the first window
tmux new-session -d -s "$SESSION_NAME" -n monitoring -c "$START_DIR"

# Create 4-pane grid layout
tmux split-window -h -p 50 -c "$START_DIR"    # Split vertically
tmux split-window -v -p 50 -t 0 -c "$START_DIR"  # Split top-left horizontally
tmux split-window -v -p 50 -t 2 -c "$START_DIR"  # Split top-right horizontally

# Optional: Set up pane contents for monitoring
# Pane 0 (top-left)
tmux select-pane -t 0
tmux send-keys "# System monitoring (htop/btop)" C-m

# Pane 1 (bottom-left)
tmux select-pane -t 1
tmux send-keys "# Logs monitoring" C-m

# Pane 2 (top-right)
tmux select-pane -t 2
tmux send-keys "# Network monitoring" C-m

# Pane 3 (bottom-right)
tmux select-pane -t 3
tmux send-keys "# Process monitoring" C-m

# Select first pane
tmux select-pane -t 0

# Attach to session
tmux attach-session -t "$SESSION_NAME"