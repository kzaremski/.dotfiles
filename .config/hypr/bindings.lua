-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Symbols picker (non-emoji: ™ © ° — ∑ → etc).
-- Omarchy's built-in picker on SUPER+CTRL+E is emoji-only; the symbol rows are
-- defined in ~/.config/omarchy/extensions/omarchy-menu.jsonc.
-- SUPER+CTRL+U because S/E and most other CTRL combos are already bound.
o.bind("SUPER + CTRL + U", "Symbols", "omarchy-menu summon trigger.symbols")

-- yazi, the TUI file manager, on the file-manager key.
--
-- Omarchy binds SUPER+SHIFT+F to nautilus by default; nautilus moves off this
-- key but stays on SUPER+ALT+SHIFT+F ("File manager (cwd)") and is still the
-- inode/directory handler. It is kept deliberately: it does gvfs
-- mounting/unmounting and shows Nextcloud sync-status overlays, neither of
-- which a terminal file manager can do.
--
-- { tui = ... } routes through omarchy-launch-tui -> xdg-terminal-exec, and
-- ~/.config/xdg-terminals.list lists foot.desktop first, so this opens in foot.
-- focus = true picks omarchy-launch-or-focus-tui, so pressing the key again
-- raises the existing window (app-id org.omarchy.yazi) instead of stacking new
-- ones. yazi has its own tabs (t) when more than one pane is wanted.
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager (yazi)", { tui = "yazi", focus = true })

-- Reload the Hyprland config without logging out.
--
-- Needed in particular after docking: monitors.lua gates the workspace pinning
-- on the dock's EDID, and that gate is only evaluated at config load. Plug the
-- dock in, hit this, and workspaces 1-5 / 6-10 pin to the two VE248s.
-- Also re-reads scale/transform, bindings, window rules and look-and-feel.
o.bind(
  "SUPER + SHIFT + R",
  "Reload Hyprland config",
  -- Outer DOUBLE quotes: o.notify single-quotes the message, and single quotes
  -- do not nest, so 'sh -c \'... \'msg\'\'' truncates it to the first word.
  'sh -c "hyprctl reload && ' .. o.notify("Hyprland config reloaded") .. '"' 
)

-- Rescue floating windows that have drifted off every screen.
--
-- A floating window holds absolute pixel coordinates, so unplugging a monitor
-- or changing the layout can leave one parked entirely in negative space: it
-- still shows in `hyprctl clients` and still takes keyboard focus, but no
-- monitor covers those coordinates so the mouse can never reach it. Happened
-- with Forza, which sat at x=-1760 after the internal panel went away.
--
-- Centres every floating window on the current workspace; pass --all to sweep
-- every workspace. Fullscreen windows are skipped -- Hyprland's center
-- dispatcher only acts on floating ones.
-- The script raises its own notification (--notify) rather than being wrapped
-- in `sh -c "... && " .. o.notify(...)`: o.notify single-quotes its message,
-- and nesting that inside a single-quoted sh -c ends the outer quote early, so
-- only the first word survives as the message.
o.bind("SUPER + CTRL + G", "Gather floating windows", "omarchy-center-floating --notify")

-- Free a stuck pointer grab: cursor moves but clicks land nowhere.
--
-- Happens two ways, and both need a REAL pointer event to clear -- a
-- synthetic focus change does nothing:
--   * a mouse replugged, or moved between dock ports, never gets pointer
--     focus, so buttons have no surface to go to;
--   * a fullscreen XWayland game (Project Zomboid, Resolve popups) holds a
--     grab and keeps it after focus leaves. hyprwm/Hyprland#3342, still open.
--
-- Touching the built-in touchpad works but means opening the lid. This emits
-- the same thing from a virtual uinput pointer, so it works from the keyboard
-- with the lid shut.
o.bind("SUPER + CTRL + M", "Unstick mouse", "omarchy-unstick-mouse")
