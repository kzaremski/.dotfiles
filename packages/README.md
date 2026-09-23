# Package lists

Regenerate with `dotfiles-packages --save`, install with `dotfiles-packages --install`.

- `repo.txt` — explicitly-installed packages from the official repos (`pacman -Qqen`)
- `aur.txt`  — explicitly-installed AUR packages (`pacman -Qqem`)

Both are *explicit* installs only, so dependencies are omitted and pacman pulls
them back automatically. Installing uses `--needed`, so anything the Omarchy ISO
already provides is skipped.

## AUR packages that need a human

**davinci-resolve-studio** — the PKGBUILD takes a local
`DaVinci_Resolve_Studio_<ver>_Linux.zip` (~11 GB) that cannot be downloaded
automatically; sign in at blackmagicdesign.com and drop it in the build dir.
After installing, run `pkexec resolve-perms "$USER"` — the package ships
`.license`, `Extras`, `LUT` and `Fusion/LUTs` as root:root, and an unwritable
`.license` makes activation fail with "Cannot validate license key".
See `.config/comrade/contexts/resolve.md`.

**libfprint-ft9201** — the proprietary driver for the GPD Pocket 4's FocalTech
reader (2808:0752). Stock `libfprint` has no driver for it. This package must
keep `libfprint-git` in its `provides`, or `omarchy setup security fingerprint`
will uninstall it.

**apfs-fuse-git** — needed to read the Mac backup SSD. Mount read-only.

## Not captured here, and not capturable

Fingerprint enrolment (re-enrol), Tailscale node auth (re-auth), SSH/GPG keys
(restore from your own secure backup), DaVinci Resolve activation (re-activate),
ollama models (re-pull, ~9 GB).
