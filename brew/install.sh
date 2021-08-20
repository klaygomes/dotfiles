if [ ! -f "$(which brew)" ]
then
  echo "We are going to install Brew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Brew is already installed"
fi

if [[ "$(uname -m)" == "arm64" ]]; then
  homebrew_prefix=/opt/homebrew
else
  homebrew_prefix=/usr/local
fi

brew_env="$(${homebrew_prefix}/bin/brew shellenv)"
brew_env_file="${HOME}/.brewenv"

echo "${brew_env}" > "${brew_env_file}"
grep -qF "${brew_env_file}" ${HOME}/.zshrc || echo "source '${brew_env_file}'\n" >> $HOME/.zshrc
