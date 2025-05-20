# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

# load antigen
source "${HOME}/.antigen.zsh"

# Load the oh-my-zsh's library
antigen use oh-my-zsh

antigen bundles <<EOBUNDLES
    # Bundles from the default repo (robbyrussell's oh-my-zsh)
    git
    sudo
    archlinux
    command-not-found

    # Zsh syntax highlighting
    zsh-users/zsh-syntax-highlighting

    # Fish-like auto suggestions
    zsh-users/zsh-autosuggestions

    # Extra zsh completions
    zsh-users/zsh-completions
EOBUNDLES

# Load the theme
antigen theme https://github.com/denysdovhan/spaceship-zsh-theme spaceship
# Tell antigen that you're done
antigen apply


# Get rid of the `vi` command
alias vi="vim"

alias lg="lazygit"
alias ld="lazydocker"

export PATH=$PATH:/snap/bin

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ali/Apps/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ali/Apps/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ali/Apps/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ali/Apps/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ali/Apps/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
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

# load bashrc configs
# source ~/.bashrc

. "$HOME/.local/bin/env"
