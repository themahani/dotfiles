# load antigen
if [[ -r "${HOME}/.antigen.zsh" ]]; then
    source "${HOME}/.antigen.zsh"
else
    print -u2 'Antigen is missing; run the dotfiles installer before loading plugins.'
    return
fi

# Autosuggestions style
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Syntax Highlighting style
# Define colors for different parts of the command line.
# We use the terminal's theme colors (e.g., 'blue', 'yellow').
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]="fg=white"
ZSH_HIGHLIGHT_STYLES[command]="fg=cyan,bold"
ZSH_HIGHLIGHT_STYLES[path]="fg=magenta"
ZSH_HIGHLIGHT_STYLES[string]="fg=green"
ZSH_HIGHLIGHT_STYLES[reserved-word]="fg=blue"
ZSH_HIGHLIGHT_STYLES[comment]="fg=8" # Same subtle grey as autosuggestions

# zsh-vi-mode configs
ZVM_SYSTEM_CLIPBOARD_ENABLED=true


antigen use oh-my-zsh

antigen bundles <<EOBUNDLES
    # Bundles from the default repo (robbyrussell's oh-my-zsh)
    git
    sudo

    # Vi/Vim mode
    jeffreytse/zsh-vi-mode

    # Zsh syntax highlighting
    zsh-users/zsh-syntax-highlighting

    # Fish-like auto suggestions
    zsh-users/zsh-autosuggestions

    # Extra zsh completions
    zsh-users/zsh-completions
EOBUNDLES

if [[ -f /etc/arch-release ]]; then
    antigen bundle archlinux
fi

# Load the theme
antigen theme https://github.com/denysdovhan/spaceship-zsh-theme spaceship
# Tell antigen that you're done
antigen apply

# Use modern completion system
autoload -U compinit && compinit

# Completion style using zstyle
zstyle ':completion:*' completer _extensions _complete _approximate     # Load compinit modules
zstyle ':completion:*' use-cache on     # cache completions
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompcache" # completion cache directory

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''    # Group completion results
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands    # Group order or command completion results
# zstyle ':completion:*' file-list all    # show all file list results using the -l flag
zstyle ':completion:*' squeeze-slashes true     # Smarter directory suggestions
# Colorize the completion menu using the theme's colors
zstyle ':completion:*:default' list-colors "=(#s)''=(${(s.:.)LS_COLORS})="
zstyle ':completion:*:descriptions' format $'\e[34m%d\e[0m' # Descriptions in blue


# Add ~/.cargo/bin to PATH if it exists
if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Add /snap/bin to PATH if it exists
if [ -d "/snap/bin" ]; then
    export PATH="$PATH:/snap/bin"
fi



# Optional apps are not required just to use the shell module.
if (( $+commands[nvim] )); then
    export EDITOR='nvim'
    export VISUAL='nvim'
    alias vi="nvim"
fi
if (( $+commands[eza] )); then
    alias el="eza -lh"
    alias ela="eza -lha"
fi
(( $+commands[lazygit] )) && alias lg="lazygit"
(( $+commands[lazydocker] )) && alias ld="lazydocker"

# Machine-specific overrides (not committed). See .zshrc.local.example.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
