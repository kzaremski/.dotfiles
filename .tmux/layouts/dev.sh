#!/bin/bash
# tmux dev layout
# Structure: 60/40 vertical split, left pane split 70/30 horizontally

BASE_NAME="${1:-dev}"
START_DIR="${2:-$(pwd)}"

# Find an available session name
SESSION_NAME="$BASE_NAME"
COUNTER=1
while tmux has-session -t "$SESSION_NAME" 2>/dev/null; do
    SESSION_NAME="${BASE_NAME}-${COUNTER}"
    ((COUNTER++))
done

echo "Creating new session: $SESSION_NAME"

# Create new session with the first window
tmux new-session -d -s "$SESSION_NAME" -n main -c "$START_DIR"

# Create the layout structure
# Start with vertical split (60/40)
tmux split-window -h -p 40 -c "$START_DIR"

# Select the left pane and split it horizontally (70/30)
tmux select-pane -t 1
tmux split-window -v -p 30 -c "$START_DIR"

# Ensure all panes are in the correct directory
tmux send-keys -t "$SESSION_NAME:main.1" "cd \"$START_DIR\"" C-m
tmux send-keys -t "$SESSION_NAME:main.2" "cd \"$START_DIR\"" C-m
tmux send-keys -t "$SESSION_NAME:main.3" "cd \"$START_DIR\"" C-m

# Clear the prompts
tmux send-keys -t "$SESSION_NAME:main.1" "clear" C-m
tmux send-keys -t "$SESSION_NAME:main.2" "clear" C-m

# Launch claude in pane 3 (right pane)
tmux send-keys -t "$SESSION_NAME:main.3" 'claude' C-m

# Select the main editing pane
tmux select-pane -t 1
tmux send-keys -t "$SESSION_NAME:main.1" 'vim' C-m

# Attach to session
tmux attach-session -t "$SESSION_NAME"
