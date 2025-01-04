#!/bin/bash -euo pipefail

if [ ! -f "$(which brew)" ]
  then
    echo "We are going to install Brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Brew is already installed, we are going to prune and clean your installation."
    brew update;
    brew upgrade;
    brew cleanup;
    brew doctor
fi
