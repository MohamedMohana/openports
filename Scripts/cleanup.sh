#!/bin/bash

# OpenPorts Cleanup Script
# Removes build artifacts from the working directory

set -e

echo "🧹 Cleaning up OpenPorts build artifacts..."

# Remove app bundles
if [ -d "OpenPorts.app" ]; then
    echo "  Removing OpenPorts.app..."
    rm -rf OpenPorts.app
fi

# Remove release archives
count=$(ls -1 OpenPorts-*.zip 2>/dev/null | wc -l)
if [ $count -gt 0 ]; then
    echo "  Removing $count release archives..."
    rm -f OpenPorts-*.zip
fi

# Remove generated icon files
for icon in Icon.icns Icon.png OpenPorts.icns; do
    if [ -f "$icon" ]; then
        echo "  Removing $icon..."
        rm -f "$icon"
    fi
done

# Remove .DS_Store files
echo "  Removing .DS_Store files..."
find . -name ".DS_Store" -delete

echo "✅ Cleanup complete!"
echo ""
echo "Kept:"
echo "  - Icon.iconset/ (source icons)"
echo "  - Icon.icon/ (icon documentation)"
echo "  - Source code and configuration"
