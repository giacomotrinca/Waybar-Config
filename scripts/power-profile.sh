#!/usr/bin/env bash

# Power profile module for Waybar
# Requires powerprofilesctl (power-profiles-daemon)

PROFILES=("balanced" "performance" "power-saver")
SIGNAL=9
WAYBAR_BIN=waybar
NOTIFIER=$(command -v notify-send)

send_notification() {
    local title="$1"
    local body="$2"

    if [ -n "$NOTIFIER" ]; then
        "$NOTIFIER" -a "Waybar" "$title" "$body"
    fi
}

powerprofilesctl_cmd() {
    if ! command -v powerprofilesctl >/dev/null 2>&1; then
        return 1
    fi
    return 0
}

current_profile() {
    powerprofilesctl get 2>/dev/null | tr -d '\n' | tr '[:upper:]' '[:lower:]'
}

pretty_name() {
    case "$1" in
        performance) echo "Performance" ;;
        power-saver) echo "Power Saver" ;;
        *) echo "Balanced" ;;
    esac
}

profile_icon() {
    case "$1" in
        performance) echo "󰓅" ;;
        power-saver) echo "󰾆" ;;
        *) echo "󰔚" ;;
    esac
}

profile_class() {
    case "$1" in
        performance) echo "performance" ;;
        power-saver) echo "power-saver" ;;
        *) echo "balanced" ;;
    esac
}

emit_status() {
    if ! powerprofilesctl_cmd; then
        echo '{"text":"󱈸","tooltip":"powerprofilesctl not available","class":"unavailable"}'
        exit 0
    fi

    local current
    current=$(current_profile)
    if [[ -z "$current" ]]; then
        echo '{"text":"󱈸","tooltip":"Unable to read power profile","class":"error"}'
        exit 0
    fi

    local icon name class tooltip
    icon=$(profile_icon "$current")
    name=$(pretty_name "$current")
    class=$(profile_class "$current")
    tooltip="Profile: ${name}\\nLeft click to cycle"

    echo "{\"text\":\"${icon} ${name}\",\"tooltip\":\"${tooltip}\",\"class\":\"${class}\"}"
}

cycle_profile() {
    if ! powerprofilesctl_cmd; then
        send_notification "Power Profile" "powerprofilesctl unavailable"
        exit 1
    fi

    local current next_idx next_profile idx
    current=$(current_profile)
    if [[ -z "$current" ]]; then
        send_notification "Power Profile" "unable to read current profile"
        exit 1
    fi

    for idx in "${!PROFILES[@]}"; do
        if [[ "${PROFILES[$idx]}" == "$current" ]]; then
            next_idx=$(( (idx + 1) % ${#PROFILES[@]} ))
            break
        fi
    done

    if [[ -z "$next_idx" ]]; then
        next_idx=0
    fi

    next_profile="${PROFILES[$next_idx]}"

    if powerprofilesctl set "$next_profile" >/dev/null 2>&1; then
        pkill -RTMIN+$SIGNAL "$WAYBAR_BIN" 2>/dev/null
        send_notification "Power Profile" "$(pretty_name "$current") → $(pretty_name "$next_profile")"
    else
        send_notification "Power Profile" "failed to set $(pretty_name "$next_profile")"
        exit 1
    fi

}

case "$1" in
    --toggle)
        cycle_profile
        ;;
    *)
        emit_status
        ;;
esac
