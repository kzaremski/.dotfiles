# i3 Keybindings Reference

Mod key: `Mod4` (Super/Windows key)

## Applications

| Key               | Action                          |
|-------------------|---------------------------------|
| Mod+Return        | Terminal (kitty)                |
| Mod+Shift+Return  | VSCode (new window)             |
| Mod+d             | dmenu launcher                  |
| Mod+Shift+d       | Docs/reference selector         |
| Mod+Ctrl+d        | Script selector                 |
| Mod+F1            | File manager (PCManFM)          |
| Mod+Shift+F1      | Advanced file manager (Krusader)|
| Mod+Ctrl+F1       | TUI file manager (ranger)       |
| Mod+F2            | Firefox                         |
| Mod+Shift+F2      | Firefox (private window)        |
| Mod+F3            | Thunderbird                     |
| Mod+F4            | LibreOffice                     |
| Mod+Shift+F5      | Captive portal (surf)           |
| Mod+F10           | KeePassXC password manager      |
| Mod+F12           | htop                            |
| Mod+Shift+F12     | bpytop                          |

## Window Management

| Key                  | Action                        |
|----------------------|-------------------------------|
| Mod+Shift+q          | Kill focused window           |
| Mod+j / Mod+Left     | Focus left                    |
| Mod+k / Mod+Down     | Focus down                    |
| Mod+l / Mod+Up       | Focus up                      |
| Mod+; / Mod+Right    | Focus right                   |
| Mod+Shift+j          | Move window left              |
| Mod+Shift+k          | Move window down              |
| Mod+Shift+l          | Move window up                |
| Mod+Shift+;          | Move window right             |
| Mod+Shift+Arrow      | Move window (arrow keys)      |
| Mod+a                | Focus parent container        |
| Mod+f                | Toggle fullscreen             |
| Mod+Shift+Space      | Toggle floating               |
| Mod+Space            | Toggle focus (tiling/floating)|

## Layout

| Key       | Action                     |
|-----------|----------------------------|
| Mod+h     | Split horizontal           |
| Mod+v     | Split vertical             |
| Mod+q     | Toggle split direction     |
| Mod+s     | Stacking layout            |
| Mod+w     | Tabbed layout              |
| Mod+e     | Toggle split layout        |

## Workspaces

| Key            | Action                              |
|----------------|-------------------------------------|
| Mod+1-0        | Switch to workspace 1-10            |
| Mod+Shift+1-0  | Move window to workspace (& follow) |

Workspace assignment:
- Workspaces 1-4: Primary monitor
- Workspaces 5-10: VGA-1 (secondary)

## Resize Mode

Enter with `Mod+r`, exit with `Return` or `Escape`

| Key                | Action              |
|--------------------|---------------------|
| j / Left           | Shrink width        |
| k / Down           | Grow height         |
| l / Up             | Shrink height       |
| ; / Right          | Grow width          |

## System Mode

Enter with `Mod+Shift+e`, exit with `Return` or `Escape`

| Key      | Action         |
|----------|----------------|
| l        | Lock (i3lock)  |
| s        | Suspend        |
| e        | Exit i3        |
| r        | Reboot         |
| Shift+s  | Shutdown       |

## i3 Management

| Key           | Action                    |
|---------------|---------------------------|
| Mod+Shift+c   | Reload config             |
| Mod+Shift+r   | Restart i3 (preserves session) |

## Display

| Key           | Action                           |
|---------------|----------------------------------|
| Mod+F7        | Screen layout selector           |
| Mod+Shift+F7  | Reset to laptop display          |
| Shift+F7      | Reset wallpaper                  |

## Media Keys

| Key                  | Action                    |
|----------------------|---------------------------|
| XF86AudioRaiseVolume | Volume up (+10%)          |
| XF86AudioLowerVolume | Volume down (-10%)        |
| XF86AudioMute        | Toggle mute               |
| XF86AudioMicMute     | Toggle mic mute           |
| XF86AudioPlay/Pause  | Play/pause media          |
| XF86AudioNext        | Next track                |
| XF86AudioPrev        | Previous track            |
| XF86MonBrightnessUp  | Brightness up (+10%)      |
| XF86MonBrightnessDown| Brightness down (-10%)    |
| XF86ScreenSaver      | Lock screen               |
| XF86Launch1          | Sync buffers (ThinkPad)   |

## Screenshots (maim)

| Key               | Action                          |
|-------------------|---------------------------------|
| Print             | Screenshot (full screen)        |
| Mod+Print         | Screenshot (active window)      |
| Shift+Print       | Screenshot (selection)          |
| Ctrl+Print        | Screenshot to clipboard         |
| Ctrl+Mod+Print    | Window screenshot to clipboard  |
| Ctrl+Shift+Print  | Selection to clipboard          |

Screenshots saved to `~/Pictures/Screenshot <ISO-8601-datetime>.png`
Example: `Screenshot 2024-06-28T14:30:00-04:00.png`

## Startup Applications

These run automatically when i3 starts:
- feh (wallpaper)
- picom (compositor)
- xss-lock + i3lock (screen locker)
- nm-applet (NetworkManager tray)
- blueman-applet (Bluetooth tray)
- pasystray (PulseAudio tray)
- nextcloud (sync client)
- dex (XDG autostart)

## Appearance

- Font: CaskaydiaCove Nerd Font 10
- Gaps: 8px inner, 0px outer
- Status bar: i3status
