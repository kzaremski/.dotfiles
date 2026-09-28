# Displays: the dock chain, and how it fails

## Normal topology

    Pocket (or the MacBook) --Thunderbolt--> Belkin dock
        |
        +-- dock's other TB port --> J5Create USB-C-to-HDMI --> RIGHT VE248
        |                                                       serial HCLMQS071226
        +-- dock's DisplayPort ----> Insignia DP-to-HDMI
                                     --> HDMI cable ----------> LEFT VE248
                                                                serial F4LMQS087738

Both panels are identical ASUS VE248s, so the serial is the ONLY thing that
tells them apart. Connector names are worthless here: the same physical panel
has appeared as DP-6, DP-9, DP-10, DP-11 and DP-1 across reconnects. Every
rule in monitors.lua matches on `desc:` (which ends in the serial) for exactly
that reason.

Note both panels sit behind a protocol converter, and the dock is a third
device in the chain. That is a lot of retimers between GPU and glass, and it
is where every display fault so far has come from.

## Failure modes seen, with their signatures

**1. Link trains, but at the slowest rate.** Both panels attached, one lights
up and the other stays black.

    # debugfs, needs root
    cat /sys/kernel/debug/dri/*/DP-*/link_settings
    Current: 4  0x6   <- RBR, 1.62 Gbps/lane
    Verified: 4 0x1e  <- HBR3, 8.1 Gbps/lane, what it should be

RBR x4 = 5.18 Gbps usable. One 1920x1080@60 at 24bpp needs ~3.56 Gbps, so one
stream fits and two do not. The second panel gets no mode and Hyprland reports
it 0x0. Hyprland logs `atomic drm request: failed to commit: Invalid argument`
on every retry -- that is the symptom, not the cause.

**2. Link does not train at all.** Seen with the J5Create on a TB port:

    amdgpu [drm] *ERROR* LTTPR count is nonzero but invalid lane count reported

LTTPR is the retimer in the adapter. It announces repeaters, then reports a
lane count the driver rejects. Result:

    cat /sys/class/drm/card1-DP-1/modes   # EMPTY -- zero usable modes
    cat /sys/class/drm/card1-DP-1/edid    # empty too

With no modes there is nothing to set. No Hyprland setting can fix this.

**3. The whole tunnel collapses.** Jiggling the cable on 2026-09-27:

    amdgpu [drm] *ERROR* wait_for_completion_timeout   <- DMUB stopped answering
    thunderbolt 1-0:2.1: retimer disconnected
    pciehp Slot(0-1): Link Down / Card not present
    xhci_hcd 0000:63:00.0: remove

103 HPD interrupts in five minutes beforehand. The machine had to be held down
at the power button. This is a PCIe surprise-removal taking the dock's USB and
Ethernet with it, not a display bug.

## Telling a dead panel from an absent one

A panel can be plugged in, advertise valid EDID, and still carry no signal.
EDID presence is NOT liveness. DRM distinguishes them:

    live:  status=connected  enabled=enabled   dpms=On
    dead:  status=connected  enabled=disabled  dpms=Off

    for d in /sys/class/drm/*/; do
      grep -qa VE248 "$d/edid" 2>/dev/null &&
        echo "$(basename $d) $(cat $d/status) $(cat $d/enabled)"
    done

Hyprland's own view agrees -- a dead panel shows a `0x0` mode -- but
`hyprctl monitors` CANNOT be called from monitors.lua: Hyprland does not serve
IPC while parsing its config, so it returns nothing and every check silently
falls through. monitors.lua uses DRM sysfs for this; scripts outside the config
can use hyprctl freely.

## When a panel dies

    omarchy-displays-rehome     # move workspaces onto a monitor that can show them
    SUPER + SHIFT + R           # reload: re-decides the 1-5 / 6-10 split
    SUPER + CTRL + G            # recentre floating windows that drifted off-screen

`omarchy-monitor-watch` does the first two automatically on hotplug, but stands
down for five minutes if it sees more than 12 events in 60 seconds -- a
flapping link needs a cable, not more modesets.

## Dead ends / traps

* **Reload alone was blamed for not re-homing workspaces. It does re-home
  them.** It only looked otherwise because detection was returning the wrong
  answer, so the rules were being re-applied correctly to the wrong monitor.

* **The cold-boot guard must consider every output, not just the VE248s.**
  With one panel absent and one dead, neither reads "enabled", so a guard
  looking only at those two concludes it is at startup, trusts mere presence,
  and hands all ten workspaces to the dead panel -- leaving the working
  internal display on an empty ghost workspace.

* **A lone monitor must take the origin.** The right panel is normally at
  1920x0. Left there as the only display, nothing backs the 0..1920 range and
  anything placing a window at 0,0 -- plenty of XWayland apps -- lands
  unreachable.

* **`quiet loglevel=0` cannot be overridden by a drop-in.** omarchy-defaults
  .conf always lands last in the assembled cmdline, and it is not in pacman's
  backup list, so editing it is silently reverted on update. Do not bother:
  journald records everything regardless of console level, and when DMUB wedges
  the console cannot render anyway.

* **`hyprctl keyword` does not work on this build**, and neither does the bare
  `movewindowpixel exact X Y,class:...` form. See hypr.md.
