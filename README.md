# dotfiles
Repository to store all my configuration files
Simply run the `install` executable to position the configuration files in the right order.
This command works by creating symlinks to each configuration file/directory in the right location.
More instructions available in the `@dotbot` repository.

## Notes
- To also clone the submodules, us the `--recursive` tag when cloning.
- After the installation of nvidia drivers and intel drivers, run the following command as root:\
`cp etc/X11/xorg.conf /etc/X11/xorg.conf`
