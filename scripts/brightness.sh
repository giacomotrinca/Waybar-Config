#!/usr/bin/env bash

# Brightness control script for Waybar
# Requires brightnessctl and optionally notify-send (libnotify) for feedback

SIGNAL=11
WAYBAR_BIN=waybar
STEP="5%"
NOTIFIER=$(command -v notify-send)
BRIGHTNESSCTL=$(command -v brightnessctl)

if [ -z "$BRIGHTNESSCTL" ]; then
    echo '{"text":"󰃞","tooltip":"brightnessctl not available","class":"unavailable"}'
    exit 0
fi

send_update() {
    pkill -RTMIN+"$SIGNAL" "$WAYBAR_BIN" 2>/dev/null
}

notify_level() {
    [ -z "$NOTIFIER" ] && return
    local percent="$1"
    [ -z "$percent" ] && return
    "$NOTIFIER" -a "Waybar" "Brightness" "${percent}%"
}

current_percent() {
    local current max
    # Prefer percent field from -m output (last comma-separated field)
    local info percent_field
    info=$($BRIGHTNESSCTL -m 2>/dev/null | head -n1)
    if [ -n "$info" ]; then
        # split by comma, take last field
        IFS=',' read -r -a parts <<< "$info"
        percent_field=${parts[-1]}
        # remove trailing percent sign if present
        percent_field=${percent_field%%%}
        # ensure numeric
        if [ -n "$percent_field" ] && [ "$percent_field" -eq "$percent_field" ] 2>/dev/null; then
            echo "$percent_field"
            return
        fi
    fi

    # Fallback to compute from get/max
    local current max
    current=$($BRIGHTNESSCTL get 2>/dev/null)
    max=$($BRIGHTNESSCTL max 2>/dev/null)
    if [ -z "$current" ] || [ -z "$max" ] || [ "$max" -eq 0 ] 2>/dev/null; then
        echo ""
        return
    fi
    awk -v cur="$current" -v mx="$max" 'BEGIN { printf "%.0f", (cur / mx) * 100 }'
}

get_info() {
    local info device current max percent icon class tooltip text

    info=$($BRIGHTNESSCTL -m 2>/dev/null | head -n1)
    if [ -z "$info" ]; then
        echo '{"text":"󰃞","tooltip":"No backlight device detected","class":"unavailable"}'
        exit 0
    fi

    # Parse fields from brightnessctl -m output which can vary by version.
    # Common observed format: device,class,current,percent,max_raw  (5 fields)
    IFS=',' read -r -a parts <<< "$info"
    device=${parts[0]}
    if [ ${#parts[@]} -ge 5 ]; then
        current=${parts[2]}
        percent_field=${parts[3]}
        last_field=${parts[4]}
        # last_field is often the raw max (numeric) in some brightnessctl versions
        if [[ "$last_field" =~ ^[0-9]+$ ]]; then
            max=$last_field
        else
            max=$($BRIGHTNESSCTL max 2>/dev/null)
        fi
    elif [ ${#parts[@]} -eq 4 ]; then
        current=${parts[2]}
        percent_field=${parts[3]}
        max=$($BRIGHTNESSCTL max 2>/dev/null)
    else
        # Fallback to direct commands
        current=$($BRIGHTNESSCTL get 2>/dev/null)
        max=$($BRIGHTNESSCTL max 2>/dev/null)
        percent_field=""
    fi

    # Prefer percent_field (like "73%") when available
    percent=${percent_field%%%}
    if ! [[ "$percent" =~ ^[0-9]+$ ]]; then
        # fallback: compute from current/max (ensure numeric values)
        if [[ "$current" =~ ^[0-9]+$ ]] && [[ "$max" =~ ^[0-9]+$ ]] && [ "$max" -ne 0 ] 2>/dev/null; then
            percent=$(awk -v cur="$current" -v mx="$max" 'BEGIN { printf "%.0f", (cur / mx) * 100 }')
        else
            percent=0
        fi
    fi

    if [ -z "$percent" ]; then
        percent=0
    fi

    icon="󰃞"
    class="normal"

    if [ "$percent" -ge 75 ]; then
        icon="󰃠"
    elif [ "$percent" -ge 40 ]; then
        icon="󰃟"
    else
        icon="󰃞"
    fi

    if [ "$percent" -ge 95 ]; then
        class="bright"
    elif [ "$percent" -le 5 ]; then
        class="dim"
    fi

    tooltip="Device: ${device}\\nCurrent: ${current}/${max}\\nLevel: ${percent}%"
    text="${icon} ${percent}%"
    echo "{\"text\":\"${text}\",\"tooltip\":\"${tooltip}\",\"class\":\"${class}\"}"
}

case "$1" in
    --inc)
        if $BRIGHTNESSCTL set "+${STEP}" >/dev/null 2>&1; then
            send_update
            notify_level "$(current_percent)"
        fi
        exit 0
        ;;
    --dec)
        if $BRIGHTNESSCTL set "${STEP}-" >/dev/null 2>&1; then
            send_update
            notify_level "$(current_percent)"
        fi
        exit 0
        ;;
    *)
        get_info
        ;;
esac
