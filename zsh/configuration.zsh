# display user:host if remotely connected
if [[ -n $SSH_CONNECTION ]]; then
    export PS1='%{$fg[cyan]%}%n:%m%{$reset_color%} [%~] %(!.#.λ) '
else
    export PS1='[%~] %(!.#.λ) '
fi

setopt NO_LIST_BEEP
setopt PROMPT_SUBST
setopt CORRECT
setopt COMPLETE_IN_WORD

# don't expand aliases before completion has finished
setopt complete_aliases

# history
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000