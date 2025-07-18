#!/usr/bin/env bash

# Usage: ./link_dotfile.sh <folder-name>
# Example: ./link_dotfile.sh hypr

set -e

FOLDER="$1"

if [ -z "$FOLDER" ]; then
    echo "❌ Error: No folder name provided."
    echo "Usage: $0 <folder-name>"
    exit 1
fi

SOURCE="$HOME/.config/$FOLDER"
TARGET="$HOME/dotfiles/$FOLDER"

# Exit silently if source does not exist
if [ ! -e "$SOURCE" ]; then
    echo "⚠️ $SOURCE not found. Nothing to do."
    exit 0
fi

# Backup if dotfiles target already exists
if [ -e "$TARGET" ]; then
    echo "⚠️ Target $TARGET already exists. Backing it up..."
    mv "$TARGET" "$TARGET.bak.$(date +%s)"
fi

# Move the original config to dotfiles
echo "📦 Moving $SOURCE to $TARGET"
mv "$SOURCE" "$TARGET"

# Create the symlink
echo "🔗 Creating symlink: $SOURCE -> $TARGET"
ln -s "$TARGET" "$SOURCE"

echo "✅ Done! $FOLDER is now tracked in $TARGET and symlinked back."

