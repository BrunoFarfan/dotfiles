#!/usr/bin/env bash

# Configuration
WALLPAPER_DIR="$HOME/Pictures/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
THUMBNAIL_WIDTH="250"  # Size of thumbnails in pixels (16:9)
THUMBNAIL_HEIGHT="141"

# Parse command line arguments
SHUFFLE_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --shuffle|-s)
            SHUFFLE_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --shuffle, -s    Bypass interactive mode and select random wallpaper"
            echo "  --help, -h       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

# Handle shuffle mode or interactive selection
if [[ "$SHUFFLE_MODE" == "true" ]]; then
    # Shuffle mode: directly select a random wallpaper
    # Get current wallpaper if it exists
    current_wallpaper=""
    if [[ -f "$HOME/.cache/current_wallpaper" ]]; then
        current_wallpaper=$(cat "$HOME/.cache/current_wallpaper")
    fi
    
    # Select a random wallpaper from the directory, excluding shuffle.png and current wallpaper
    if [[ -n "$current_wallpaper" ]]; then
        # Exclude current wallpaper from random selection
        original_path=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -name "shuffle.png" ! -path "$current_wallpaper" | shuf -n 1)
    else
        # No current wallpaper, just exclude shuffle.png
        original_path=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -name "shuffle.png" | shuf -n 1)
    fi
    
    # Check if a wallpaper was found
    if [[ -z "$original_path" ]]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi
    
    echo "Selected random wallpaper: $(basename "$original_path")"
else
    # Interactive mode: use wofi to display grid of wallpapers
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
            # Get current wallpaper if it exists
            current_wallpaper=""
            if [[ -f "$HOME/.cache/current_wallpaper" ]]; then
                current_wallpaper=$(cat "$HOME/.cache/current_wallpaper")
            fi
            
            # Select a random wallpaper from the directory, excluding shuffle.png and current wallpaper
            if [[ -n "$current_wallpaper" ]]; then
                # Exclude current wallpaper from random selection
                original_path=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -name "shuffle.png" ! -path "$current_wallpaper" | shuf -n 1)
            else
                # No current wallpaper, just exclude shuffle.png
                original_path=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) ! -name "shuffle.png" | shuf -n 1)
            fi
        else
            # Get the original filename from the thumbnail path
            original_filename=$(basename "${thumbnail_path%.*}")

            # Find the corresponding original file in the wallpaper directory
            original_path=$(find "$WALLPAPER_DIR" -type f -name "${original_filename}.*" | head -n1)
        fi
    fi
fi

# Set wallpaper if one was selected or found
if [ -n "$original_path" ]; then
        # Start swww daemon if not already running (suppress error if already running)
        if ! pgrep -x "swww" > /dev/null; then
            swww-daemon > /dev/null 2>&1 &
            sleep 0.1
        fi
        
        # Set wallpaper using swww with transition animation
        swww img "$original_path" \
            --transition-type any \
            --transition-step 90 \
            --transition-fps 60 \
            --transition-duration 2 \
            --transition-angle 30 \
            --transition-pos 0.854,0.977

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
    el
        notify-send "Wallpaper Error" "Could not find the original wallpaper file."
    fi
fi
