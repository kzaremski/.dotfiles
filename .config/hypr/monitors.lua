-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- GPD Pocket 4 built-in panel.
--
-- The LCD is natively portrait (1600x2560) and physically mounted sideways,
-- so it needs transform 3 (270 deg) to read as landscape. That rotation and
-- the 2x scale are specific to this hardware and must never leak onto an
-- external monitor.
--
-- Instead of hardcoding "eDP-1" (the connector name every laptop's internal
-- panel uses), find the connector whose EDID advertises this panel's model.
-- On any other machine the model string is absent, no rule is emitted, and
-- every display just gets Hyprland's defaults -- so this file is safe to
-- carry to another system as-is.
--
-- Deliberately NO catch-all `output = ""` rule here. In Hyprland 0.56.2 a
-- catch-all is re-applied to ALREADY-CONNECTED monitors when a display is
-- hotplugged, which overwrites this panel's scale (dropping it to 1 and
-- making everything tiny) while leaving the rotation in place. Verified on
-- 0.56.2. Unmatched external monitors fall back to Hyprland's own defaults,
-- which is the behaviour a catch-all would have provided anyway.
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
  hl.monitor({
    output = panel,
    mode = "preferred",
    position = "auto",
    scale = omarchy_monitor_scale,
    transform = 3,
  })
end

-- If an external monitor comes up at the wrong scale, give it its own rule
-- matched on description (see `hyprctl monitors` for the exact string), e.g.
-- hl.monitor({ output = "desc:Dell Inc. DELL U2415 ...", mode = "preferred",
--              position = "auto", scale = 1 })

-- Home docking station: two identical ASUS VE248 panels.
--
-- They are the same make+model, so the ONLY thing that tells them apart is the
-- serial, which is the last field of the description string. Connector names
-- (DP-6 / DP-9) are not stable -- they depend on plug order and which port the
-- dock enumerates first, which is exactly why they came up swapped.
-- Matching on the full description pins each physical panel to a fixed side
-- regardless of plug order.
--
-- Run `hyprctl monitors` and read the `description:` line to get these strings.
hl.monitor({
  output = "desc:Ancor Communications Inc VE248 F4LMQS087738",
  mode = "preferred", position = "0x0", scale = 1,      -- LEFT
})
hl.monitor({
  output = "desc:Ancor Communications Inc VE248 HCLMQS071226",
  mode = "preferred", position = "1920x0", scale = 1,   -- RIGHT
})

-- Pin workspaces to specific monitors at the docking station.
--
-- 1-5 on the LEFT panel, 6-10 on the RIGHT (the bar renders workspace 10 as
-- "0", so that row reads 6 7 8 9 0).
--
-- Matched by `desc:` (which ends in the serial) for the same reason the
-- position rules are: both monitors are identical ASUS VE248s, and DP-6 /
-- DP-9 swap around with plug order.
--
-- persistent = true keeps each workspace alive even when empty, so they always
-- appear in that monitor's bar row rather than popping in and out.
-- default = true makes that workspace the one the monitor lands on.
--
-- Undocked, these descriptions match no connected output, but the rules are
-- NOT simply skipped: persistent = true still creates all ten workspaces, and
-- Hyprland falls them back onto the only monitor that does exist. Verified on
-- 0.56.2 -- `hyprctl workspaces` lists 1-10 on eDP-1 with no dock attached.
--
-- That would leave the bar showing ten slots, seven of them empty, so the
-- workspace widget hides empty ones when a single monitor is connected. See
-- laptopMode in ~/.config/omarchy/plugins/kzaremski.workspaces/Workspaces.qml.
local dock_left = "desc:Ancor Communications Inc VE248 F4LMQS087738"
local dock_right = "desc:Ancor Communications Inc VE248 HCLMQS071226"

-- Only pin when the dock is actually attached.
--
-- persistent = true creates the workspace even when the monitor its rule names
-- is absent -- known Hyprland behaviour (hyprwm/Hyprland#11758, #9947; Waybar
-- hits it too, Alexays/Waybar#3110). Undocked, these rules therefore claimed
-- 1-10 for monitors that do not exist, leaving the built-in panel with no
-- workspace of its own: Hyprland allocated it the first unclaimed number and
-- every undocked boot landed on workspace 11. Anything above 10 is unreachable
-- (bindings/tiling.lua only generates SUPER+1..0), so windows opened there were
-- effectively lost.
--
-- Gated on the VE248 EDID the same way the panel rule is gated on YHB03P24.
-- Undocked this block is skipped entirely, 1-10 stay unclaimed, and the panel
-- boots onto workspace 1 like any normal single-monitor setup.
--
-- Limitation: evaluated at config load. Docking mid-session does not re-run it,
-- so pinning only applies from the next `hyprctl reload` (or next login).
local function dock_present()
  local cmd = [[for d in /sys/class/drm/card*-*; do ]]
    .. [[if grep -qa 'VE248' "$d/edid" 2>/dev/null; then echo yes; break; fi; done]]
  local handle = io.popen(cmd)
  if not handle then return false end
  local out = handle:read("*a") or ""
  handle:close()
  return out:match("yes") ~= nil
end

if dock_present() then

for ws = 1, 5 do
  hl.workspace_rule({
    workspace = tostring(ws),
    monitor = dock_left,
    persistent = true,
    default = ws == 1,
  })
end

for ws = 6, 10 do
  hl.workspace_rule({
    workspace = tostring(ws),
    monitor = dock_right,
    persistent = true,
    default = ws == 6,
  })
end

end -- dock_present()
