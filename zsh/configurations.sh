#!/bin/bash -euo pipefail

# only owner can delete its files
umask 022

# avoid overwriting existing files with output redirection
set -o noclobber

HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

autoload -Uz compinit && compinit
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt MENU_COMPLETE

# Enable parameter expansion in the prompt
setopt PROMPT_SUBST

# Load Git info
autoload -Uz vcs_info
precmd() {
    if [[ -z "$TMUX" ]]; then
        IP_DATA="@$(get_ip_info)"
        vcs_info
    else
        IP_DATA=""
        vcs_info_msg_0_=""
    fi
    echo "$COLUMNS" >| /tmp/terminal_cols
}
zstyle ':vcs_info:git:*' formats ' ~ git (%b) '
if [[ -n "$TMUX" ]]; then
    PROMPT='%F{magenta}%(5~|%-1~/…/%3~|%~)%f %(!.#.$) '
else
    PROMPT='%F{magenta}%n${IP_DATA}${vcs_info_msg_0_}'$'\n''%~%f %(!.#.$) '
fi

if type brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
  [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
    && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
    && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
