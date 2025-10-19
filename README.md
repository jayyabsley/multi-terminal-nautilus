# Nautilus Terminal Selector

Add custom terminal emulator options to the Nautilus file manager context menu.

## Features

- Right-click folders to open them in your preferred terminal
- Support for 13+ terminal emulators
- Interactive installation with auto-detection
- Multiple terminals can be enabled simultaneously

## Supported Terminals

kitty, alacritty, terminator, tilix, konsole, wezterm, foot, st, xterm, urxvt, gnome-terminal, xfce4-terminal, mate-terminal

## Installation

One-line install:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/jayyabsley/multi-terminal-nautilus/master/setup-terminal-selector.sh)
```

Or clone and run locally:

```bash
git clone https://github.com/jayyabsley/multi-terminal-nautilus.git
cd multi-terminal-nautilus
./setup-terminal-selector.sh
```

The installer will:
1. Detect installed terminals on your system
2. Prompt you to select which ones to enable
3. Install the extension and restart Nautilus

## Usage

After installation, right-click any folder in Nautilus to see "Open in [Terminal]" options.

## Management

To modify, reinstall, or uninstall, run the installer again:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/jayyabsley/multi-terminal-nautilus/master/setup-terminal-selector.sh)
```

Options:
- Reinstall (keep or update configuration)
- Uninstall the extension

## Requirements

- Nautilus (GNOME Files)
- `python-nautilus` or `python3-nautilus` package
- At least one supported terminal emulator

## Configuration

Edit `~/.config/nautilus-terminals.conf` to enable/disable terminals or customize launch commands.

After changes, restart Nautilus:
```bash
nautilus -q
```

## License

Public Domain
