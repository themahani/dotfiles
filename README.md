# dotfiles
Repository to store all my configuration files
Simply run the `install` executable to position the configuration files in the right order.
This command works by creating symlinks to each configuration file/directory in the right location.
More instructions available in the `@dotbot` repository.

## Notes
- To also clone the submodules, us the `--recursive` tag when cloning.
- After the installation of nvidia drivers and intel drivers, run the following command as root:\
`cp etc/X11/xorg.conf /etc/X11/xorg.conf`

### Neovim
After a clean install, on the first launch of `neovim`, the `lazy.nvim` plugin will install all the packages.\
Same goes for `mason` which is the packages manager for the LSP. If not, you can run the `:MasonInstallAll` command \
in neovim to install all preconfigured packages.

### Fonts
A lot of the terminal tools use **Nerd Fonts**. So please have them installed. \
You can choose the font you like in the configuration files.

## To-Do
- [ ] Setup nvim to close if `neo-tree.nvim` is the only buffer open
