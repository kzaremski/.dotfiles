# DaVinci Resolve on Omarchy / Linux

Applies to: Resolve **Studio 21.1**, Omarchy 4.0.4, Hyprland 0.56.2, AMD 890M (gfx1150).
Captured 2026-09-22. Version-sensitive -- recheck before trusting.

## Codecs: the big one

Free Resolve on Linux **cannot decode H.264, H.265 or AAC at all** -- Blackmagic
doesn't license them for the Linux build. Studio adds H.264/H.265 but **AAC stays
locked out in every edition**.

Symptom: clips show as "missing" and Relink can't find them even when the files are
right there. Resolve finds them and *refuses* them; relink can't fix an unsupported
format. Nothing to do with paths.

CONFIRMED 2026-09-22: Studio's HEVC decode **does work on the AMD 890M (gfx1150)**
under Omarchy, despite Blackmagic only officially supporting NVIDIA on Linux.
Video played back fine; only audio was missing, exactly as the licensing implies.

Fixes:
- Video: install Studio (`davinci-resolve-studio` AUR, needs the Studio zip).
- Audio: remux AAC -> PCM. Lossless and ~0.1s per clip, video stream-copied.

      resolve-fix-audio <dir of clips>        # in ~/.local/bin, from dotfiles

  It verifies each file's video stream hash matches the original BEFORE
  replacing it, keeps filenames (so no relink), and skips files already PCM.
  The underlying call is:

      ffmpeg -i in.MP4 -map 0 -c copy -c:a pcm_s16le -f mov out.MP4

  `-map 0` keeps DJI gyro/telemetry streams (2.5 Mb/s, needed by Gyroflow).
  Verify with: `ffmpeg -i X -map 0:v:0 -c copy -f md5 -` before/after.
  Done in anger on 28 clips (16.1 GB): 73 seconds, +0.9 GB, 0 failures, filenames
  unchanged so Resolve needed no relink.
  Transcoding to DNxHR HQX instead works but cost 16 GB -> 227 GB for 95 min.
  Use **HQX not HQ**: identical size, but HQ is 8-bit and throws away 10-bit source.

## "Cannot validate license key, please try again later"

**Almost always a filesystem permission problem, not network or TLS.**

Resolve stores activation in `/opt/resolve/.license/`, which the AUR package ships
`root:root 755`. Resolve runs as *you*. Activation succeeds over the network, fails
to persist, and reports the above. Same for `/opt/resolve/Extras` (the "invalid
chunk file" DDM warnings).

    pkexec resolve-perms "$USER"            # in ~/.local/bin, from dotfiles

That script re-owns every directory Resolve needs to write:

    /opt/resolve/.license      activation state (the error above)
    /opt/resolve/Extras        DLC downloads ("invalid chunk file" warnings)
    /opt/resolve/LUT           where the LUT browser reads -- needed to add your own
    /opt/resolve/Fusion/LUTs   same, for Fusion

**pacman resets ownership on every Resolve upgrade** -- re-run it afterwards.

**`.license` must be 0777, not 755.** It holds an RLM licence-manager tree
(`Do-NOT-Touch-Anything-in-This-RLM-Directory`), Resolve creates it world-
writable itself, and the Arch/AUR community documents 777 as required.
Tightening it "for neatness" makes Resolve **re-prompt for the licence key on
every start** -- activation stops persisting, with `LeManager ERROR 24, 291`
and `22, 334, -4` in the log. This was done once and cost an evening.

Note `~/.local/share/DaVinciResolve/.LUT` is Resolve's processed cache, not the
place to drop your own LUTs -- it renames `.ilut` to `_ilut` and generates .png
thumbnails. Use /opt/resolve/LUT.

## "Resolve won't launch" -- exits 0, no window, no log lines

It is usually **already running and wedged**. Resolve uses a Qt single-instance
lock; a second launch hands off to the live instance and exits 0 silently.

    pgrep -af /opt/resolve/bin/resolve     # NOT pgrep -x: comm is "GUI Thread"
    kill <pid>; rm -f /tmp/qtsingleapp-DaVinc-*

/tmp is tmpfs, so a reboot also clears it -- which is why this gets misattributed
to "rebooting fixed it".

## UI scaling

Resolve ignores QT_SCALE_FACTOR. Scaling is `<DisplayScale>` in
`~/.local/share/DaVinciResolve/configs/config.user.xml` -- a single global value,
no per-monitor setting. 200 suits the Pocket 4 panel, 100 the 1080p dock, so a
value set on one is wrong on the other. `~/.local/bin/resolve-scaled` rewrites it
from the focused monitor's scale at launch. Fixed at launch only; relaunch after
docking.

## Popups capture the mouse (unresolved)

Resolve is XWayland-only. Its Qt dialogs issue an X11 `XGrabPointer`, which
XWayland converts imperfectly into a Wayland pointer constraint -- worse with
scaling and multiple monitors, both of which apply here. A popup traps the pointer
until dismissed.

**No fix exists.** hyprwm/Hyprland#3342 (a grab-release dispatcher) is open and
unimplemented. Window rules cannot help: they act on focus, the grab is below that.

Do NOT apply the widely-circulated `stayfocused` rule -- it pins focus to the
popup, which *causes* this symptom. It's the fix for the opposite problem (popups
vanishing on pointer-leave). Workaround: dismiss dialogs before clicking away.

## "Asks for the licence key on every start"

Not a licensing problem -- a permissions one. See the `.license` 0777 note
above. `pkexec resolve-perms "$USER"` restores it.

## "Won't launch" -- use the command

    resolve-unstick        kill a wedged instance + clear its Qt locks
    resolve-unstick -l     ...and relaunch

## Dead ends (already checked -- don't repeat)

- **`/opt/resolve/Certificates/Blackmagic.pem`**: genuinely has 30 expired certs and
  fails `curl`, but **Resolve never opens it**. strace shows it uses
  `/etc/ssl/certs/ca-certificates.crt`. Replacing it changes nothing.
- **Network / TLS**: `apps.cloud.blackmagicdesign.com` (Cloudflare) and the AWS
  us-east-2 licensing backend both resolve and accept 443 fine. Not the problem.
- **`/var/BlackmagicDesign/DaVinci Resolve/.migrated` ENOENT**: real, harmless,
  ignored. Not a launch blocker. No package creates that directory.
- **`pgrep -x resolve` returning nothing**: `-x` matches comm exactly, and Resolve's
  comm is `GUI Thread`. It was running the whole time. Use `pgrep -f`.

## Diagnosing

`strace -f -e trace=openat,connect,socket -o /tmp/r.strace /opt/resolve/bin/resolve`
Read the *true tail*, not the last failed syscall -- filtering for ENOENT/EACCES
hides the actual exit path.
