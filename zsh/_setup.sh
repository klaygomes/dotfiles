#!/bin/bash

HOME=$1
CONFIG=$2

DIR=${CONFIG}zsh

antigen="${DIR}/antigen.zsh"
if [ ! -f "$antigen" ]; then
  curl -L git.io/antigen > "$antigen"
fi;

inject(){
  file="${DIR}/$1"
  if ! grep "${file}" "${HOME}/.zshrc" -q ; then
    echo '[[ $- = *i* ]] && source '"'$file'" >> "${HOME}/.zshrc"
  fi
}

inject antigen.zsh
