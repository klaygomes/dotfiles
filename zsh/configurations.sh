#!/bin/bash -euo pipefail

# only owner can delete its files
umask 022

# avoid overwriting existing files with output redirection
set -o noclobber

# Enable parameter expansion in the prompt
setopt PROMPT_SUBST

# Load Git info
autoload -Uz vcs_info
precmd() {
    vcs_info
    IP_DATA=$(get_ip_info)
}
zstyle ':vcs_info:git:*' formats ' ~ git (%b) '

PROMPT='%F{magenta}%n@${IP_DATA}${vcs_info_msg_0_}'$'\n''%~%f %(!.#.$) '
