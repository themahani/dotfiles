# Dotfiles

Arch Linux configuration for Bash, Zsh, Git, Neovim, tmux, Kitty, Hyprland,
Waybar, Rofi, SwayNC, wlogout, MPD, rmpc, and Irssi.

Requirements: Git, Python >= 3.9, Neovim >= 0.12, and Hyprland's Lua config API
(tested with 0.56.2). Dotbot creates config links. Ansible installs Arch packages.

The repository uses my current setup as its base: `us,ir` keyboard layouts,
Catppuccin styling, Telegram autostart, Copilot, and language servers for my
development tools. Choose the applications through a profile, then adjust their
settings through local files. Review startup commands and hardware settings
before starting a new desktop session.

## Install

Run these commands as your regular user:

```bash
git clone https://github.com/themahani/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install profiles
./install plan --profile developer
./install apply --profile developer
./install doctor --profile developer
```

`./install` defaults to a preview of the developer profile. `apply` initializes
the selected Git submodules and creates links. Review the plan before applying.

### Profiles

| Profile     | Modules                                                                     |
| ----------- | --------------------------------------------------------------------------- |
| `minimal`   | Git, Neovim, Bash                                                           |
| `developer` | Git, Bash, Zsh, Neovim, tmux, CLI tools                                     |
| `desktop`   | Developer profile plus Kitty, fonts, and the Hyprland desktop               |
| `personal`  | Desktop profile plus music, Java, LaTeX, Rust, Irssi, and desktop utilities |

Add modules to a profile for a single command:

```bash
./install plan --profile minimal --modules tmux kitty
./install apply --profile developer --modules latex
```

`--modules` accepts one or more names. Selections include the profile's modules
and each module's dependencies. Save permanent selections in `profiles/*.json`.
An `extends` entry inherits a profile's modules, packages, and link overrides.
Every included module uses the same base configuration. The full Neovim server
list uses Java and LaTeX tools; add `--modules java latex` when provisioning a
smaller profile if you keep those servers enabled.

## Packages

Keep Arch current through your usual full-system upgrade workflow. Install
Ansible and its collection once:

```bash
sudo pacman -S --needed ansible-core
ansible-galaxy collection install -r ansible/requirements.yml
```

Preview the selected packages, then install them:

```bash
./install packages --profile developer --check
./install packages --profile developer --apply
```

Package installation requires a privilege-escalation password. Check mode reads
the package database as your regular user. Existing packages satisfy the manifest.
System upgrades, service setup, login-shell selection, and package removal remain
manual tasks.

The desktop requires `wlogout` and `blueberry`; the font settings also use
`vazirmatn-fonts`. These are listed under `aur` for manual installation with
your preferred AUR workflow. Review their build files before installing.

## Conflicts, relinking, and restore

The installer checks all selected destinations before linking. Matching links
are kept. Existing files, directories, and unrelated links require a decision.
Each linked directory belongs to its module; its contents come from the checkout.

Back up conflicting destinations before replacing them:

```bash
./install plan --profile personal --backup-conflicts
./install apply --profile personal --backup-conflicts
```

After moving the checkout, repair broken destination symlinks:

```bash
./install plan --profile personal --relink
./install apply --profile personal --relink
```

`--relink` requires an existing source and a broken destination symlink. Valid
unrelated links and ordinary files retain their conflict protection. Symlinked
parent directories require a separate migration.

Backups and journals live in
`${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/transactions/`. Apply prints a
transaction ID. Restore that transaction with:

```bash
./install restore --transaction TRANSACTION_ID
```

Restore removes unchanged links created by that transaction, restores available
backups, and removes empty directories it created. User changes remain in place.
Package installation and edits to repository files have separate recovery steps.
Backup moves require the source and transaction directories to share a filesystem.

Logs use ANSI colors in terminals. Use `--color always` for captured output,
`--color never` for plain text, or `NO_COLOR=1` to disable automatic colors.

## Customize the configuration

Settings in `config/` form the base. Local overrides load afterward and remain
outside the checkout. The installer preserves existing local files.

| File                                | Settings                                          |
| ----------------------------------- | ------------------------------------------------- |
| `~/.gitconfig_local`                | Git identity, editor, credential helper           |
| `~/.bashrc.local`                   | Bash environment and aliases                      |
| `~/.zshrc.local`                    | Zsh environment and aliases                       |
| `~/.config/dotfiles/nvim.local.lua` | Copilot, language servers, formatters             |
| `~/.config/dotfiles/hypr.local.lua` | Keyboard, mouse, startup commands                 |
| `~/.config/dotfiles/monitors.lua`   | Monitor layout                                    |
| `~/.config/dotfiles/workspaces.lua` | Workspace layout                                  |
| `~/.config/dotfiles/hypr.extra.lua` | Additional Hyprland configuration                 |
| `~/.config/dotfiles/nvim.extra.lua` | Additional editor options, mappings, and autocmds |

Shell and Git examples live beside their configs. Desktop/editor examples live
in `examples/`. For example:

