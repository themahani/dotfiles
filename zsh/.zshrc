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
alias vi="nvim"

alias lg="lazygit"
alias ld="lazydocker"

export PATH=$PATH:/snap/bin

export PATH=$HOME/.cargo/bin/:$PATH
