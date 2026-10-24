"""Exercise installer migrations and OS routing without touching the real home."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
DEFINITIONS = (REPO / 'install').read_text().split('# --- Main ---')[0]


class InstallTests(unittest.TestCase):
    def run_shell(self, body):
        with tempfile.TemporaryDirectory() as temp:
            home = Path(temp)
            definitions = home / 'definitions'
            definitions.write_text(DEFINITIONS)
            env = os.environ.copy()
            env.update(HOME=temp, CI='', DOTFILES_CI='')
            result = subprocess.run(
                ['bash', '-c', 'source "$1"; dir="$2"; ' + body,
                 'test', str(definitions), str(REPO)],
                env=env, cwd=temp, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            return result.stdout

    def test_omarchy_refresh_retains_each_backup_and_is_idempotent(self):
        self.run_shell('''
            is_omarchy() { return 0; }
            mkdir -p "$HOME/.config/tmux"
            cfg="$HOME/.config/tmux/tmux.conf"
            echo original > "$cfg"
            setup_omarchy_tmux
            setup_omarchy_tmux
            test ! -e "$cfg.omarchy-default.1"
            echo refreshed > "$cfg"
            setup_omarchy_tmux
            echo refreshed-again > "$cfg"
            setup_omarchy_tmux
            grep -qx original "$cfg.omarchy-default"
            grep -qx refreshed "$cfg.omarchy-default.1"
            grep -qx refreshed-again "$cfg.omarchy-default.2"
            grep -qx 'source-file ~/.tmux.conf' "$cfg"
        ''')

    def test_backup_collision_with_directory_and_dangling_symlink(self):
        self.run_shell('''
            mkdir "$HOME/backup"
            ln -s missing "$HOME/backup.1"
            echo saved > "$HOME/source"
            backup_path "$HOME/source" "$HOME/backup"
            test -d "$HOME/backup"
            test -L "$HOME/backup.1"
            grep -qx saved "$HOME/backup.2"
        ''')

    def test_mise_migration_and_existing_local_config(self):
        self.run_shell('''
            mkdir -p "$HOME/.config"
            ln -s "$dir/.config/mise" "$HOME/.config/mise"
            link_mise_config
            test ! -L "$HOME/.config/mise"
            echo '# local config' > "$HOME/.config/mise/config.toml"
            link_mise_config
            grep -qx '# local config' "$HOME/.config/mise/config.toml"
            test "$(readlink "$HOME/.config/mise/conf.d/dot-files.toml")" = "$dir/.config/mise/config.toml"
        ''')

    def test_config_linking_platforms(self):
        for platform in ('Darwin', 'Linux', 'FreeBSD'):
            with self.subTest(platform=platform):
                self.run_shell('''
                    os="''' + platform + '''"
                    is_omarchy() { return 1; }
                    link_config_dirs
                    link_config_dirs
                    test -L "$HOME/.config/fish"
                    if [ "$os" = Darwin ]; then
                        test -L "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
                    else
                        test -L "$HOME/.config/ghostty"
                    fi
                ''')

    def test_omarchy_ghostty_untouched(self):
        self.run_shell('''
            is_omarchy() { return 0; }
            mkdir -p "$HOME/.config/ghostty"
            echo theme > "$HOME/.config/ghostty/config"
            link_config_dirs
            test ! -L "$HOME/.config/ghostty"
            grep -qx theme "$HOME/.config/ghostty/config"
        ''')

    def test_freebsd_package_routing_and_unavailable_package(self):
        output = self.run_shell('''
            os=FreeBSD
            mkdir "$HOME/repo"
            printf '# comment\\n\\nfish\\nmissing-package\\n' > "$HOME/repo/packages-freebsd.txt"
            dir="$HOME/repo"
            run_as_root() { "$@"; }
            pkg() {
                case "$1" in
                    update) return 0 ;;
                    search) [ "$4" = fish ] && echo fish-1.0; return 0 ;;
                    install) printf '%s\\n' "$*" > "$HOME/installed" ;;
                esac
            }
            fish() { :; }; git() { :; }; vim() { :; }; tmux() { :; }
            fzf() { :; }; fd() { :; }; mise() { :; }; curl() { :; }
            install_system_packages
            grep -qx 'install -y fish' "$HOME/installed"
            install_mise_runtimes
        ''')
        self.assertIn('missing-package (skipped)', output)
        self.assertIn('automatic runtime installs are skipped', output)


if __name__ == '__main__':
    unittest.main()
