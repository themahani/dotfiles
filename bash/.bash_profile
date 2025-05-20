#
# ~/.bash_profile
#
# Auto start tbsm after login on first two VTs
[[ $XDG_VTNR -le 2 ]] && tbsm

[[ -f ~/.bashrc ]] && . ~/.bashrc

. "$HOME/.local/bin/env"
