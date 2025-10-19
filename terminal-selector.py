#!/usr/bin/env python3
# Terminal Selector Nautilus Extension
#
# Place me in ~/.local/share/nautilus-python/extensions/,
# ensure you have python-nautilus package, restart Nautilus, and enjoy :)
#
# This script is released to the public domain.

from gi.repository import Nautilus, GObject
from subprocess import call
import os
import configparser

# Path to the configuration file
CONFIG_FILE = os.path.expanduser('~/.config/nautilus-terminals.conf')

# Terminal command templates
TERMINAL_COMMANDS = {
    'kitty': 'kitty --directory="{path}"',
    'alacritty': 'alacritty --working-directory "{path}"',
    'terminator': 'terminator --working-directory="{path}"',
    'tilix': 'tilix --working-directory="{path}"',
    'konsole': 'konsole --workdir "{path}"',
    'wezterm': 'wezterm start --cwd "{path}"',
    'foot': 'foot --working-directory="{path}"',
    'st': 'st -d "{path}"',
    'xterm': 'xterm -e "cd \\"{path}\\" && exec $SHELL"',
    'urxvt': 'urxvt -cd "{path}"',
    'gnome-terminal': 'gnome-terminal --working-directory="{path}"',
    'xfce4-terminal': 'xfce4-terminal --working-directory="{path}"',
    'mate-terminal': 'mate-terminal --working-directory="{path}"',
}


class TerminalSelectorExtension(GObject.GObject, Nautilus.MenuProvider):

    def __init__(self):
        super().__init__()
        self.terminals = self.load_terminals()

    def load_terminals(self):
        """Load enabled terminals from config file."""
        terminals = []

        if not os.path.exists(CONFIG_FILE):
            return terminals

        try:
            config = configparser.ConfigParser()
            config.read(CONFIG_FILE)

            if 'terminals' in config:
                for term_name, enabled in config['terminals'].items():
                    if enabled.lower() in ('true', 'yes', '1'):
                        # Get custom command or use default
                        if 'commands' in config and term_name in config['commands']:
                            cmd_template = config['commands'][term_name]
                        else:
                            cmd_template = TERMINAL_COMMANDS.get(term_name)

                        if cmd_template:
                            terminals.append({
                                'name': term_name,
                                'command': cmd_template
                            })
        except Exception as e:
            print(f"Error loading terminal config: {e}")

        return terminals

    def launch_terminal(self, menu, terminal, path):
        """Launch the specified terminal with the given path."""
        try:
            cmd = terminal['command'].format(path=path)
            call(cmd + ' &', shell=True)
        except Exception as e:
            print(f"Error launching {terminal['name']}: {e}")

    def get_file_items(self, *args):
        """Add menu items when right-clicking on files/folders."""
        files = args[-1]

        # Only show for single directory selection
        if len(files) != 1:
            return []

        file_info = files[0]

        # Only show for directories
        if not file_info.is_directory():
            return []

        path = file_info.get_location().get_path()

        if not path or not os.path.isdir(path):
            return []

        return self._create_menu_items(path)

    def get_background_items(self, *args):
        """Add menu items when right-clicking on empty space."""
        file_ = args[-1]
        path = file_.get_location().get_path()

        if not path or not os.path.isdir(path):
            return []

        return self._create_menu_items(path)

    def _create_menu_items(self, path):
        """Create menu items for all enabled terminals."""
        items = []

        for terminal in self.terminals:
            # Capitalize the terminal name for display
            display_name = terminal['name'].capitalize()
            if terminal['name'] == 'gnome-terminal':
                display_name = 'GNOME Terminal'
            elif terminal['name'] == 'xfce4-terminal':
                display_name = 'XFCE Terminal'
            elif terminal['name'] == 'mate-terminal':
                display_name = 'MATE Terminal'

            item = Nautilus.MenuItem(
                name=f'TerminalSelector::{terminal["name"]}',
                label=f'Open in {display_name}',
                tip=f'Opens this directory in {display_name}'
            )
            item.connect('activate', self.launch_terminal, terminal, path)
            items.append(item)

        return items
