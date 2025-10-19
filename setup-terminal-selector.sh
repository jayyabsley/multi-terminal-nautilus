#!/bin/bash

# Terminal Selector Nautilus Extension - Setup Script
# This script handles both installation and uninstallation

CONFIG_FILE="$HOME/.config/nautilus-terminals.conf"
EXTENSION_DIR="$HOME/.local/share/nautilus-python/extensions"
EXTENSION_FILE="$EXTENSION_DIR/terminal-selector.py"

echo "========================================="
echo "Terminal Selector Nautilus Extension"
echo "========================================="
echo ""

# Check if already installed
if [ -f "$EXTENSION_FILE" ]; then
    echo "⚠ Extension is already installed."
    echo ""
    echo "What would you like to do?"
    echo "  [1] Reinstall (keep existing configuration)"
    echo "  [2] Reinstall (create new configuration)"
    echo "  [3] Uninstall"
    echo "  [4] Cancel"
    echo ""
    read -p "Your choice (1-4): " choice </dev/tty

    case $choice in
        1)
            echo ""
            echo "Reinstalling with existing configuration..."
            KEEP_CONFIG=true
            MODE="reinstall"
            ;;
        2)
            echo ""
            echo "Reinstalling with new configuration..."
            KEEP_CONFIG=false
            MODE="install"
            ;;
        3)
            echo ""
            echo "Uninstalling..."
            MODE="uninstall"
            ;;
        4)
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
else
    MODE="install"
fi

# Uninstall function
uninstall() {
    echo "========================================="
    echo "Uninstalling Extension"
    echo "========================================="
    echo ""

    # Ask about config file
    if [ -f "$CONFIG_FILE" ]; then
        echo "A configuration file was found at:"
        echo "  $CONFIG_FILE"
        echo ""
        read -p "Do you want to keep this file for future reinstallation? (y/n): " keep_config </dev/tty

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
        echo "  ./setup-terminal-selector.sh"
        echo ""
    fi
}

