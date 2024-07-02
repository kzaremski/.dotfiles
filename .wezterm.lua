local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font_size = 10.0
config.font = wezterm.font 'CaskaydiaCove Nerd Font'

config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

return config

