# Epson Perfection V39 II (USB 04b8:013f)

Works. Driver is `epsonscan2` from the AUR -- NOT plain SANE, and NOT iscan.

## Why plain SANE does not see it

No SANE backend handles this model. `scanimage -L` finds nothing, and forcing
the id into epson2.conf or epsonds.conf does not help: the device needs a
firmware upload before its scan engine exists at all.

The V39 II is NOT the V39 in a new case. Different product id (013f), different
firmware (esfw0282.bin). Guides written for the V39 do not apply, and iscan
predates this model entirely.

## Install

The AUR PKGBUILD patches this model in by product id explicitly:

    else if (dd.idProduct == 0x13F)
        sprintf(..., "Perfection V39II");

Build deps are awkward: `qt5-singlecoreapplication` has no AUR repo of its own
-- it is a split output of pkgbase `qt5-singleapplication`, so clone THAT.
Cloning the subpackage name gives an empty repository.

## THE TRAP: replug after installing

The firmware is uploaded by a udev rule when the device CONNECTS:

    ATTRS{idProduct}=="013f", ENV{epsonscan2_driver}="esci",
                              ENV{firmware_file}="esfw0282.bin"

Install the driver with the scanner already plugged in and that rule never
fires for it. The symptom is precise and misleading:

  * `scanimage -L` lists the scanner correctly, by name, over esci2;
  * opening it for an actual scan fails with `Error during device I/O`.

Enumerating but not scanning means NO FIRMWARE. Unplug and replug the USB
cable; a real add event fires the rule. `udevadm trigger` is not reliably
enough. No firmware extraction is needed -- the package ships all six
esfw*.bin blobs, including this one, at /usr/share/epsonscan2/.

## Permissions

epsonscan2's own rule sets MODE="0666", i.e. world-writable to every local
process. root/etc/udev/rules.d/60-epson-v39ii.rules sorts before it and uses
MODE="0664" + TAG+="uaccess" so only the logged-in seat owner gets it. Check
with `ls -l /dev/bus/usb/<bus>/<dev>` -- a trailing `+` means the ACL applied.

Without any rule the node is `crw-rw-r-- root root`: readable but not
writable, and libusb needs write for control transfers. sanei_usb then skips
EVERY usb device, not just this one:

    sanei_usb: skipping device 0x04b8/0x013f: cannot open: Access denied

## Scanning

    scanimage -L                       # get the device string
    scanimage -d '<device string>' --resolution 75 --mode Grayscale \
              --format=png -o out.png

`--mode` takes Color|Grayscale|Monochrome. "Gray" is rejected. Resolution goes
to 9600dpi; default is 200.

Do NOT pipe scanimage's stdout through `head`/`tail` -- SIGPIPE aborts the
scan mid-transaction and leaves the device wedged, which then looks exactly
like the missing-firmware failure above. Redirect to a file instead.
