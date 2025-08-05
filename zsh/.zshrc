# load antigen
source "${HOME}/.antigen.zsh"


antigen use oh-my-zsh

antigen bundles <<EOBUNDLES
    # Bundles from the default repo (robbyrussell's oh-my-zsh)
    git
    sudo
    archlinux

    # Zsh syntax highlighting
    # zsh-users/zsh-syntax-highlighting

    # Fish-like auto suggestions
    # zsh-users/zsh-autosuggestions

    # Extra zsh completions
    # zsh-users/zsh-completions
EOBUNDLES

# Load the theme
antigen theme https://github.com/denysdovhan/spaceship-zsh-theme spaceship
# Tell antigen that you're done
antigen apply

# Add ~/.cargo/bin to PATH if it exists
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Add /snap/bin to PATH if it exists
if [ -d "/snap/bin" ]; then
    export PATH="$PATH:/snap/bin"
fi

# Use modern completion system
autoload -U compinit && compinit


# Set default editor to neovim
export EDITOR='nvim'
export VISUAL='nvim'

# Get rid of the `vi` command
alias vi="nvim"

alias lg="lazygit"
alias ld="lazydocker"
