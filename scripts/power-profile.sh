#!/usr/bin/env bash

# Power profile module for Waybar
# Requires powerprofilesctl (power-profiles-daemon)

PROFILES=("balanced" "performance" "power-saver")
SIGNAL=9
WAYBAR_BIN=waybar

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
        exit 1
    fi

    local current next idx
    current=$(current_profile)
    if [[ -z "$current" ]]; then
        exit 1
    fi

    for idx in "${!PROFILES[@]}"; do
        if [[ "${PROFILES[$idx]}" == "$current" ]]; then
            next=$(( (idx + 1) % ${#PROFILES[@]} ))
            break
        fi
    done

    if [[ -z "$next" ]]; then
        next=0
    fi

    powerprofilesctl set "${PROFILES[$next]}" >/dev/null 2>&1

    # Trigger Waybar refresh
    pkill -RTMIN+$SIGNAL "$WAYBAR_BIN" 2>/dev/null
}

case "$1" in
    --toggle)
        cycle_profile
        ;;
    *)
        emit_status
        ;;
esac
