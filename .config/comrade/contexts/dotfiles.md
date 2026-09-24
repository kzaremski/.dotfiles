# ~/.dotfiles: how this repo works, and its traps

Applies to the repo at ~/.dotfiles with manifest.yaml + dotfiles.py.
Captured 2026-09-23.

## Model

`manifest.yaml` lists entries; `dotfiles.py` symlinks repo -> $HOME. Entries
carry labels so one manifest serves several machines:

    dotfiles.py --label omarchy --yes
    dotfiles.py --labels                # what's available
    dotfiles.py --dry-run / --unlink

**Live wins.** When the live system and the repo disagree, the live system is
correct -- copy live into the repo, never the reverse. The repo is frequently
behind.

## System files (outside $HOME)

An entry with `system: true` takes its source from `<repo>/root/` and an
absolute `dest`. These are **copied, never symlinked**, and are excluded from
every link path:

    dotfiles.py --import-system     repo  -> system (root, one auth for all)
    dotfiles.py --export-system     system -> repo  (plain read)

Why copy: /etc/pam.d files must stay root-owned. A symlink into this
user-writable repo would let an unprivileged user rewrite their own auth rules.
`--unlink` never touches system entries.

## TRAP: never track ~/.config/systemd/user as a directory

**This silently disabled 11 services and it was not noticed for 18 hours.**

systemd records "enabled" as symlinks it writes into `.wants/` subdirectories
*inside* that directory. Tracking the directory makes dotfiles.py back it up and
replace it with a symlink to the repo -- destroying every enable-symlink. The
units still exist and `systemctl --user status` looks normal; they simply never
start again.

Casualties that time: omarchy-sleep-lock (so **no lock screen after suspend** --
a security hole), ssh-agent.socket, pipewire-pulse, onedrive, fcitx5, bt-agent,
podman.socket, omarchy-crash-watch, omarchy-recover-internal-monitor,
omarchy-tailscale-receive, omarchy-migrate-notify.

**Track individual unit files instead:**

    - source: .config/systemd/user/ollama.service      # the FILE
      dest: .config/systemd/user/ollama.service

Recovery, if it happens again -- dotfiles.py's backup holds the truth:

    b=~/.dotfiles-backup/.config_systemd_user.backup.<timestamp>
    for u in $(find "$b" -mindepth 2 -type l -printf "%f\n" | sort -u); do
      systemctl --user enable "$u"
    done

The same hazard applies to any directory an application writes its own state
into. Track the file, not the directory.

## Other traps

- **manifest.yaml is indented 2 spaces**, not 4. Reading it through `sed 's/^/  /'`
  makes it look like 4 and anchors then fail to match.
- **A directory entry means the files inside are NOT symlinks** -- the parent is.
  `ls -la` on the file shows a regular file; check the parent before concluding
  something is untracked.
- **Entries can be in the manifest but never linked** if you only ever run with a
  label that doesn't match. `.desktop` files sat as plain files this way, and
  edits to them silently diverged from the repo.
- **`.desktop` Exec= is not shell-expanded** -- `~` and `$HOME` are literal and
  there is no `%h`. Use a bare command name on PATH.

## Related

[[local-llm-comrade-setup]] for the ollama unit's contents.
