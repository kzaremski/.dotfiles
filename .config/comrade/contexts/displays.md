# Displays: the dock chain, and how it fails

## Normal topology

    Pocket (or the MacBook) --Thunderbolt--> Belkin dock
        |
        +-- dock's other TB port --> J5Create USB-C-to-HDMI --> RIGHT VE248
        |                                                       serial HCLMQS071226
        +-- dock's DisplayPort ----> DP-to-DVI --> DVI in ----> LEFT VE248
                                                                serial F4LMQS087738

Changed 2026-09-28: the left leg was dock DP -> Insignia DP-to-HDMI -> HDMI.
That leg, NOT the USB-C one, is what kept dropping -- see below.

Both panels are identical ASUS VE248s, so the serial is the ONLY thing that
tells them apart. Connector names are worthless here: the same physical panel
has appeared as DP-6, DP-9, DP-10, DP-11 and DP-1 across reconnects. Every
rule in monitors.lua matches on `desc:` (which ends in the serial) for exactly
that reason.

Note both panels sit behind a protocol converter, and the dock is a third
device in the chain. That is a lot of retimers between GPU and glass, and it
is where every display fault so far has come from.

## Which leg actually fails

The LEFT panel is the one that drops, repeatedly, and the right has stayed up
through all of it. Every dead-panel observation on 2026-09-27/28 was
F4LMQS087738 sitting at 0x0 -- as DP-10, then DP-11 -- while HCLMQS071226 kept
working. The left ran through the dock's DisplayPort output and an Insignia
DP-to-HDMI adapter; that adapter has been replaced with a DP-to-DVI into the
monitor's DVI input, and the leg is now on trial.

Do not let the USB-C leg take the blame for this. The J5Create's Billboard
refusal happened only when it was plugged DIRECTLY into the Pocket, which is a
separate fault (see below). Through the dock, that leg has been the reliable
one.

Link rate is NOT a good predictor of which leg fails:

    LEFT  (DP -> DVI)      Current 4 @ 0xa  == Verified 4 @ 0xa   full capability
    RIGHT (TB -> J5Create) Current 4 @ 0x6  vs Verified 4 @ 0x1e  one fifth

The right trains at a fifth of its capability and has been stable; the left
trained at full capability and died anyway. RBR is a sign of a marginal link,
not proof that it is the failing one. 5.18 Gbps still carries one 1920x1080@60
stream (3.56 Gbps) with room to spare, and the two panels are on SEPARATE
links -- they do not share a bandwidth budget, so "two streams will not fit"
reasoning does not apply here.

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

## USB-C direct to a monitor: check for a Billboard Device first

If an external panel plugged straight into the Pocket shows nothing, check
what the adapter enumerated as BEFORE investigating anything about the GPU:

    lsusb | grep -i billboard

    0bda:2172 Realtek Semiconductor Corp. BillBoard Device

A USB Billboard Device is the spec-defined way an adapter reports that
**alternate mode entry FAILED**. The adapter asked for DisplayPort alt mode,
the port refused, and it fell back to announcing exactly that. No DP link is
ever offered, so:

  * a replug produces USB enumeration events and NO drm/hotplug activity;
  * the connector may still read `connected` with a full mode list, stale from
    an earlier session, while `enabled` stays `disabled`;
  * `link_settings` shows `Current: 0 lanes` against a healthy
    `Verified: 4 0x1e`, which looks like a training failure but is really
    "never attempted";
  * Hyprland walks every mode from 1920x1080 down to 720x400, each failing.

This is NOT "the port has no DisplayPort". The port in question is the very
one the Belkin dock runs on, driving two panels. The two get video through
the port by different means:

  * the dock is a Thunderbolt/USB4 device and its video is DP **tunnelled**
    over USB4, negotiated as part of Thunderbolt;
  * a plain adapter like the J5Create wants DisplayPort **alt mode**, where
    the port remuxes its lanes to carry native DP.

The port grants the first and refuses the second, which is what the Billboard
Device reports. A Mac does both, which is why the identical adapter and panel
lit up there immediately.

So for a direct-to-monitor connection on this machine, prefer a Thunderbolt or
USB4 display adapter over a DP-alt-mode one -- or just use the dock, which
already works. Do not go hunting the cable, the adapter, the monitor or the
driver: all four were chased here first, and all four were fine.

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
