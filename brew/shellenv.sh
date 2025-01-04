#!/bin/bash -euo pipefail

# configure homebrew
printf "Configuring homebrew... "

if [[ "$(uname -m)" == "arm64" ]]; then
  echo "> ARM64 detected, setting homebrew location to /opt/homebrew"
  HOMEBREW_LOCATION=/opt/homebrew
else
  echo "> x86_64 detected, setting homebrew location to /usr/local"
  HOMEBREW_LOCATION=/usr/local
fi

printf "Setting homebrew environment variables..."

if grep -qF "/bin/brew shellenv" ${HOME}/.zshrc > /dev/null 2>&1; then
  echo "\nIt is already there..."
else
  echo "" >> $HOME/.zshrc # add a new line
  echo "eval \$(${HOMEBREW_LOCATION}/bin/brew shellenv)" >> $HOME/.zshrc
  echo " - ok"
fi

# inject brew shellenv into current session
eval $(${HOMEBREW_LOCATION}/bin/brew shellenv)
