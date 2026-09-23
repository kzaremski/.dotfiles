# Omarchy Hyprland config: Lua, not .conf

**Critical:** this machine configures Hyprland in **Lua**, not the classic
`hyprland.conf` syntax. Any answer using `bind = SUPER, Q, killactive` or
`monitor = eDP-1,preferred,auto,1` is WRONG here. Do not suggest it.

Likewise `hyprctl keyword ...` does NOT work on this build. To drive Hyprland
from the shell, pass Lua to the dispatcher:

    hyprctl dispatch 'hl.dsp.focus({ workspace = "1" })'

## File layout

    ~/.config/hypr/
      hyprland.lua    # entry point; loads Omarchy defaults then the files below
      bindings.lua    # keybindings
      monitors.lua    # displays + workspace pinning
      input.lua       # keyboard/mouse/touch
      looknfeel.lua   # gaps, borders, animations
      autostart.lua   # startup apps

Omarchy's own defaults (read-only reference, never edit):
`/usr/share/omarchy/default/hypr/*.lua`

## Helper API (`o.*`, from default/hypr/helpers.lua)

    o.bind(keys, description, dispatcher, options)
    o.bind_toggle(keys, description, toggle, options)
    o.window(match, rules)          -- match as string = class
    o.launch(command)               -- wraps with "uwsm-app --"
    o.launch_on_start(command)
    o.launch_webapp(url) / o.launch_webapp_sole(name, url)
    o.launch_sole(match, command)
    o.exec_on_start(command)
    o.notify(message)
    o.shell_quote(v) / o.shell_succeeds(cmd) / o.cmd_present(cmd) / o.cmd_missing(cmd)

A string dispatcher is auto-wrapped in `hl.dsp.exec_cmd`.

## Core API (`hl.*`)

    hl.bind / hl.unbind
    hl.monitor{ output, mode, position, scale, transform }
    hl.workspace_rule{ workspace, monitor, persistent, default }
    hl.window_rule / hl.layer_rule
    hl.env(name, value)
    hl.animation{ leaf, enabled, speed, bezier, style }
    hl.curve / hl.config / hl.get_config
    hl.exec_cmd / hl.dispatch / hl.on / hl.timer
    hl.device / hl.gesture
    hl.get_active_window

## Dispatchers (`hl.dsp.*`)

    hl.dsp.focus{ workspace = "1" | "e+1" | "e-1" }
    hl.dsp.exec_cmd(cmd)
    hl.dsp.layout(...)
    hl.dsp.send_key_state(...)
    hl.dsp.window.close / .move / .resize / .drag / .swap
    hl.dsp.window.float / .fullscreen / .pseudo
    hl.dsp.window.bring_to_top / .cycle_next
    hl.dsp.workspace.move{ monitor = "l"|"r"|"u"|"d" }
    hl.dsp.workspace.toggle_special
    hl.dsp.group.toggle / .next / .prev / .active

## Examples (real, from this system)

    o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh host")
    o.bind("SUPER + B", "Browser", { launch = "chromium" })
    o.bind("SUPER + CTRL + U", "Symbols", "omarchy-menu summon trigger.symbols")
    hl.unbind("SUPER + F")        -- ALWAYS unbind before rebinding an existing key

    hl.monitor({ output = "eDP-1", mode = "preferred",
                 position = "auto", scale = 2, transform = 3 })

    hl.workspace_rule({ workspace = "1", monitor = "desc:Some Monitor SERIAL",
                        persistent = true, default = true })

    hl.animation({ leaf = "workspaces", enabled = true, speed = 5,
                   bezier = "easeOutQuint", style = "slide" })

## Monitor transform values

    0 = no rotation        4 = flipped
    1 = 90 deg             5 = flipped + 90
    2 = 180 deg            6 = flipped + 180
    3 = 270 deg            7 = flipped + 270

`transform = 3` is 270 degrees clockwise (equivalently 90 counter-clockwise).
That is the value this machine's built-in panel needs.

## Hard-won gotchas on this machine (Hyprland 0.56.2)

- **Never add a catch-all `hl.monitor({ output = "" })` rule.** On hotplug it is
  re-applied to already-connected monitors and clobbers the built-in panel's
  scale (drops it to 1) while leaving the rotation. Unmatched monitors fall back
  to Hyprland's defaults, which is what a catch-all would have given anyway.
- **`persistent = true` workspace rules still create the workspace when the named
  monitor is absent** -- Hyprland falls it back onto whatever output exists. It
  does NOT skip the rule. Undocked this yields ten workspaces on the panel.
- The built-in GPD Pocket 4 panel is natively portrait and needs `transform = 3`
  on BOTH the monitor rule and the touchscreen device rule.
- Validate every config change with `hyprctl reload` then `hyprctl configerrors`.
