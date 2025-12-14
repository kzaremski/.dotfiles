#!/bin/bash
# lock.sh - wrapper for i3lock that disables numlock first

# Disable numlock before locking
numlockx off 2>/dev/null

# Lock the screen (pass through any arguments)
exec i3lock "$@"
