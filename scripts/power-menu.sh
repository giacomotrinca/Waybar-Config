#!/usr/bin/env bash

# Power menu script for Waybar
# Beautiful power menu with wofi or rofi

# Get script directory
SCRIPT_DIR="$HOME/.config/waybar/scripts"

# Check which launcher is available
if command -v wofi &> /dev/null; then
    LAUNCHER="wofi"
    USE_WOFI=true
elif command -v rofi &> /dev/null; then
    LAUNCHER="rofi"
    USE_WOFI=false
else
    notify-send "Error" "No launcher found (wofi or rofi required)"
    exit 1
fi

# Power menu options with Nerd Font icons
shutdown="󰐥  Shutdown"
reboot="󰜉  Reboot"
lock="󰌾  Lock"
logout="󰍃  Logout"
suspend="󰤄  Suspend"
hibernate="󰒲  Hibernate"

# Show menu based on launcher
if [ "$USE_WOFI" = true ]; then
    # Wofi with custom styling
    chosen=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
        "$shutdown" "$reboot" "$lock" "$logout" "$suspend" "$hibernate" | \
        wofi --dmenu \
        --prompt "Power Menu" \
        --width 300 \
        --height 260 \
        --style "$SCRIPT_DIR/power-menu.css" \
        --hide-scroll \
        --no-actions \
        --insensitive)
else
    # Rofi fallback
    chosen=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
        "$shutdown" "$reboot" "$lock" "$logout" "$suspend" "$hibernate" | \
        rofi -dmenu -p "Power Menu" -theme-str 'window {width: 300px;}')
fi

# Execute chosen option
case "$chosen" in
    *"Shutdown")
        systemctl poweroff
        ;;
    *"Reboot")
        systemctl reboot
        ;;
    *"Lock")
        # Try different lock commands
        if command -v hyprlock &> /dev/null; then
            hyprlock
        elif command -v swaylock &> /dev/null; then
            swaylock -f
        else
            notify-send "Error" "No lock screen found"
        fi
        ;;
    *"Logout")
        # Logout from Hyprland
        hyprctl dispatch exit
        ;;
    *"Suspend")
        systemctl suspend
        ;;
    *"Hibernate")
        systemctl hibernate
        ;;
esac
