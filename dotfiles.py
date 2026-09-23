#!/usr/bin/env python3
# Konstantin Zaremski
#   August 27, 2023
#   Updated: 2025
#
# dotfiles.py
#   This python script manages the dotfiles repository with an interactive TUI
#   for creating symlinks from the repo to your home directory
#
# Usage
#   python3 dotfiles.py [--link | -l]
#
# License
#   MIT

import os
import sys
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

# Add local venv to path if it exists
SCRIPT_DIR = Path(__file__).parent.resolve()
VENV_DIR = SCRIPT_DIR / ".venv"

# Determine the site-packages path based on platform
if VENV_DIR.exists():
    if sys.platform == "win32":
        venv_site_packages = VENV_DIR / "Lib" / "site-packages"
    else:
        # Unix-like systems (Linux, macOS)
        python_version = f"python{sys.version_info.major}.{sys.version_info.minor}"
        venv_site_packages = VENV_DIR / "lib" / python_version / "site-packages"

    if venv_site_packages.exists() and str(venv_site_packages) not in sys.path:
        sys.path.insert(0, str(venv_site_packages))

# Try to import Rich for fancy TUI, fall back to basic interface if not available
try:
    from rich.console import Console
    from rich.prompt import Confirm, Prompt
    from rich.table import Table
    from rich.panel import Panel
    from rich.text import Text
    from rich import box
    HAS_RICH = True
    console = Console()
except ImportError:
    HAS_RICH = False
    console = None

# Try to import YAML for manifest support
try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

# ASCII banner, rendered in Delta Corps Priest 1 -- the figlet font
# Omarchy's own logo uses. Shown only when the terminal is wide enough;
# narrower terminals fall back to the plain header.
BANNER = """\
 ▄██████▄    ▄▄▄▄███▄▄▄▄      ▄████████    ▄████████  ▄████████    ▄█    █▄       ▄████████    ▄█   ▄█▄  ▄█
███    ███ ▄██▀▀▀███▀▀▀██▄   ███    ███   ███    ███ ███    ███   ███    ███     ███    ███   ███ ▄███▀ ███
███    ███ ███   ███   ███   ███    ███   ███    ███ ███    █▀    ███    ███     ███    █▀    ███▐██▀   ███▌
███    ███ ███   ███   ███   ███    ███  ▄███▄▄▄▄██▀ ███         ▄███▄▄▄▄███▄▄   ███         ▄█████▀    ███▌
███    ███ ███   ███   ███ ▀███████████ ▀▀███▀▀▀▀▀   ███        ▀▀███▀▀▀▀███▀  ▀███████████ ▀▀█████▄    ███▌
███    ███ ███   ███   ███   ███    ███ ▀███████████ ███    █▄    ███    ███            ███   ███▐██▄   ███
███    ███ ███   ███   ███   ███    ███   ███    ███ ███    ███   ███    ███      ▄█    ███   ███ ▀███▄ ███
 ▀██████▀   ▀█   ███   █▀    ███    █▀    ███    ███ ████████▀    ███    █▀     ▄████████▀    ███   ▀█▀ █▀
                                          ███    ███                                          ▀
"""
BANNER_WIDTH = 108

# Manifest file path
MANIFEST_FILE = SCRIPT_DIR / "manifest.yaml"

def load_dotfiles_manifest():
    """Load dotfiles configuration from manifest.yaml"""
    if not MANIFEST_FILE.exists():
        print(f"Error: Manifest file not found: {MANIFEST_FILE}")
        print("Please create a manifest.yaml file or restore it from the repository.")
        sys.exit(1)

    if not HAS_YAML:
        print("Error: PyYAML library not found.")
        print("Install it with: python3 dotfiles.py --install-deps")
        sys.exit(1)

    try:
        with open(MANIFEST_FILE, 'r') as f:
            data = yaml.safe_load(f)

        if not data or 'dotfiles' not in data:
            print(f"Error: Invalid manifest format in {MANIFEST_FILE}")
            print("Expected 'dotfiles' key with a list of entries.")
            sys.exit(1)

        # Convert to tuple format (source, dest, description, labels)
        dotfiles = []
        for entry in data['dotfiles']:
            if not all(k in entry for k in ['source', 'dest', 'description']):
                print(f"Warning: Skipping invalid entry: {entry}")
                continue
            labels = entry.get('labels') or []
            if isinstance(labels, str):
                labels = [l.strip() for l in labels.split(',') if l.strip()]
            dotfiles.append((entry['source'], entry['dest'], entry['description'], list(labels)))

        if not dotfiles:
            print(f"Error: No valid dotfiles found in {MANIFEST_FILE}")
            sys.exit(1)

        return dotfiles

    except yaml.YAMLError as e:
        print(f"Error: Failed to parse manifest.yaml: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: Failed to load manifest: {e}")
        sys.exit(1)

