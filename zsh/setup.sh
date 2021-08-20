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


# Improve fzf completion with shell completion
fzf_tab_dir=${CONFIG}zsh/fzf-tab-dir

if [ ! -d "$fzf_tab_dir" ]; then
  mkdir -p "$fzf_tab_dir"
  git clone https://github.com/Aloxaf/fzf-tab "$fzf_tab_dir"
fi

if ! grep "${fzf_tab_dir}" "${HOME}/.zshrc" -q ; then
  echo 'source '"'${fzf_tab_dir}/fzf-tab.plugin.zsh'" >> "${HOME}/.zshrc"
fi

