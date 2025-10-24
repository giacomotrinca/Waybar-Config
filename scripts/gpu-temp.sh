#!/usr/bin/env bash

# GPU Temperature script for Waybar
# Supports NVIDIA GPUs using nvidia-smi

# Check if nvidia-smi is available
if ! command -v nvidia-smi &> /dev/null; then
    echo '{"text":"N/A","tooltip":"NVIDIA GPU not found or nvidia-smi not installed"}'
    exit 0
fi

# Get GPU temperature
temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)

# Check if we got a valid temperature
if [ -z "$temp" ] || ! [[ "$temp" =~ ^[0-9]+$ ]]; then
    echo '{"text":"N/A","tooltip":"Unable to read GPU temperature"}'
    exit 0
fi

# Get GPU name and other stats
gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
gpu_utilization=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null)
gpu_memory=$(nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits 2>/dev/null)
power_draw=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader 2>/dev/null)

# Choose icon and class based on temperature
if [ "$temp" -ge 80 ]; then
    icon="󰸇"
    class="critical"
elif [ "$temp" -ge 70 ]; then
    icon="󰔏"
    class="warning"
else
    icon="󰢮"
    class="normal"
fi

# Create tooltip with detailed info
tooltip="<b>${gpu_name}</b>\n"
tooltip+="Temperature: ${temp}°C\n"
tooltip+="GPU Usage: ${gpu_utilization}%\n"
tooltip+="Memory Usage: ${gpu_memory}%\n"
tooltip+="Power Draw: ${power_draw}"

# Output JSON for Waybar
echo "{\"text\":\"${icon} ${temp}°C\",\"tooltip\":\"${tooltip}\",\"class\":\"${class}\"}"
