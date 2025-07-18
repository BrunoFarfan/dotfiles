#!/usr/bin/env bash

# wallpaper path
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# pick random wallpaper
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | shuf -n 1)

[ -z "$WALLPAPER" ] && echo "No wallpapers found in $WALLPAPER_DIR" && exit 1

echo "preload = $WALLPAPER" > "$HOME/.config/hypr/hyprpaper.conf"
echo "wallpaper = HDMI-A-1,$WALLPAPER" >> "$HOME/.config/hypr/hyprpaper.conf"

pkill hyprpaper
hyprpaper &

rm -rf ~/.cache/wal/schemes/

wal -i "$WALLPAPER" && {
	~/.cache/wal/convert_colors.sh
	pkill waybar
	waybar &
} &
