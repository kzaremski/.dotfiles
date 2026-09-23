-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Slide workspaces horizontally when switching.
--
-- Omarchy ships this animation DISABLED (see the default looknfeel.lua:
-- `hl.animation({ leaf = "workspaces", enabled = false })`), so without this
-- there is no workspace transition at all. This file loads after Omarchy's
-- defaults, so re-enabling it here wins.
--
-- "slide" is horizontal; Hyprland picks left/right automatically from the
-- direction you're travelling (the forced `slide left`/`slide right` variants
-- only apply to `windows` and `layers`, not `workspaces`).
--
-- Other styles: slidevert (vertical), fade, slidefade, slidefadevert.
-- All the slide* styles accept a travel percentage, e.g. style = "slide 20%"
-- to move only 20% of the screen width instead of a full page.
--
-- speed is duration in deciseconds (1 = 100ms); lower is snappier.
-- easeOutQuint is defined by Omarchy's defaults.
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
