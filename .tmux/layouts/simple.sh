#!/bin/bash
# tmux simple layout
# Structure: Simple horizontal split (50/50)

SESSION_NAME="${1:-simple}"
START_DIR="${2:-$(pwd)}"

# Check if session already exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "Session '$SESSION_NAME' already exists. Attaching..."
    tmux attach-session -t "$SESSION_NAME"
    exit 0
fi

# Create new session with the first window
tmux new-session -d -s "$SESSION_NAME" -n main -c "$START_DIR"

# Create simple horizontal split
tmux split-window -v -p 50 -c "$START_DIR"

# Optional: Set up pane contents
# Top pane (editor/work)
tmux select-pane -t 0
tmux send-keys "# Editor/main work" C-m
tmux send-keys "clear" C-m

# Bottom pane (terminal)
tmux select-pane -t 1
tmux send-keys "# Terminal" C-m
tmux send-keys "clear" C-m

# Select the top pane
tmux select-pane -t 0

# Attach to session
tmux attach-session -t "$SESSION_NAME"