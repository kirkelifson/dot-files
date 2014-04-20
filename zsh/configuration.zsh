# display user:host if remotely connected
if [[ -n $SSH_CONNECTION ]]; then
    export PROMPT='%{$fg[cyan]%}%n:%m%{$reset_color%}(%~)%(!.#.λ) '
else
    export PROMPT='(%~)%(!.#.λ) '
fi

# zsh features
setopt promptsubst
setopt correct
setopt complete_in_word
setopt append_history

# don't expand aliases before completion has finished
setopt complete_aliases

# history
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