# Lazy loading of dotfiles - only load when needed, not at import time
DOTFILES = None

def get_dotfiles():
    """Get dotfiles list, loading from manifest if needed"""
    global DOTFILES
    if DOTFILES is None:
        DOTFILES = load_dotfiles_manifest()
    return DOTFILES

class DotfilesManager:
    def __init__(self):
        self.repo_path = Path(__file__).parent.resolve()
        self.home_path = Path.home()
        self.backup_dir = self.home_path / ".dotfiles-backup"
        # When True, report what would happen but touch nothing on disk.
        self.dry_run = False

    def print_header(self):
        """Print a fancy header or simple text depending on Rich availability"""
        # Only draw the banner if it fits; wrapping mangles block art badly.
        cols = shutil.get_terminal_size(fallback=(80, 24)).columns
        show_banner = cols >= BANNER_WIDTH

        if HAS_RICH:
            if show_banner:
                console.print(Text(BANNER, style="bold cyan"), highlight=False)
            console.print(Panel.fit(
                "[bold cyan]Konstantin's Dotfiles Manager[/bold cyan]\n"
                "[dim]Interactive symlink management for configuration files[/dim]",
                box=box.DOUBLE,
                border_style="cyan"
            ))
        else:
            if show_banner:
                print(BANNER)
            print("=" * 60)
            print("  DOTFILES MANAGER")
            print("  Interactive symlink management")
            print("=" * 60)
            print()

    def print_info(self, message, style="info"):
        """Print info message with optional styling"""
        if HAS_RICH:
            style_map = {
                "info": "cyan",
                "success": "green",
                "warning": "yellow",
                "error": "red"
            }
            console.print(f"[{style_map.get(style, 'white')}]{message}[/{style_map.get(style, 'white')}]")
        else:
            prefix = {
                "info": "[i]",
                "success": "[✓]",
                "warning": "[!]",
                "error": "[✗]"
            }
            print(f"{prefix.get(style, '')} {message}")

    def print_table(self, data):
        """Print a table of dotfiles or simple list"""
        if HAS_RICH:
            table = Table(title="Available Dotfiles", box=box.ROUNDED)
            table.add_column("No.", style="cyan", justify="right")
            table.add_column("Source", style="magenta")
            table.add_column("Destination", style="yellow")
            table.add_column("Status", style="white")
            table.add_column("Description", style="dim")

            for idx, (source, dest, status, desc) in enumerate(data, 1):
                status_style = "green" if status == "✓ Not linked" else "yellow" if status.startswith("→") else "red"
                table.add_row(
                    str(idx),
                    source,
                    dest,
                    f"[{status_style}]{status}[/{status_style}]",
                    desc
                )

            console.print(table)
        else:
            print("\nAvailable Dotfiles:")
            print("-" * 80)
            for idx, (source, dest, status, desc) in enumerate(data, 1):
                print(f"{idx:2}. {source:30} -> {dest:30} [{status}]")
                print(f"    {desc}")
            print("-" * 80)

    def get_status(self, source_rel, dest_rel):
        """Get the current status of a dotfile"""
        source = self.repo_path / source_rel
        dest = self.home_path / dest_rel

        if not source.exists():
            return "✗ Missing in repo"

        if not dest.exists():
            return "✓ Not linked"

        if dest.is_symlink():
            target = dest.resolve()
            if target == source:
                return "→ Already linked"
            else:
                return f"→ Links elsewhere"

        return "⚠ File exists"

    def list_dotfiles(self):
        """List all dotfiles with their current status"""
        data = []
        dotfiles = get_dotfiles()
        for source_rel, dest_rel, desc, _labels in dotfiles:
            status = self.get_status(source_rel, dest_rel)
            data.append((source_rel, dest_rel, status, desc))

        self.print_table(data)
        return data

    def confirm(self, message, default=False, allow_all=False):
        """Ask for confirmation with Rich or basic input

        Args:
            message: The prompt message
            default: Default choice if user presses enter
            allow_all: If True, allow 'a' for "yes to all"

        Returns:
            True for yes, False for no, 'all' for yes to all (when allow_all=True)
        """
        if HAS_RICH and not allow_all:
            return Confirm.ask(message, default=default)
        else:
            if allow_all:
                default_str = "y/N/a" if not default else "Y/n/a"
                response = input(f"{message} [{default_str}]: ").strip().lower()
                if not response:
                    return default
                if response in ['a', 'all']:
                    return 'all'
                return response in ['y', 'yes']
            else:
                default_str = "Y/n" if default else "y/N"
                response = input(f"{message} [{default_str}]: ").strip().lower()
                if not response:
                    return default
                return response in ['y', 'yes']

    def prompt(self, message, default=""):
        """Prompt for input"""
        if HAS_RICH:
            return Prompt.ask(message, default=default)
        else:
            return input(f"{message} [{default}]: ").strip() or default

    def all_labels(self):
        """Every label in the manifest, with how many entries carry each."""
        counts = {}
        for entry in get_dotfiles():
            for label in entry[3]:
                counts[label] = counts.get(label, 0) + 1
        return counts

    def select(self, include=None, exclude=None):
        """Filter manifest entries by label.

        include: keep an entry if it carries ANY of these (union, not
                 intersection -- `--label omarchy,shell` means "either").
                 An entry with no labels never matches an include filter.
        exclude: drop an entry if it carries ANY of these. Applied after
                 include, so exclude always wins.
        """
        entries = get_dotfiles()
        if include:
            entries = [e for e in entries if set(e[3]) & set(include)]
        if exclude:
            entries = [e for e in entries if not (set(e[3]) & set(exclude))]
        return entries

    def backup_name_for(self, path):
        """Build a collision-free backup filename for a destination path.

        Using only path.name would collide for entries that share a basename
        (e.g. .config/foo/config and .config/bar/config), since the timestamp
        is only second-resolution. Flatten the home-relative path instead.
        """
        try:
            rel = path.relative_to(self.home_path)
        except ValueError:
            rel = Path(path.name)
        flat = str(rel).strip("/").replace("/", "_")
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        return f"{flat}.backup.{timestamp}"

    def backup_file(self, path):
        """Backup an existing file, directory, or symlink.

        Symlinks are preserved as symlinks rather than dereferenced -- copying
        through a link would duplicate the target's contents (potentially a
        large tree) and lose the fact that it was a link at all. Broken
        symlinks are handled too: they fail exists() but still need removing.
        """
        if not path.exists() and not path.is_symlink():
            return None

        backup_path = self.backup_dir / self.backup_name_for(path)

        if self.dry_run:
            return backup_path

        # Create backup directory if it doesn't exist
        self.backup_dir.mkdir(parents=True, exist_ok=True)

        if path.is_symlink():
            # Record the link itself, target unresolved.
            backup_path.symlink_to(os.readlink(path))
        elif path.is_dir():
            shutil.copytree(path, backup_path, symlinks=True)
        else:
            shutil.copy2(path, backup_path)

        return backup_path

    def create_symlink(self, source_rel, dest_rel, force=False, yes_to_all=False):
        """Create a symlink from repo to home directory

        Args:
            source_rel: Source path relative to repo
            dest_rel: Destination path relative to home
            force: Skip confirmation entirely
            yes_to_all: Already confirmed for all files

        Returns:
            Tuple of (success: bool, apply_to_all: bool)
        """
        source = self.repo_path / source_rel
        dest = self.home_path / dest_rel

        # Check if source exists in repo
        if not source.exists():
            self.print_info(f"✗ Source not found: {source}", "error")
            return (False, yes_to_all)

        # Check if destination already exists
        if dest.exists() or dest.is_symlink():
            if dest.is_symlink() and dest.resolve() == source.resolve():
                self.print_info(f"→ Already linked: {dest_rel}", "info")
                return (True, yes_to_all)

            if not force and not yes_to_all:
                self.print_info(f"⚠ Destination exists: {dest_rel}", "warning")
                response = self.confirm("  Backup and replace?", default=False, allow_all=True)
                if response == 'all':
                    yes_to_all = True
                elif not response:
                    self.print_info(f"⊘ Skipped: {dest_rel}", "warning")
                    return (False, yes_to_all)

            # Backup existing file
            backup_path = self.backup_file(dest)
            if backup_path:
                verb = "Would back up" if self.dry_run else "Backed up"
                self.print_info(f"  {verb} to: {backup_path.relative_to(self.home_path)}", "info")

            # Remove existing file/symlink
            if not self.dry_run:
                if dest.is_dir() and not dest.is_symlink():
                    shutil.rmtree(dest)
                else:
                    dest.unlink()

        if self.dry_run:
            self.print_info(f"● Would link: {dest_rel} → {source_rel}", "info")
            return (True, yes_to_all)

        # Create parent directories if needed
        dest.parent.mkdir(parents=True, exist_ok=True)

        # Create symlink
        try:
            dest.symlink_to(source)
            self.print_info(f"✓ Linked: {dest_rel} → {source_rel}", "success")
            return (True, yes_to_all)
        except Exception as e:
            self.print_info(f"✗ Failed to link {dest_rel}: {e}", "error")
            return (False, yes_to_all)

    def link_selected(self, selections):
        """Link selected dotfiles"""
        if not selections:
            self.print_info("No dotfiles selected", "warning")
            return

        self.print_info(f"\nLinking {len(selections)} dotfile(s)...\n", "info")

        dotfiles = get_dotfiles()
        success_count = 0
        yes_to_all = False

        for idx in selections:
            if 1 <= idx <= len(dotfiles):
                source_rel, dest_rel, desc = dotfiles[idx - 1]
                success, yes_to_all = self.create_symlink(source_rel, dest_rel, yes_to_all=yes_to_all)
                if success:
                    success_count += 1
                print()  # Empty line between items

        self.print_info(f"\n✓ Successfully linked {success_count}/{len(selections)} dotfiles", "success")
        if self.backup_dir.exists():
            self.print_info(f"  Backups saved to: {self.backup_dir.relative_to(self.home_path)}", "info")

    def link_all(self):
        """Link all dotfiles"""
        self.print_info("\nLinking all dotfiles...\n", "info")

        dotfiles = get_dotfiles()
        success_count = 0
        yes_to_all = False

        for source_rel, dest_rel, desc, _labels in dotfiles:
            success, yes_to_all = self.create_symlink(source_rel, dest_rel, yes_to_all=yes_to_all)
            if success:
                success_count += 1
            print()

        self.print_info(f"\n✓ Successfully linked {success_count}/{len(dotfiles)} dotfiles", "success")
        if self.backup_dir.exists():
            self.print_info(f"  Backups saved to: {self.backup_dir.relative_to(self.home_path)}", "info")

    def link_by_label(self, include=None, exclude=None, force=False):
        """Link only the entries matching the given label filters."""
        entries = self.select(include, exclude)
        if not entries:
            self.print_info("No entries match those labels.", "warning")
            return

        what = []
        if include: what.append("labels: " + ", ".join(include))
        if exclude: what.append("excluding: " + ", ".join(exclude))
        self.print_info("Linking %d of %d entries (%s)\n" % (
            len(entries), len(get_dotfiles()), "; ".join(what) or "all"), "info")

        ok = 0
        yes_to_all = force
        for source_rel, dest_rel, _desc, _labels in entries:
            success, yes_to_all = self.create_symlink(
                source_rel, dest_rel, force=force, yes_to_all=yes_to_all)
            if success: ok += 1

        verb = "would link" if self.dry_run else "linked"
        self.print_info("\n%s %d/%d" % (verb.capitalize(), ok, len(entries)),
                        "success" if ok == len(entries) else "warning")

    def unlink_all(self, force=False):
        """Remove symlinks that point into this repo.

        Only removes links whose target resolves inside the repo -- a real file
        at the destination, or a link pointing somewhere else, is left alone so
        this can never eat something it didn't create. Backups in
        ~/.dotfiles-backup are never touched; restoring is a deliberate manual
        step.
        """
        removed = skipped = 0
        yes_to_all = force

        for source_rel, dest_rel, _desc, _labels in get_dotfiles():
            dest = self.home_path / dest_rel
            source = self.repo_path / source_rel

            if not dest.is_symlink():
                if dest.exists():
                    self.print_info(f"⊘ Not a symlink, left alone: {dest_rel}", "warning")
                    skipped += 1
                continue

            try:
                points_here = dest.resolve() == source.resolve()
            except OSError:
                points_here = False   # broken link

            if not points_here:
                self.print_info(f"⊘ Points outside the repo, left alone: {dest_rel}", "warning")
                skipped += 1
                continue

            if not yes_to_all:
                response = self.confirm(f"  Remove symlink {dest_rel}?", default=False, allow_all=True)
                if response == 'all':
                    yes_to_all = True
                elif not response:
                    skipped += 1
                    continue

            if self.dry_run:
                self.print_info(f"● Would unlink: {dest_rel}", "info")
            else:
                try:
                    dest.unlink()
                    self.print_info(f"✓ Unlinked: {dest_rel}", "success")
                except Exception as e:
                    self.print_info(f"✗ Failed to unlink {dest_rel}: {e}", "error")
                    skipped += 1
                    continue
            removed += 1

        verb = "would be removed" if self.dry_run else "removed"
        self.print_info(f"\n{removed} {verb}, {skipped} left alone", "info")
        if self.backup_dir.exists():
            self.print_info(f"Backups remain in: {self.backup_dir}", "info")

    def interactive_mode(self):
        """Run interactive selection mode"""
        self.print_header()
        self.print_info(f"Repository: {self.repo_path}", "info")
        self.print_info(f"Home: {self.home_path}\n", "info")

        # Main loop - keep prompting until user quits or completes an action
        while True:
            # List all dotfiles
            data = self.list_dotfiles()

            print()
            self.print_info("Select dotfiles to link:", "info")
            self.print_info("  • Enter numbers separated by spaces (e.g., '1 3 5')", "info")
            self.print_info("  • Enter 'all' to link everything", "info")
            self.print_info("  • Enter 'q' or 'quit' to exit\n", "info")

            try:
                selection = self.prompt("Selection", "all").strip().lower()
            except (EOFError, KeyboardInterrupt):
                print()
                self.print_info("\nExiting without changes", "info")
                return

            # Handle quit commands
            if selection in ['q', 'quit', 'exit']:
                self.print_info("Exiting without changes", "info")
                return

            # Handle empty input
            if not selection:
                self.print_info("No input provided. Please try again.\n", "warning")
                continue

            # Handle 'all' selection
            if selection == 'all':
                try:
                    if self.confirm("\nLink all dotfiles?", default=True):
                        self.link_all()
                        print()
                        # Ask if user wants to continue
                        if not self.confirm("Manage more dotfiles?", default=False):
                            return
                        print()
                    else:
                        print()
                except (EOFError, KeyboardInterrupt):
                    print()
                    self.print_info("\nExiting without changes", "info")
                    return
                continue

            # Handle numeric selections
            try:
                # Parse selections
                selections = [int(x) for x in selection.split()]

                # Validate all selections are in range
                dotfiles = get_dotfiles()
                invalid = [s for s in selections if s < 1 or s > len(dotfiles)]
                if invalid:
                    self.print_info(f"Invalid selection(s): {', '.join(map(str, invalid))}. Must be between 1-{len(dotfiles)}.\n", "error")
                    continue

                try:
                    if self.confirm(f"\nLink {len(selections)} selected dotfile(s)?", default=True):
                        self.link_selected(selections)
                        print()
                        # Ask if user wants to continue
                        if not self.confirm("Manage more dotfiles?", default=False):
                            return
                        print()
                    else:
                        print()
                except (EOFError, KeyboardInterrupt):
                    print()
                    self.print_info("\nExiting without changes", "info")
                    return

            except ValueError:
                self.print_info("Invalid input. Please enter numbers separated by spaces, 'all', or 'q' to quit.\n", "error")

