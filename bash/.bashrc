#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias la='ls -A'
alias ll='ls -l'
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

# ProtonVPN shortcuts
alias pvpnc='protonvpn-cli c'
alias pvpnd='protonvpn-cli d'
alias pvpnr='protonvpn-cli reconnect'
alias pvpns='protonvpn-cli status'



# Use aliases in Sudo as well...
alias sudo='sudo '

# Virtual Env Local Directory
export PATH=$PATH:/home/phoenix/.local/bin/



# Firefox on wayland
# export MOZ_ENABLE_WAYLAND=1
