-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use natural (inverse) scrolling.
--       natural_scroll = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- Plain Caps Lock.
--
-- Omarchy's default is kb_options = "compose:caps,shift:both_capslock_cancel"
-- (see /usr/share/omarchy/default/hypr/input.lua), which turns Caps Lock into
-- the Compose key and moves Caps Lock itself onto "press both Shifts".
-- Clearing kb_options restores Caps Lock to being Caps Lock.
hl.config({
  input = {
    kb_layout = "us",
    kb_options = "",
  },
})

-- ---------------------------------------------------------------------------
-- GPD Pocket 4 touchscreen (NVTK0603:00 0603:F001, i2c)
--
-- The built-in LCD is rotated 270 deg (see hypr/monitors.lua). Hyprland does
-- NOT propagate a monitor's transform to touch input: `input.touchdevice
-- .transform` defaults to 0 regardless of how the output is rotated, so
-- without this the touch coordinates land 90 deg away from your finger.
--
-- This transform MUST stay in sync with the `transform` in hypr/monitors.lua.
-- If you ever change the panel rotation, change it in both places.
--
-- `output` is pinned to the panel as well. It defaults to auto-detection,
-- which can map the touchscreen onto an external display once one is plugged
-- in -- pinning it keeps touch on the screen you are actually touching.
--
-- Gated on the panel's EDID model so this file stays safe to carry to another
-- machine (same check as hypr/monitors.lua; duplicated so each file stands on
-- its own if one of them gets refreshed by Omarchy).
local function gpd_panel_connector()
  local cmd = [[for d in /sys/class/drm/card*-*; do ]]
    .. [[if grep -qa 'YHB03P24' "$d/edid" 2>/dev/null; then ]]
    .. [[basename "$d" | sed 's/^card[0-9]*-//'; break; fi; done]]
  local handle = io.popen(cmd)
  if not handle then return nil end
  local out = handle:read("*a") or ""
  handle:close()
  return out:match("^%s*(.-)%s*$")
end

local panel = gpd_panel_connector()
if panel and panel ~= "" then
  hl.config({
    input = {
      touchdevice = {
        output = panel,
        transform = 3,
      },
    },
  })
end
