#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

export PATH="/home/kzaremski/.npm-global/bin:/home/kzaremski/.cargo/bin:/home/kzaremski/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/cxoffice/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl"
export GPG_TTY=$(tty)

# SSH Agent Setup (KeePassXC → keychain → ssh-agent fallback)
if [ -S "${XDG_RUNTIME_DIR}/ssh-agent.socket" ]; then
    # KeePassXC SSH agent
    export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR}/ssh-agent.socket"
elif command -v keychain &>/dev/null; then
    # Fallback to keychain for headless servers
    eval "$(keychain --eval --quiet --agents ssh id_ed25519 2>/dev/null)"
elif [ -z "$SSH_AUTH_SOCK" ]; then
    # Last resort: start ssh-agent
    eval "$(ssh-agent -s)" &>/dev/null
fi
