#!/bin/bash
# android.sh - Control internally mounted Android device
# Usage: android.sh [wake|sleep|lock|unlock|shutdown|reboot|scrcpy|status|menu]

DEVICE_SERIAL="${ANDROID_SERIAL:-}"
DMENU_FONT="Terminus-10"

adb_cmd() {
    if [[ -n "$DEVICE_SERIAL" ]]; then
        adb -s "$DEVICE_SERIAL" "$@"
    else
        adb "$@"
    fi
}

check_device() {
    if ! adb_cmd get-state &>/dev/null; then
        echo "Error: No Android device connected"
        exit 1
    fi
}

show_menu() {
    local options="scrcpy
wake
sleep
unlock
screenshot
status
reboot
shutdown
recovery
bootloader
shell"
    local choice=$(echo "$options" | dmenu -i -l 10 -p "Android:" -fn "$DMENU_FONT")
    [[ -n "$choice" ]] && exec "$0" "$choice"
}

case "${1:-}" in
    "")
        # No argument: show dmenu if available, otherwise status
        if [ -n "$DISPLAY" ] && command -v dmenu &> /dev/null; then
            show_menu
        else
            exec "$0" status
        fi
        ;;
    menu|dmenu)
        show_menu
        ;;
    wake)
        check_device
        # Send KEYCODE_WAKEUP
        adb_cmd shell input keyevent KEYCODE_WAKEUP
        echo "Sent wake signal"
        ;;
    sleep|lock)
        check_device
        # Send KEYCODE_SLEEP
        adb_cmd shell input keyevent KEYCODE_SLEEP
        echo "Sent sleep signal"
        ;;
    unlock)
        check_device
        # Wake + swipe up to unlock (adjust swipe coords if needed)
        adb_cmd shell input keyevent KEYCODE_WAKEUP
        sleep 0.3
        adb_cmd shell input swipe 540 1800 540 800 300
        echo "Sent unlock gesture"
        ;;
    shutdown|poweroff)
        check_device
        echo "Shutting down Android device..."
        adb_cmd shell reboot -p
        ;;
    reboot|restart)
        check_device
        echo "Rebooting Android device..."
        adb_cmd reboot
        ;;
    recovery)
        check_device
        echo "Rebooting to recovery..."
        adb_cmd reboot recovery
        ;;
    bootloader|fastboot)
        check_device
        echo "Rebooting to bootloader..."
        adb_cmd reboot bootloader
        ;;
    scrcpy|mirror|display)
        check_device
        echo "Starting scrcpy..."
        shift
        scrcpy -K --keyboard=uhid --turn-screen-off --stay-awake --power-off-on-close "$@"
        ;;
    screenshot)
        check_device
        FILENAME="${2:-android-screenshot-$(date +%Y%m%d-%H%M%S).png}"
        adb_cmd exec-out screencap -p > "$FILENAME"
        echo "Screenshot saved to $FILENAME"
        ;;
    shell)
        check_device
        shift
        if [[ $# -eq 0 ]]; then
            adb_cmd shell
        else
            adb_cmd shell "$@"
        fi
        ;;
    status)
        echo "=== Android Device Status ==="
        if adb_cmd get-state &>/dev/null; then
            STATE=$(adb_cmd get-state)
            SERIAL=$(adb_cmd get-serialno)
            echo "State:  $STATE"
            echo "Serial: $SERIAL"

            if [[ "$STATE" == "device" ]]; then
                MODEL=$(adb_cmd shell getprop ro.product.model 2>/dev/null | tr -d '\r')
                ANDROID=$(adb_cmd shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')
                BATTERY=$(adb_cmd shell dumpsys battery 2>/dev/null | grep "level:" | awk '{print $2}')
                SCREEN=$(adb_cmd shell dumpsys power 2>/dev/null | grep "Display Power" | head -1)

                echo "Model:  $MODEL"
                echo "Android: $ANDROID"
                [[ -n "$BATTERY" ]] && echo "Battery: ${BATTERY}%"
                [[ -n "$SCREEN" ]] && echo "$SCREEN"
            fi
        else
            echo "No device connected"
            exit 1
        fi
        ;;
    help|--help|-h)
        echo "Usage: $(basename "$0") <command>"
        echo ""
        echo "Commands:"
        echo "  wake        Wake up the screen"
        echo "  sleep/lock  Turn off the screen"
        echo "  unlock      Wake + swipe to unlock"
        echo "  shutdown    Power off the device"
        echo "  reboot      Reboot the device"
        echo "  recovery    Reboot to recovery mode"
        echo "  bootloader  Reboot to bootloader/fastboot"
        echo "  scrcpy      Start screen mirroring"
        echo "  screenshot  Take a screenshot"
        echo "  shell       Open adb shell (or run command)"
        echo "  status      Show device status (default)"
        echo "  menu        Show dmenu picker"
        echo ""
        echo "Environment:"
        echo "  ANDROID_SERIAL  Specify device serial if multiple connected"
        echo "  DMENU_CMD       Custom dmenu command (default: dmenu -i -p Android:)"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$(basename "$0") help' for usage"
        exit 1
        ;;
esac
