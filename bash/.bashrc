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

