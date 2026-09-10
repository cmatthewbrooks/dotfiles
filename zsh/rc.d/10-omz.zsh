# oh-my-zsh. Everything here must run BEFORE oh-my-zsh.sh is sourced, since
# that call reads these variables and runs compinit itself.

ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="cmb"
HIST_STAMPS="yyyy-mm-dd"

# zsh-syntax-highlighting wraps the ZLE widgets defined before it, so it must
# stay last in this list.
plugins=(
    git
    tmux
    python
    zsh-syntax-highlighting
)

# Completion styles have to be set before compinit, which oh-my-zsh.sh runs.
zstyle ':completion:*' completer _complete _ignored

source "$ZSH/oh-my-zsh.sh"
