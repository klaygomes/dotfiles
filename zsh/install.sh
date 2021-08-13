#!/bin/bash

HOME=$1
CONFIG=$2

prompt_dir=${CONFIG}zsh/liquidprompt

if [ ! -d "${prompt_dir}" ]; then
	mkdir -p "${prompt_dir}"
	git clone --branch stable https://github.com/nojhan/liquidprompt.git "${prompt_dir}"
fi

if ! grep "${prompt_dir}" "${HOME}/.zshrc" -q ; then
  echo '[[ $- = *i* ]] && source '"'${prompt_dir}/liquidprompt'" >> "${HOME}/.zshrc"
fi
