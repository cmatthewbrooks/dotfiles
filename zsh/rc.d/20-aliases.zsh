# Aliases. Loaded after oh-my-zsh so these win over any plugin definitions.

alias zshconfig="vim ${ZDOTDIR:-$HOME}/.zshrc"
alias zshsource="source ${ZDOTDIR:-$HOME}/.zshrc"
alias ohmyzsh="vim $HOME/.oh-my-zsh"
alias zshrcd="cd ${ZDOTDIR:-$HOME}/rc.d"

# Navigation
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../../../'
alias ....='cd ../../../../'
alias .....='cd ../../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

alias vi='vim'
alias edit='vim'
alias vless='vim -c "set nonumber"'

# Typo catchers
alias cler="clear"
alias clera="clear"
alias cdclear="cd && clear"
alias clearls="clear && ls"

alias sha="shasum -a 256"
alias publicip="curl -s https://api.ipify.org && echo"

alias gs="git status"

# colordiff is a separate package; fall back to plain diff when it is absent
# so a fresh host does not end up with a broken `diff`.
if command -v colordiff >/dev/null 2>&1; then
  alias diff='colordiff'
fi
