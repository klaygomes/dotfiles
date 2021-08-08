if [ ! -f "$(which brew)" ]
then
  echo "We are going to install Brew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Brew is already installed"
fi
