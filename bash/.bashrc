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
alias pvpnc='sudo protonvpn c'
alias pvpnd='sudo protonvpn d'
alias pvpnr='sudo protonvpn reconnect'
alias pvpns='protonvpn status'





# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/phoenix/Apps/Anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/phoenix/Apps/Anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/phoenix/Apps/Anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/phoenix/Apps/Anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Use aliases in Sudo as well...
alias sudo='sudo '

# Virtual Env Local Directory
export PATH=$PATH:/home/phoenix/.local/bin/



# Firefox on wayland
# export MOZ_ENABLE_WAYLAND=1
