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

-- Reload the Hyprland config without logging out.
--
-- Needed in particular after docking: monitors.lua gates the workspace pinning
-- on the dock's EDID, and that gate is only evaluated at config load. Plug the
-- dock in, hit this, and workspaces 1-5 / 6-10 pin to the two VE248s.
-- Also re-reads scale/transform, bindings, window rules and look-and-feel.
o.bind(
  "SUPER + SHIFT + R",
  "Reload Hyprland config",
  "sh -c 'hyprctl reload && " .. o.notify("Hyprland config reloaded") .. "'"
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
-- every workspace. Fullscreen windows are skipped -- Hyprland's centre
-- dispatcher only acts on floating ones.
o.bind(
  "SUPER + CTRL + G",
  "Gather floating windows",
  "sh -c 'omarchy-center-floating >/dev/null && " ..
    o.notify("Floating windows centred") .. "'"
)
