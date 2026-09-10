NEWLINE=$'\n'

# For the function below, add this line to the theme of choice:
# %{$fg[green]%}$(virtualenv_info)%{$reset_color%}%
function virtualenv_info { 
    [ $VIRTUAL_ENV ] && echo 'virtual_env:('`basename $VIRTUAL_ENV`') ' 
}

PROMPT='$(git_prompt_info) %{$fg[green]%}$(virtualenv_info)%{$reset_color%}% '
PROMPT+='%K{red}%B%F{white}%/%k%f%b${NEWLINE}%(!.#root.>) '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
