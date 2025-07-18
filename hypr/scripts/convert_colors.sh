#!/bin/bash

# Paths
wal_colors="$HOME/.cache/wal/colors.sh"
hyprland_colors="$HOME/.cache/wal/colorsHyprland.conf"

# Check for existence
if [[ ! -f "$wal_colors" ]]; then
    echo "Error: $wal_colors does not exist."
    exit 1
fi

# Ensure output directory exists
mkdir -p "$(dirname "$hyprland_colors")"

# Start writing the Hyprland color config
echo "# Generated from pywal colors" > "$hyprland_colors"
echo "# Do not edit manually – edit ~/.cache/wal/colors.sh and re-run the script" >> "$hyprland_colors"
echo "" >> "$hyprland_colors"

# Convert each color variable to Hyprland format
grep -E "^color[0-9]+=" "$wal_colors" | while IFS='=' read -r name value; do
    hex=$(echo "$value" | tr -d "'#")
    echo "\$$name = rgba(${hex}ff)" >> "$hyprland_colors"
done

# Also include special colors if desired
for special in background foreground cursor; do
    if grep -q "^$special=" "$wal_colors"; then
        value=$(grep "^$special=" "$wal_colors" | cut -d= -f2 | tr -d "'#")
        echo "\$$special = rgba(${value}ff)" >> "$hyprland_colors"
    fi
done

# Include wallpaper variable
if grep -q "^wallpaper=" "$wal_colors"; then
    wallpaper_value=$(grep "^wallpaper=" "$wal_colors" | cut -d= -f2 | tr -d "'")
    echo "\$wallpaper = $wallpaper_value" >> "$hyprland_colors"
fi

echo "✅ colorsHyprland.conf generated at: $hyprland_colors"

