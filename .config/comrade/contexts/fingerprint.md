# Fingerprint reader (GPD Pocket 4)

FocalTech 2808:0752. Omarchy 4.0.4, fprintd 1.94.5. Captured 2026-09-23.

## The driver

Stock `libfprint` has **no driver** for this reader. It needs the proprietary
`libfprint-ft9201` (AUR).

**The package must keep `libfprint-git` in its `provides`**, or
`omarchy setup security fingerprint` will uninstall it -- that script hardcodes
`libfprint-git` as the dependency it wants. This has already happened once.

Verify the driver actually sees the device by enumerating with an isolated
`LD_LIBRARY_PATH`, not by grepping the binary for USB IDs. Binary-scanning gives
false negatives: a control test looking for 22 known-supported HOLTEK IDs found
none of them either.

## The lid gate, and defeating omarchy's re-add

Omarchy inserts a clamshell gate before `pam_fprintd` in `/etc/pam.d/sudo` and
`/etc/pam.d/polkit-1`:

    auth [success=1 default=ignore] pam_exec.so quiet /usr/bin/omarchy-hw-laptop-closed

The script exits 0 when the lid is **closed**, and `success=1` skips the next
module -- so fingerprint is disabled in clamshell. That assumption is wrong for
the Pocket 4: **its reader is on the outside and is reachable with the lid shut.**

Removing the line is not enough. Both `omarchy-setup-security-fingerprint` and
migration `1784818437.sh` guard on:

    ! grep -q 'omarchy-hw-laptop-closed' "$pam"

They test for the **string**, not a working rule. So leave a commented tombstone
line containing the string: PAM ignores comments, the guards see it and do not
re-add. This generalises -- when an omarchy script keeps reasserting something,
satisfy its guard inertly rather than fighting it after the fact.

## Timeouts: sudo yes, polkit no

- `/etc/pam.d/sudo` -> `pam_fprintd.so timeout=10`. A TTY has no GUI, so PAM must
  serialise: prompt, block for the full timeout, only then offer the password.
  Default is 30s, which is a long stall.
- `/etc/pam.d/polkit-1` -> **no timeout, deliberately.** The omarchy-shell polkit
  agent shows the password field *while* pam_fprintd waits, so both inputs race
  and whichever lands first wins. A timeout there would only cut short a
  legitimate finger.

Both files are tracked as `system: true` entries -- see [[dotfiles]].

## pkexec is the right escalation for an agent

`pkexec` raises a GUI dialog the desktop's polkit agent draws, which accepts a
fingerprint. `sudo` needs a TTY for its password prompt and will hang when run
from a tool. The polkit agent is **omarchy-shell itself** ("omarchy polkit agent
registered" in its log) -- there is no separate agent binary, so grepping for one
finds nothing and wrongly suggests pkexec will fail.

## Known-bad: the driver throws on every attempt

    fprintd: fpi_device_action_error: assertion 'priv->current_action != FPI_DEVICE_ACTION_NONE' failed

Fires on essentially every verification. It is a libfprint-ft9201 bug, unrelated
to any PAM config, and means fallback to password happens more than it should.

## Enrolment

Only one finger enrolled by default is a common cause of "it randomly doesn't
work" -- on a *press* sensor a partial contact often does not register as a read
at all, so it logs no no-match and looks like nothing happened.

    for f in left-index-finger right-thumb left-thumb; do fprintd-enroll -f $f; done
    fprintd-list "$USER"        # check what is enrolled