# Install function
install() {
    echo "========================================="
    echo "Installing Extension"
    echo "========================================="
    echo ""

    # Install python-nautilus
    echo "[1/4] Installing python-nautilus..."
    if type "pacman" > /dev/null 2>&1
    then
        # check if already install, else install
        pacman -Qi python-nautilus &> /dev/null
        if [ `echo $?` -eq 1 ]
        then
            sudo pacman -S --noconfirm python-nautilus
        else
            echo "✓ python-nautilus is already installed"
        fi
    elif type "apt-get" > /dev/null 2>&1
    then
        # Find Ubuntu python-nautilus package
        package_name="python-nautilus"
        found_package=$(apt-cache search --names-only $package_name)
        if [ -z "$found_package" ]
        then
            package_name="python3-nautilus"
        fi

        # Check if the package needs to be installed and install it
        installed=$(apt list --installed $package_name -qq 2> /dev/null)
        if [ -z "$installed" ]
        then
            sudo apt-get install -y $package_name
        else
            echo "✓ $package_name is already installed."
        fi
    elif type "dnf" > /dev/null 2>&1
    then
        installed=`dnf list --installed nautilus-python 2> /dev/null`
        if [ -z "$installed" ]
        then
            sudo dnf install -y nautilus-python
        else
            echo "✓ nautilus-python is already installed."
        fi
    else
        echo "⚠ Failed to find python-nautilus, please install it manually."
        echo "  Debian/Ubuntu: sudo apt install python3-nautilus"
        echo "  Fedora: sudo dnf install nautilus-python"
        echo "  Arch: sudo pacman -S python-nautilus"
        exit 1
    fi

    echo ""

    # Detect installed terminals
    echo "[2/4] Detecting installed terminals..."
    declare -A TERMINALS
    TERMINAL_LIST=("kitty" "alacritty" "terminator" "tilix" "konsole" "wezterm" "foot" "st" "xterm" "urxvt" "gnome-terminal" "xfce4-terminal" "mate-terminal")

    for term in "${TERMINAL_LIST[@]}"; do
        if type "$term" > /dev/null 2>&1; then
            TERMINALS[$term]=$(which $term)
            echo "✓ Found: $term (${TERMINALS[$term]})"
        fi
    done

    if [ ${#TERMINALS[@]} -eq 0 ]; then
        echo "⚠ No supported terminals detected!"
        echo "  Please install at least one terminal emulator."
        exit 1
    fi

    echo ""
    echo "Detected ${#TERMINALS[@]} terminal(s)."
    echo ""

    # Interactive selection
    echo "[3/4] Select terminals to enable in Nautilus context menu:"
    echo "(Enter numbers separated by spaces, e.g., '1 3 5' or 'all' for all terminals)"
    echo ""

    counter=1
    declare -A TERMINAL_INDEX
    for term in "${!TERMINALS[@]}"; do
        echo "  [$counter] $term"
        TERMINAL_INDEX[$counter]=$term
        ((counter++))
    done

    echo ""
    read -p "Your selection: " selection </dev/tty

    # Process selection
    declare -A SELECTED_TERMINALS

    if [ "$selection" = "all" ]; then
        for term in "${!TERMINALS[@]}"; do
            SELECTED_TERMINALS[$term]=1
        done
    else
        for num in $selection; do
            if [ -n "${TERMINAL_INDEX[$num]}" ]; then
                term="${TERMINAL_INDEX[$num]}"
                SELECTED_TERMINALS[$term]=1
            fi
        done
    fi

    if [ ${#SELECTED_TERMINALS[@]} -eq 0 ]; then
        echo "⚠ No terminals selected. Exiting."
        exit 1
    fi

    echo ""
    echo "Selected terminals:"
    for term in "${!SELECTED_TERMINALS[@]}"; do
        echo "  ✓ $term"
    done

    # Create config file
    echo ""
    echo "[4/4] Creating configuration..."

    mkdir -p "$(dirname "$CONFIG_FILE")"

    cat > "$CONFIG_FILE" << 'EOF'
# Nautilus Terminal Selector Configuration
#
# This file controls which terminals appear in the Nautilus context menu.
# Set terminal names to 'true' to enable them or 'false' to disable them.
#
# After editing, restart Nautilus with: nautilus -q

[terminals]
EOF

    # Add all detected terminals to config
    for term in "${TERMINAL_LIST[@]}"; do
        if [ -n "${SELECTED_TERMINALS[$term]}" ]; then
            echo "$term = true" >> "$CONFIG_FILE"
        else
            echo "$term = false" >> "$CONFIG_FILE"
        fi
    done

    cat >> "$CONFIG_FILE" << 'EOF'

# [commands]
# You can override the default command for any terminal here.
# Use {path} as a placeholder for the directory path.
# Example:
# kitty = kitty --directory="{path}"
# alacritty = alacritty --working-directory "{path}"
EOF

    echo "✓ Configuration saved to: $CONFIG_FILE"

    # Install the extension
    mkdir -p "$EXTENSION_DIR"

    # Check if terminal-selector.py exists locally, otherwise download it
    if [ -f "terminal-selector.py" ]; then
        cp terminal-selector.py "$EXTENSION_FILE"
    else
        echo "Downloading extension file..."
        wget -q -O "$EXTENSION_FILE" https://raw.githubusercontent.com/jayyabsley/multi-terminal-nautilus/master/terminal-selector.py
    fi

    chmod +x "$EXTENSION_FILE"

    echo "✓ Extension installed to: $EXTENSION_FILE"

    # Restart nautilus
    echo ""
    echo "Restarting Nautilus..."
    nautilus -q 2>/dev/null || true
    sleep 1

    echo ""
    echo "========================================="
    echo "Installation Complete!"
    echo "========================================="
    echo ""
    echo "The following terminals are now available in your Nautilus context menu:"
    for term in "${!SELECTED_TERMINALS[@]}"; do
        echo "  • Open in $(echo $term | sed 's/.*/\u&/')"
    done
    echo ""
    echo "To modify your selection, you can:"
    echo "  1. Edit the config file: $CONFIG_FILE"
    echo "  2. Re-run this script: ./setup-terminal-selector.sh"
    echo ""
    echo "After any changes, restart Nautilus with: nautilus -q"
    echo ""
}

# Reinstall function (keeps existing config)
reinstall() {
    echo "========================================="
    echo "Reinstalling Extension"
    echo "========================================="
    echo ""

    # Check if config exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "⚠ No existing configuration found."
        echo "  Performing fresh installation..."
        install
        return
    fi

    echo "Using existing configuration from: $CONFIG_FILE"
    echo ""

    # Install the extension
    mkdir -p "$EXTENSION_DIR"

    # Check if terminal-selector.py exists locally, otherwise download it
    if [ -f "terminal-selector.py" ]; then
        cp terminal-selector.py "$EXTENSION_FILE"
    else
        echo "Downloading extension file..."
        wget -q -O "$EXTENSION_FILE" https://raw.githubusercontent.com/jayyabsley/multi-terminal-nautilus/master/terminal-selector.py
    fi

    chmod +x "$EXTENSION_FILE"

    echo "✓ Extension reinstalled to: $EXTENSION_FILE"

    # Restart nautilus
    echo ""
    echo "Restarting Nautilus..."
    nautilus -q 2>/dev/null || true
    sleep 1

    echo ""
    echo "========================================="
    echo "Reinstallation Complete!"
    echo "========================================="
    echo ""
    echo "Your terminal menu items have been restored using the existing configuration."
    echo ""
    echo "To modify your selection:"
    echo "  1. Edit the config file: $CONFIG_FILE"
    echo "  2. Re-run this script: ./setup-terminal-selector.sh"
    echo ""
    echo "After any changes, restart Nautilus with: nautilus -q"
    echo ""
}

# Execute the appropriate mode
case $MODE in
    uninstall)
        uninstall
        ;;
    install)
        install
        ;;
    reinstall)
        reinstall
        ;;
esac
