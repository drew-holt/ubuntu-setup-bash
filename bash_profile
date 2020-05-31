. "$HOME/.bashrc"

export PATH="$HOME/.local/bin:$PATH"

export HISTCONTROL=ignoredups:erasedups  # no duplicate entries
export HISTSIZE=100000                   # big big history
export HISTFILESIZE=100000               # big big history
shopt -s histappend                      # append to history, don't overwrite it

# Save and reload the history after each command finishes
# export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

export EDITOR=vim
export MVN_HOME=/usr/local/maven

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

function set_aws {
  eval $(awsenv shell $1)
}
function login_aws {
  open $(awsenv console $1)
}

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

eval "$($HOME/.chefvm/bin/chefvm init -)"

export PATH="$HOME/.tfenv/bin:$PATH"

complete -C '$HOME/.local/bin/aws_completer' aws

function set_aws {
  eval $(awsenv shell $1)
}
function login_aws {
  open $(awsenv console $1)
}
