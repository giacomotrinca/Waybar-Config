#!/usr/bin/env bash

# Weather script for Waybar
# Uses wttr.in API for weather information

LOCATION="auto"  # Can be changed to your city name
CACHE_FILE="/tmp/waybar-weather-cache"
CACHE_DURATION=1800  # 30 minutes in seconds

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
    
    # Choose icon based on weather condition
    case "$condition" in
        *"Sunny"*|*"Clear"*)
            icon=""
            ;;
        *"Partly cloudy"*)
            icon=""
            ;;
        *"Cloudy"*|*"Overcast"*)
            icon=""
            ;;
        *"Rain"*|*"Drizzle"*)
            icon=""
            ;;
        *"Snow"*)
            icon=""
            ;;
        *"Thunder"*|*"storm"*)
            icon=""
            ;;
        *"Mist"*|*"Fog"*)
            icon=""
            ;;
        *)
            icon=""
            ;;
    esac
    
    # Create tooltip with detailed information
    tooltip="<b>Weather</b>\n"
    tooltip+="Condition: ${condition}\n"
    tooltip+="Temperature: ${temp}°C (feels like ${feels_like}°C)\n"
    tooltip+="Humidity: ${humidity}%\n"
    tooltip+="Wind: ${wind_speed} km/h"
    
    # Output JSON for Waybar
    echo "{\"text\":\"${icon} ${temp}°C\",\"tooltip\":\"${tooltip}\"}"
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
