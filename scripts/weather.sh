#!/usr/bin/env bash

# Weather script for Waybar
# Uses wttr.in API for weather information

CANDIDATE="$1"
LOCATION="${WAYBAR_WEATHER_LOCATION:-${CANDIDATE:-auto}}"  # env var or first arg, fallback to auto
CACHE_FILE="/tmp/waybar-weather-cache"
CACHE_DURATION=1800  # 30 minutes in seconds

condition_icon() {
    local cond
    cond=$(echo "$1" | tr '[:upper:]' '[:lower:]')

    case "$cond" in
        *"sun"*|*"clear"*) echo "󰖙" ;;
        *"partly"*"cloud"*|*"patchy"*"cloud"*) echo "󰖕" ;;
        *"cloud"*|*"overcast"*) echo "󰅠" ;;
        *"rain"*|*"drizzle"*|*"shower"*) echo "󰖖" ;;
        *"snow"*|*"sleet"*) echo "󰖗" ;;
        *"thunder"*|*"storm"*) echo "󰼯" ;;
        *"mist"*|*"fog"*|*"haze"*) echo "󰖑" ;;
        *) echo "󰖎" ;;
    esac
}

get_weather() {
    # Fetch weather data from wttr.in
    weather_data=$(curl -s "wttr.in/${LOCATION}?format=j1")
    
    if [ -z "$weather_data" ]; then
        echo '{"text":"","tooltip":"Weather data unavailable"}'
        return
    fi
    
    # Parse JSON data
    temp=$(echo "$weather_data" | jq -r '.current_condition[0].temp_C')
    feels_like=$(echo "$weather_data" | jq -r '.current_condition[0].FeelsLikeC')
    condition=$(echo "$weather_data" | jq -r '.current_condition[0].weatherDesc[0].value')
    humidity=$(echo "$weather_data" | jq -r '.current_condition[0].humidity')
    wind_speed=$(echo "$weather_data" | jq -r '.current_condition[0].windspeedKmph')
    # resolved location reported by wttr.in
    resolved_location=$(echo "$weather_data" | jq -r '.nearest_area[0].areaName[0].value' 2>/dev/null)
    if [ -z "$resolved_location" ] || [ "$resolved_location" = "null" ]; then
        # try fallback fields
        resolved_location=$(echo "$weather_data" | jq -r '.nearest_area[0].areaName.value // .nearest_area[0].areaName' 2>/dev/null)
    fi
    if [ -z "$resolved_location" ] || [ "$resolved_location" = "null" ]; then
        resolved_location="$LOCATION"
    fi
    
    # Choose icon based on weather condition
    icon=$(condition_icon "$condition")
    
    # Create tooltip with detailed information (include resolved location)
    tooltip="<b>Weather — ${resolved_location}</b>\n"
    tooltip+="Condition: ${condition}\n"
    tooltip+="Temperature: ${temp}°C (feels like ${feels_like}°C)\n"
    tooltip+="Humidity: ${humidity}%\n"
    tooltip+="Wind: ${wind_speed} km/h"
    
    # Output JSON for Waybar
    if [ -n "$icon" ]; then
        text="${icon} ${temp}°C — ${resolved_location}"
    else
        text="${temp}°C — ${resolved_location}"
    fi

    echo "{\"text\":\"${text}\",\"tooltip\":\"${tooltip}\"}"
}

# Check cache
if [ -f "$CACHE_FILE" ]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    if [ $cache_age -lt $CACHE_DURATION ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Fetch new data and cache it
weather_output=$(get_weather)
echo "$weather_output" | tee "$CACHE_FILE"
