#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias la='ls -A'
alias ll='ls -l'
alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

alias vi="vim"

# Use aliases in Sudo as well...
alias sudo='sudo '

# Virtual Env Local Directory
export PATH=$PATH:/home/ali/.local/bin/
export PATH=$PATH:/home/ali/.cargo/bin/

# Ruby Gem local directory
export PATH=$PATH:/home/ali/.local/share/gem/ruby/3.0.0/bin


# Firefox on wayland
# export MOZ_ENABLE_WAYLAND=1

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ali/Apps/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ali/Apps/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/home/ali/Apps/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ali/Apps/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
