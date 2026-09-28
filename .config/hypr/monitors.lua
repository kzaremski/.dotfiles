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
local left_serial = "F4LMQS087738"
local right_serial = "HCLMQS071226"
local dock_left = "desc:Ancor Communications Inc VE248 " .. left_serial
local dock_right = "desc:Ancor Communications Inc VE248 " .. right_serial

-- Is a display carrying this EDID string attached right now?
--
-- Gated on EDID rather than connector name for the same reason the rules match
-- on `desc:`. Note the dock's panels do not appear under the internal GPU's
-- connectors; they arrive on their own DRM card, so the glob has to span
-- card*-* rather than naming one.
local function edid_present(needle)
  local cmd = [[for d in /sys/class/drm/card*-*; do ]]
    .. [[if grep -qa ']] .. needle .. [[' "$d/edid" 2>/dev/null; then ]]
    .. [[echo yes; break; fi; done]]
  local handle = io.popen(cmd)
  if not handle then return false end
  local out = handle:read("*a") or ""
  handle:close()
  return out:match("yes") ~= nil
end

-- Is the panel with this serial actually usable right now?
--
-- EDID presence alone is not enough. This dock can leave a panel plugged in
-- and still advertising its EDID while carrying no video signal. DRM tells
-- the two apart:
--
--   live:  status=connected  enabled=enabled   dpms=On
--   dead:  status=connected  enabled=disabled  dpms=Off
--
-- Trusting EDID pinned workspaces 1-5 to a black screen -- one of them holding
-- a window -- while the overflow landed on a ghost workspace 11.
--
-- Hyprland's own view would be the authority here, but `hyprctl monitors`
-- cannot be called from this file: Hyprland does not serve IPC while it is
-- parsing its config, so the call returns nothing and every panel silently
-- looks attached. Verified by probe -- during a reload the command yields no
-- output at all. DRM sysfs has no such problem.
local function drm_enabled(serial)
  local cmd = [[for d in /sys/class/drm/*/; do ]]
    .. [[if grep -qa ']] .. serial .. [[' "$d/edid" 2>/dev/null; then ]]
    .. [[cat "$d/enabled" 2>/dev/null; break; fi; done]]
  local handle = io.popen(cmd)
  if not handle then return nil end
  local out = handle:read("*a") or ""
  handle:close()
  out = out:match("^%s*(.-)%s*$")
  if out == "" then return nil end
  return out
end

local left_state = drm_enabled(left_serial)
local right_state = drm_enabled(right_serial)

-- On the very first parse Hyprland has not configured any output yet, so every
-- connector reads "disabled" and the signal carries no information. Only trust
-- it once something is actually lit; before that, fall back to mere presence,
-- which is the old behaviour and correct for a normal docked boot.
--
-- This must consider EVERY output, not just the two dock panels. Asking only
-- about the VE248s gets it exactly backwards in the case that matters: with
-- one panel absent and the other connected-but-dead, neither reads "enabled",
-- the check concludes it is looking at a cold boot, falls back to presence and
-- hands all ten workspaces to the dead panel -- while the internal display,
-- which is lit and working, sits on a ghost workspace showing an empty desktop.
local function any_output_enabled()
  local handle = io.popen([[grep -lx enabled /sys/class/drm/*/enabled 2>/dev/null | head -1]])
  if not handle then return false end
  local out = handle:read("*a") or ""
  handle:close()
  return out:match("%S") ~= nil
end

local any_enabled = any_output_enabled()

local function panel_usable(state)
  if state == nil then return false end
  if any_enabled then return state == "enabled" end
  return true
end

local have_left = panel_usable(left_state)
local have_right = panel_usable(right_state)

-- The left panel anchors the desktop at the origin. The right one sits beside
-- it normally, but takes the origin itself when the left is missing: a lone
-- monitor parked at 1920x0 leaves the whole 0..1920 range with no screen
-- behind it, and anything that naively places a window at 0,0 -- which plenty
-- of XWayland apps do -- lands somewhere unreachable.
--
-- Both rules are emitted unconditionally even when that monitor is absent, so
-- a panel that appears mid-session still gets its scale and position. Only the
-- chosen coordinates depend on what was attached at config load.
hl.monitor({
  output = dock_left,
  mode = "preferred", position = "0x0", scale = 1,          -- LEFT
})
hl.monitor({
  output = dock_right,
  mode = "preferred",
  position = have_left and "1920x0" or "0x0",               -- RIGHT
  scale = 1,
})

-- Pin workspaces to specific monitors at the docking station.
--
-- Both panels attached: 1-5 on the LEFT, 6-10 on the RIGHT (the bar renders
-- workspace 10 as "0", so that row reads 6 7 8 9 0).
--
-- Only ONE attached: all ten go to whichever survived. This dock drops a panel
-- when it heats up, and splitting the range in that state stranded half the
-- workspaces -- persistent = true still creates them, so 6-10 existed but sat
-- on a monitor that was gone, reachable by SUPER+6..0 yet displayed nowhere.
--
-- persistent = true keeps each workspace alive even when empty, so they always
-- appear in that monitor's bar row rather than popping in and out.
-- default = true makes that workspace the one the monitor lands on.
--
-- Neither attached: no rules at all. persistent = true creates the workspace
-- even when the monitor its rule names is absent -- known Hyprland behaviour
-- (hyprwm/Hyprland#11758, #9947; Waybar hits it too, Alexays/Waybar#3110).
-- Undocked, these rules therefore claimed 1-10 for monitors that do not exist,
-- leaving the built-in panel with no workspace of its own: Hyprland allocated
-- it the first unclaimed number and every undocked boot landed on workspace 11.
-- Anything above 10 is unreachable (bindings/tiling.lua only generates
-- SUPER+1..0), so windows opened there were effectively lost. Skipping the
-- block entirely leaves 1-10 unclaimed and the panel boots onto workspace 1.
--
-- With a single monitor the bar hides empty slots anyway -- see laptopMode in
-- ~/.config/omarchy/plugins/kzaremski.workspaces/Workspaces.qml -- so all ten
-- being pinned does not fill the row with blanks.
--
-- Limitation: evaluated at config load. Docking, undocking or losing a panel
-- mid-session does not re-run it, so the layout only follows from the next
-- `hyprctl reload` (SUPER+SHIFT+R) or next login.
local function pin_range(first, last, monitor, default_ws)
  for ws = first, last do
    hl.workspace_rule({
      workspace = tostring(ws),
      monitor = monitor,
      persistent = true,
      default = ws == default_ws,
    })
  end
end

if have_left and have_right then
  pin_range(1, 5, dock_left, 1)
  pin_range(6, 10, dock_right, 6)
elseif have_left then
  pin_range(1, 10, dock_left, 1)
elseif have_right then
  pin_range(1, 10, dock_right, 1)
end
