#!/bin/bash

# Terminal Selector Nautilus Extension Uninstaller

CONFIG_FILE="$HOME/.config/nautilus-terminals.conf"
EXTENSION_DIR="$HOME/.local/share/nautilus-python/extensions"
EXTENSION_FILE="$EXTENSION_DIR/terminal-selector.py"

echo "========================================="
echo "Terminal Selector Uninstaller"
echo "========================================="
echo ""

# Check if extension is installed
if [ ! -f "$EXTENSION_FILE" ]; then
    echo "⚠ Extension not found. Nothing to uninstall."
    exit 0
fi

# Ask about config file
if [ -f "$CONFIG_FILE" ]; then
    echo "A configuration file was found at:"
    echo "  $CONFIG_FILE"
    echo ""
    read -p "Do you want to keep this file for future reinstallation? (y/n): " keep_config

    if [[ "$keep_config" =~ ^[Nn]$ ]]; then
        rm -f "$CONFIG_FILE"
        echo "✓ Removed configuration file"
    else
        echo "✓ Kept configuration file"
    fi
fi

# Remove extension
rm -f "$EXTENSION_FILE"
echo "✓ Removed extension file"

# Restart Nautilus
echo ""
echo "Restarting Nautilus..."
nautilus -q 2>/dev/null || true
sleep 1

echo ""
echo "========================================="
echo "Uninstallation Complete!"
echo "========================================="
echo ""

if [[ ! "$keep_config" =~ ^[Nn]$ ]] && [ -f "$CONFIG_FILE" ]; then
    echo "Your configuration has been preserved."
    echo "To reinstall with the same settings, run:"
    echo "  ./install-terminal-selector.sh"
    echo ""
fi