```bash
mkdir -p ~/.config/dotfiles
test -e ~/.config/dotfiles/hypr.local.lua || cp examples/hypr.local.lua ~/.config/dotfiles/hypr.local.lua
test -e ~/.config/dotfiles/nvim.local.lua || cp examples/nvim.local.lua ~/.config/dotfiles/nvim.local.lua
```

Edit the copied files before restarting applications. The ignored Lua display
layouts in `config/hypr/` also load; external layouts in `~/.config/dotfiles/`
execute afterward.

### Lua settings and schemas

`config/dotfiles/schemas.lua` contains LuaLS type definitions and runtime
validation. The installer links it and `.luarc.json` beside your local files so
LuaLS can offer field completion. The examples include type annotations:

```lua
---@type DotfilesNvimConfig
local config = {
  copilot = false,
  servers_extra = { "rust_analyzer" },
}
return config
```

Each `.local.lua` file returns a table. All fields are optional. Unknown fields,
invalid types, and invalid list entries produce a warning; the entire invalid
override is ignored. Omitted fields keep their base values.

| Neovim field       | Value                                             |
| ------------------ | ------------------------------------------------- |
| `copilot`          | Boolean                                           |
| `servers`          | Replacement list of nvim-lspconfig server names   |
| `servers_extra`    | Server names to append                            |
| `formatters`       | Replacement list of Mason formatter package names |
| `formatters_extra` | Formatter package names to append                 |

| Hyprland field                     | Value                                                      |
| ---------------------------------- | ---------------------------------------------------------- |
| `terminal`, `file_manager`, `menu` | Command strings for launcher keybindings                   |
| `keyboard_layout`                  | XKB layout string, such as `"us,ir"`                       |
| `keyboard_options`                 | XKB options string; `""` clears it                         |
| `mouse`                            | `false`, or `{ name = "device-name", sensitivity = -0.5 }` |
| `autostart`                        | Replacement list of startup shell commands                 |
| `autostart_extra`                  | Startup commands to append                                 |

Mouse sensitivity ranges from -1 to 1. Lists replace complete lists, including
`{}` to disable them. The `_extra` fields append unique entries. `mouse = false`
disables the base device-specific setting.

For changes beyond these fields, use `nvim.extra.lua` with Neovim's `vim` API or
`hypr.extra.lua` with Hyprland's `hl` API. These scripts execute after the base
configuration. Formatter additions handle installation; configure new filetype
mappings through Conform in `nvim.extra.lua`. Examples cover both script types.
Hyprland's API annotations are installed under `/usr/share/hypr/stubs`.

Local Lua files execute as your user. Review copied code and startup commands.

### Other applications

Git uses the `store` credential helper, which saves credentials in plaintext.
Configure your preferred credential manager in `~/.gitconfig_local`.

The desktop shell lives in `config/quickshell`, targeting stable Quickshell
0.3.2 (not the Git development package). It replaces Waybar and SwayNC with a
multi-output bar, notification center/popups, and volume/microphone/brightness
OSD. The original Catppuccin Mocha colors and module actions are preserved.
See [the shell guide](config/quickshell/README.md) for dependencies, controls,
and validation. The old Waybar/SwayNC configs are retained only as references;
wlogout no longer depends on the Waybar palette path.

MPD uses paths under `~/.config/mpd`; preserve the database, playlists, and sticker
data when changing those paths. Desktop scripts assume the conventional
`~/.config` layout.

## Add an application

1. Save its shared config under `config/APP/`. Keep secrets and runtime data local.
2. Add an entry to `manifests/modules.json`:

   ```json
   "btop": {
     "links": {"$CONFIG/btop/btop.conf": "config/btop/btop.conf"},
     "packages": ["btop"],
     "commands": ["btop"]
   }
   ```

3. Preview it with `./install plan --profile personal --modules btop`.
4. Review package changes with `./install packages --profile personal --modules btop --check`.
5. Apply packages and config links when ready.
6. Add the module name to a profile for permanent selection.

`links` maps home/config destinations to repository-relative sources. `packages`
lists official Arch packages, `aur` lists manual prerequisites, `commands` lists
executables checked by `doctor`, and `requires` lists module dependencies.

## Plugins and tests

- tmux: press `Ctrl-a`, then `Shift-i`, to install TPM plugins.
- Neovim: lazy.nvim and Mason install plugins and tools on first startup. Copilot
  authentication is available through `:Copilot auth` when enabled.
- Zsh: Antigen downloads its selected plugins on first startup.

`lazy-lock.json` stays ignored so local plugin updates require no Git commit.
Plugin managers control their own downloaded versions.

```bash
python3 -B -m unittest discover -s tests -v
./install plan --profile minimal --home "$(mktemp -d)"
```

Tests use temporary homes. The tmux test uses a separate server socket; Lua tests
use isolated Neovim instances. Tests with missing application/plugin prerequisites
are skipped. Validate actual package installation and desktop startup in an Arch
VM before deploying to a new machine.
