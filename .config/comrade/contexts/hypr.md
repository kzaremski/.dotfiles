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

## TRAP: persistent workspace rules claim numbers even when the monitor is absent

`persistent = true` creates the workspace **even when the monitor its rule names
is not attached** -- known upstream behavior (hyprwm/Hyprland#11758, #9947;
Waybar hits it too, Alexays/Waybar#3110).

Consequence here: pinning 1-5 and 6-10 to the two dock monitors by `desc:` meant
that undocked, all ten numbers were claimed by monitors that did not exist. The
built-in panel had no workspace rule of its own, so Hyprland allocated it the
first unclaimed number and **every undocked boot landed on workspace 11.**

That is worse than cosmetic: `bindings/tiling.lua` only generates SUPER+1..0, so
anything above 10 has **no keybinding, no bar entry and nothing to scroll to** --
a window opened there is invisible and unreachable.

Fix: gate the pinning block on the dock's EDID (`VE248`), the same way the panel
rule is gated on `YHB03P24`. Undocked the block is skipped, 1-10 stay unclaimed,
and the panel boots onto 1 like a normal single-monitor setup.

Limitation: evaluated at config load, so docking mid-session needs a
`hyprctl reload` before pinning applies.

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

## Cursor moves but clicks do nothing

TWO different faults share this symptom. They need different answers, and the
fix for one does NOT work on the other.

### 1. Replugged pointer never gets focus

Triggered by unplugging and replugging a mouse, including moving it between
ports on the dock.

Hyprland adds the device and renders its motion, but the seat never assigns
pointer FOCUS for it. Motion updates the cursor regardless of focus; button
events need a focused surface, so they go nowhere.

Cleared by one pointer event from any other device, or:

    omarchy-unstick-mouse            # SUPER+CTRL+M

### 2. XWayland app leaves clicks dead -- hyprwm/Hyprland#8146

NOT games specifically. Seen with Project Zomboid, Prey, TF2 **and DaVinci
Resolve**. The common factor is an XWayland app, not gaming. Games trigger it
more because of the sheer rate of input, not because they are games -- Resolve
took one odd interaction to do the same thing.

Clicks die everywhere afterward, not just in the app.

What the fault actually looks like, which is more specific than "no clicks":

    already-active mouse   moves the cursor, no clicks
    NEWLY plugged mouse    nothing at all -- no motion, no clicks
    trackpad (pre-existing) moves, clicks, AND fixes everything

So it is not "any pointer event clears it". A wedged seat will not accept NEW
pointer devices at all; what clears it is switching to a DIFFERENT,
ALREADY-REGISTERED device. Confirmed by plugging a second external mouse while
wedged: Hyprland listed it in `hyprctl devices` and it was completely inert,
while the original mouse still moved the cursor.

**omarchy-unstick-mouse CANNOT fix this**, and SUPER+CTRL+M will not help. It
works by creating a new virtual uinput pointer, which is exactly the class of
device a wedged seat ignores. The tool remains valid for fault 1 above.

Everything tried against a live fault that did NOT work:

  * omarchy-unstick-mouse / SUPER+CTRL+M (new device -- ignored)
  * a focus change (`hl.dsp.focus`)
  * a compositor-side cursor warp (`hl.dsp.cursor.move`)
  * moving the window between monitors (the workaround #8146 itself reports)
  * **software cursors** -- `cursor:no_hardware_cursors = true` was applied,
    the machine rebooted with it active, and the fault still occurred. The
    hardware cursor plane is NOT the cause here, whatever #8146 says.

The ONLY thing confirmed to clear it: **open the lid and move the built-in
trackpad.** Works every time.

### Do not chase these as hardware

Every obvious check comes back CLEAN in both cases:

    hyprctl devices          # the mouse IS listed
    hyprctl cursorpos        # returns sane, changing coordinates
    lsusb                    # device present
    hyprctl layers           # nothing but background + bar

Also not the cause, all checked: a stuck XWayland grab (killing Xwayland is
not even possible -- it is a Hyprland child and ignores SIGTERM), leftover
game processes, fcitx5, mixed DPI, and the dock.

