# display user:host if remotely connected
export PROMPT='%n:%m %~ %(!.#.$) '

setopt correct
setopt complete_in_word
setopt append_history

# don't expand aliases before completion has finished
setopt complete_aliases

# history
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
