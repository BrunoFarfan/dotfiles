#!/usr/bin/env bash

# Configuration
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
THUMBNAIL_WIDTH="250"  # Size of thumbnails in pixels (16:9)
THUMBNAIL_HEIGHT="141"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Function to generate thumbnail
generate_thumbnail() {
    local input="$1"
    local output="$2"
    magick "$input" -thumbnail "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}^" -gravity center -extent "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" "$output"
}

# Create shuffle icon thumbnail on the fly
SHUFFLE_ICON="$CACHE_DIR/shuffle_thumbnail.png"
# Create a properly sized shuffle icon thumbnail
magick -size "${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" xc:#1e1e2e \
    \( "$WALLPAPER_DIR/shuffle.png" -resize "80x80" \) \
    -gravity center -composite "$SHUFFLE_ICON"

# Generate thumbnails and create menu items
generate_menu() {
    # Add random/shuffle option with a name that sorts first (using ! prefix)
    echo -en "img:$SHUFFLE_ICON\x00info:!Random Wallpaper\x1fRANDOM\n"
    
    # Then add all wallpapers
    for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
        # Skip if no matches found
        [[ -f "$img" ]] || continue
        
        # Skip shuffle.png
        [[ "$(basename "$img")" == "shuffle.png" ]] && continue
        
        # Generate thumbnail filename
        thumbnail="$CACHE_DIR/$(basename "${img%.*}").png"
        
        # Generate thumbnail if it doesn't exist or is older than source
        if [[ ! -f "$thumbnail" ]] || [[ "$img" -nt "$thumbnail" ]]; then
            generate_thumbnail "$img" "$thumbnail"
        fi
        
        # Output menu item (filename and path)
        echo -en "img:$thumbnail\x00info:$(basename "$img")\x1f$img\n"
    done
}

# Use wofi to display grid of wallpapers
selected=$(generate_menu | wofi --show dmenu \
    --cache-file /dev/null \
    --define "image-size=${THUMBNAIL_WIDTH}x${THUMBNAIL_HEIGHT}" \
    --columns 3 \
    --allow-images \
    --insensitive \
    --sort-order=default \
    --prompt "Select Wallpaper" \
    --conf ~/.config/wofi/wallpaper.conf \
    --style ~/.config/wofi/style-wallpaper.css \
  )

# Set wallpaper if one was selected
if [ -n "$selected" ]; then
    # Remove the img: prefix to get the cached thumbnail path
    thumbnail_path="${selected#img:}"

    # Check if random wallpaper was selected
    if [[ "$thumbnail_path" == "$SHUFFLE_ICON" ]]; then
        # Select a random wallpaper from the directory, excluding shuffle.png
        original_path=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -name "shuffle.png" | shuf -n 1)
    else
        # Get the original filename from the thumbnail path
        original_filename=$(basename "${thumbnail_path%.*}")

        # Find the corresponding original file in the wallpaper directory
        original_path=$(find "$WALLPAPER_DIR" -type f -name "${original_filename}.*" | head -n1)
    fi

    # Ensure a valid wallpaper was found before proceeding
    if [ -n "$original_path" ]; then
        # Set wallpaper using hyprpaper
        echo "preload = $original_path" > "$HOME/.config/hypr/hyprpaper.conf"
        echo "wallpaper = HDMI-A-1,$original_path" >> "$HOME/.config/hypr/hyprpaper.conf"

        # Restart hyprpaper
        pkill hyprpaper
        hyprpaper &

        # Clear wal cache and apply theme
        rm -rf ~/.cache/wal/schemes/

        wal -i "$original_path" && {
            # run script to convert colors into .conf file for hyprland.conf
            ~/dotfiles/hypr/scripts/convert_colors.sh
            
            # restart waybar
            pkill waybar
            waybar &

            # restart swaync
            pkill swaync
            swaync &
        } &

        # Save the selection for persistence
        echo "$original_path" > "$HOME/.cache/current_wallpaper"

        # Optional: Notify user
        notify-send "Wallpaper" "Wallpaper has been updated" -i "$original_path"
    else
        notify-send "Wallpaper Error" "Could not find the original wallpaper file."
    fi
fi