def install_dependencies():
    """Install Python dependencies (PyYAML and Rich) in a local virtual environment"""
    print("Installing dependencies...")
    print()

    try:
        # Create virtual environment if it doesn't exist
        if not VENV_DIR.exists():
            print(f"Creating virtual environment at {VENV_DIR.relative_to(SCRIPT_DIR)}...")
            result = subprocess.run([sys.executable, '-m', 'venv', str(VENV_DIR)],
                                   capture_output=True,
                                   text=True)

            if result.returncode != 0:
                print(f"✗ Failed to create virtual environment: {result.stderr}")
                print()
                print("Falling back to user installation...")
                # Try user install as fallback
                return install_with_pip_user()

            print("✓ Virtual environment created")
            print()
        else:
            print(f"Using existing virtual environment at {VENV_DIR.relative_to(SCRIPT_DIR)}...")
            print()

        # Determine pip path in venv
        if sys.platform == "win32":
            pip_path = VENV_DIR / "Scripts" / "pip.exe"
            if not pip_path.exists():
                pip_path = VENV_DIR / "Scripts" / "pip"
        else:
            pip_path = VENV_DIR / "bin" / "pip"

        if not pip_path.exists():
            print(f"✗ Could not find pip in virtual environment")
            return False

        # Install dependencies in venv
        print("Installing PyYAML and Rich libraries...")
        result = subprocess.run([str(pip_path), 'install', 'pyyaml', 'rich'],
                               capture_output=True,
                               text=True)

        if result.returncode == 0:
            print("✓ Successfully installed dependencies!")
            print()
            print("Please restart the script to use the enhanced interface.")
            return True
        else:
            print(f"✗ Failed to install dependencies: {result.stderr}")
            return False

    except Exception as e:
        print(f"✗ Error installing dependencies: {e}")
        print()
        print("Falling back to user installation...")
        return install_with_pip_user()

