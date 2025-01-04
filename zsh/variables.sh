#!/bin/bash -euo pipefail

# fzf and rg integration
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi

export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export CONFIG_PATH=$HOME/.config/
