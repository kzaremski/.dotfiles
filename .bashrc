# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Add your own exports, aliases, and functions here.
#
# Make an alias for invoking commands you use constantly
# alias p='python'

# Resume the long-running Claude Code session for this machine's own config.
# && rather than ; so it cannot start the session in the wrong directory if
# ~/Work is missing.
alias pw='cd ~/Work && claude --resume "Pocket Worker"'

# Use the systemd-managed ssh-agent (see ~/.config/environment.d/10-ssh-agent.conf).
# Guarded: a no-op once environment.d has already exported SSH_AUTH_SOCK.
if [ -z "$SSH_AUTH_SOCK" ] && [ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]; then
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# yazi, but leave the shell wherever you navigated to.
#
# Plain `yazi` always drops you back where you started, which is the thing
# people miss when they first try it. --cwd-file makes yazi write its final
# directory out on exit, and this reads it back and cds there.
#
# `y` rather than overriding `yazi`: keeping the bare command untouched means
# scripts and the SUPER+SHIFT+F binding behave normally.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd <"$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}