def install_with_pip_user():
    """Fallback: Install dependencies using pip --user"""
    try:
        # Try pip3 first, then pip
        pip_cmd = None
        for cmd in ['pip3', 'pip']:
            try:
                result = subprocess.run([cmd, '--version'],
                                       capture_output=True,
                                       text=True,
                                       timeout=5)
                if result.returncode == 0:
                    pip_cmd = cmd
                    break
            except (FileNotFoundError, subprocess.TimeoutExpired):
                continue

        if not pip_cmd:
            print("Error: pip not found. Please install pip first.")
            return False

        print(f"Using {pip_cmd} to install dependencies...")
        result = subprocess.run([pip_cmd, 'install', '--user', 'pyyaml', 'rich'],
                               capture_output=True,
                               text=True)

        if result.returncode == 0:
            print("✓ Successfully installed dependencies!")
            print()
            print("Please restart the script to use the enhanced interface.")
            return True
        else:
            print(f"✗ Failed to install dependencies: {result.stderr}")
            return False

    except Exception as e:
        print(f"✗ Error installing dependencies: {e}")
        return False

def main(args):
    """Main entry point"""

    # Handle help first
    if "--help" in args or "-h" in args:
        print("Usage: python3 dotfiles.py [options]")
        print()
        print("Options:")
        print("  -l, --link         Interactive mode to create symlinks")
        print("  -u, --unlink       Remove symlinks that point into this repo")
        print("  -n, --dry-run      Show what would happen; change nothing")
        print("  --label A,B        Only entries carrying ANY of these labels")
        print("  --exclude-label A  Skip entries carrying ANY of these labels")
        print("  --labels           List all labels and how many entries use each")
        print("  -y, --yes          Don't prompt; assume yes (for scripted installs)")
        print()
        print("Examples:")
        print("  dotfiles.py --labels")
        print("  dotfiles.py --link --label omarchy -y")
        print("  dotfiles.py --link --label common,macos --dry-run")
        print("  dotfiles.py --link --exclude-label legacy")
        print("  --install-deps     Install Python dependencies (PyYAML and Rich)")
        print("  -h, --help         Show this help message")
        print()
        print("Without options, runs in interactive mode by default.")
        print()
        print("Dependencies:")
        print("  PyYAML - Required to read manifest.yaml configuration")
        print("  Rich   - Optional for enhanced TUI with colors and tables")
        return

    # Handle dependency installation
    if "--install-deps" in args or "--install" in args:
        return install_dependencies()

    # Check if dependencies are available and offer to install them (only in interactive mode)
    missing_deps = []
    if not HAS_YAML:
        missing_deps.append("PyYAML (required)")
    if not HAS_RICH:
        missing_deps.append("Rich (optional)")

    if missing_deps and (not args or len(args) == 1 or "--link" in args or "-l" in args):
        print(f"Note: Missing dependencies: {', '.join(missing_deps)}")
        if not HAS_YAML:
            print("  • PyYAML is required to read the manifest.yaml configuration file")
        if not HAS_RICH:
            print("  • Rich provides colorful output, tables, and better prompts (optional)")
        print()

        # Ask if user wants to install them
        try:
            response = input("Would you like to install missing dependencies now? [y/N]: ").strip().lower()
            if response in ['y', 'yes']:
                if install_dependencies():
                    print("Run the script again to continue.")
                    return
                else:
                    if not HAS_YAML:
                        print("Error: PyYAML is required. Cannot continue without it.")
                        sys.exit(1)
                    print("Continuing in basic mode...")
                    print()
            else:
                if not HAS_YAML:
                    print("Error: PyYAML is required. Install with: python3 dotfiles.py --install-deps")
                    sys.exit(1)
                print("Continuing in basic mode...")
                print("(You can install dependencies later with: python3 dotfiles.py --install-deps)")
                print()
        except EOFError:
            # Handle piped input or non-interactive mode
            print()
            if not HAS_YAML:
                print("Error: PyYAML is required. Install with: python3 dotfiles.py --install-deps")
                sys.exit(1)
            print("Running in non-interactive mode...")
            print("(Install dependencies with: python3 dotfiles.py --install-deps)")
            print()

    manager = DotfilesManager()
    manager.dry_run = "--dry-run" in args or "-n" in args
    if manager.dry_run:
        manager.print_info("DRY RUN - nothing will be changed on disk\n", "warning")

    def opt_values(flag):
        """Collect comma- or space-separated values following a flag."""
        vals = []
        for i, a in enumerate(args):
            if a == flag and i + 1 < len(args):
                vals += [v.strip() for v in args[i + 1].split(',') if v.strip()]
            elif a.startswith(flag + "="):
                vals += [v.strip() for v in a.split('=', 1)[1].split(',') if v.strip()]
        return vals

    include = opt_values("--label")
    exclude = opt_values("--exclude-label")
    assume_yes = "--yes" in args or "-y" in args

    # Parse arguments
    if "--labels" in args:
        manager.print_header()
        counts = manager.all_labels()
        if not counts:
            manager.print_info("No labels defined in the manifest.", "warning")
        else:
            manager.print_info("Labels in manifest.yaml:\n", "info")
            for label in sorted(counts, key=lambda k: (-counts[k], k)):
                print("  %-12s %d" % (label, counts[label]))
        return

    if "--unlink" in args or "-u" in args:
        manager.print_header()
        manager.unlink_all(force=assume_yes)
    elif include or exclude:
        manager.print_header()
        manager.link_by_label(include, exclude, force=assume_yes)
    elif assume_yes and ("--link" in args or "-l" in args):
        manager.print_header()
        manager.link_by_label(None, None, force=True)
    elif "--link" in args or "-l" in args:
        manager.interactive_mode()
    else:
        # Default to interactive mode
        manager.interactive_mode()

if __name__ == "__main__":
    try:
        main(sys.argv)
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)
