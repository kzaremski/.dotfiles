-- Konstantin Zaremski's WezTerm Configuration
-- Last updated: October 11, 2025

local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- ==================
-- FONT CONFIGURATION
-- ==================

-- Font configuration with fallbacks
-- First try Nerd Font version (has icons), fallback to regular Cascadia,
-- then use WezTerm's built-in glyphs for any missing symbols
config.font = wezterm.font_with_fallback({
  'CaskaydiaCove Nerd Font Mono',  -- Nerd Font on macOS
  'CaskaydiaCove Nerd Font',       -- Nerd Font on Linux
  'Cascadia Mono',                 -- Regular Cascadia (fallback)
  'Cascadia Code',                 -- Another fallback
  'Menlo',                         -- macOS system monospace
  'Symbols Nerd Font Mono',        -- Nerd Font symbols
  -- WezTerm's built-in fallback fonts automatically used for missing glyphs
})
config.font_size = 12.5

-- Font rendering (better for macOS)
config.freetype_load_target = "Normal"
config.freetype_render_target = "HorizontalLcd"

-- Disable ligatures if they're causing issues
-- config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- ==================
-- APPEARANCE
-- ==================

-- Use a dark theme similar to macOS Terminal "Pro"
-- Colors based on macOS Pro theme
config.colors = {
  foreground = '#f0f0f0',
  background = '#000000',

  cursor_bg = '#4ae0aa',
  cursor_fg = '#000000',
  cursor_border = '#4ae0aa',

  selection_fg = '#000000',
  selection_bg = '#4ae0aa',

  scrollbar_thumb = '#222222',

  split = '#444444',

  ansi = {
    '#000000',  -- black
    '#cc0000',  -- red
    '#4ae0aa',  -- green (Pro theme green)
    '#d7af5f',  -- yellow
    '#5496ff',  -- blue
    '#c678dd',  -- magenta
    '#00d7ff',  -- cyan
    '#ffffff',  -- white
  },

  brights = {
    '#767676',  -- bright black (gray)
    '#f54444',  -- bright red
    '#5fd787',  -- bright green
    '#ffd75f',  -- bright yellow
    '#5fafd7',  -- bright blue
    '#d787d7',  -- bright magenta
    '#5fd7ff',  -- bright cyan
    '#ffffff',  -- bright white
  },
}

-- Window background opacity and blur (macOS only)
config.window_background_opacity = 0.80
config.macos_window_background_blur = 20

-- ==================
-- WINDOW SETTINGS
-- ==================

-- Native macOS decorations
config.window_decorations = "RESIZE"

-- Padding around the terminal content
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- ==================
-- TAB BAR
-- ==================

-- Hide tab bar when only one tab is open
config.hide_tab_bar_if_only_one_tab = true

-- Use fancy tab bar (native macOS style)
config.use_fancy_tab_bar = true

-- Tab bar colors with font fallback
config.window_frame = {
  font = wezterm.font_with_fallback({
    { family = 'CaskaydiaCove Nerd Font Mono', weight = 'Bold' },
    { family = 'CaskaydiaCove Nerd Font', weight = 'Bold' },
    { family = 'Cascadia Mono', weight = 'Bold' },
    { family = 'Menlo', weight = 'Bold' },
  }),
  font_size = 11.0,
  active_titlebar_bg = '#000000',
  inactive_titlebar_bg = '#000000',
}

-- ==================
-- BEHAVIOR
-- ==================

-- Scrollback
config.scrollback_lines = 10000

-- Cursor (standard non-blinking block)
config.default_cursor_style = 'SteadyBlock'

-- Mouse bindings
config.mouse_bindings = {
  -- Paste on right click
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
}

-- ==================
-- KEY BINDINGS
-- ==================

config.keys = {
  -- Split panes
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Shift+Enter sends escape sequence (for Claude Code)
  {
    key = 'Enter',
    mods = 'SHIFT',
    action = wezterm.action.SendString '\x1b\r',
  },
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Close pane
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- Navigate panes
  {
    key = 'LeftArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  {
    key = 'UpArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CMD|ALT',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  -- Toggle fullscreen
  {
    key = 'Enter',
    mods = 'CMD|CTRL',
    action = wezterm.action.ToggleFullScreen,
  },
}

-- ==================
-- PERFORMANCE
-- ==================

-- Enable GPU acceleration
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"

-- Text rendering improvements
config.line_height = 1.0
config.cell_width = 1.0

-- Better rendering for transparent backgrounds
config.text_background_opacity = 1.0

return config
