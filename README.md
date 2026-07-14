# Dotfiles

My dotfiles for my most used applications. These config files are constantly revised for better perfomance and compatibility. Feel free to clone them,
modify them, and potentially submit a pull request. :wink:

## Dependencies

The installation depends on you having the following applications

- **Installation dependencies**:
  - `git`
  - `python3`
- **Vim** and **Neovim**:
  - `vim` (not maintaining the configs for this one anymore)
  - `neovim`
  - `nodejs`
  - `npm`
  - `rust` and `cargo` (in some OS variants, these are separate packages)
  - `texlab` and `latexmk` (for the latex LSP server and build)
  - `lazygit` for the `lazygit.nvim` plugin
- **Tmux**:
  - `tmux`
- JetBrains Mono Nerd Font ( installation method depends on your OS and package manager )

And the configurations apply to the following applications:

- [kitty](https://github.com/kovidhoyal/kitty)
- [tmux](https://github.com/tmux/tmux)
- [neovim](https://github.com/neovim/neovim)
- [ vim ](https://github.com/vim/vim)

## Installation

In order to setup the dotfiles, run the following commands:

```bash
cd ~
git clone --recursive https://github.com/themahani/dotfiles.git .dotfiles
cd .dotfiles
./install
```

## Post-Installation Notes

Ater installing the configs, some apps require your manual intervention to set up.

- **Tmux**: Upon the first initialization of the app, use the `C-a I` combo -- that is ctrl+a, then shift+i -- to install all the tmux plugins.
- **Neovim**: In your first run of the app, `lazy.nvim` will install all the plugins and `mason` will configure all the LSP servers, so not much to do there. You need to run
  `:Copilot auth` if you plan on using it. You can check the keymaps by invoking the keymap picker `<space>sk`. `<leader>` is mapped to `<space>`, btw...
- **Vim**: Run the vim command `:PlugInstall`, (for more command options and fancy maneuvers visit [vim-plug](https://github.com/junegunn/vim-plug))
- **Kitty**: Nothing to do here, just run the app and do your thing. :)
- **Zsh**: Uses `antigen` to install some plugins. The plugins are installed in a `$HOME/.zsh/` directory and should not be tracked by git. The `.zshrc` file is minimal. If you want
  to add environment parameters to it (e.g., installing mamba or conda and having to set PATH env variable), you can do so by adding them to the `$HOME/.zshenv` file and (optionally) track it.

## Credits

My configurations for neovim were inspired by many that are available on github, at this point I have lost count of how many configurations I've
looked into. So if you have a dotfiles repo, thank you :)
