if [ ! -f "$(which brew)" ]
then
  echo "We are going to install Brew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew="$(/opt/homebrew/bin/brew shellenv)"
  touch $HOME/.zshrc
  grep -qF "HOMEBREW_PREFIX" ${HOME}/.zshrc || echo "${brew}" >> $HOME/.zshrc
else
  echo "Brew is already installed"
fi


