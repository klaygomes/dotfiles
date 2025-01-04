#!/bin/bash -euo pipefail


echo "Installing nvm..."

if ! command -v brew &> /dev/null
then
    echo "> Brew not found, run make brew before running this script"
    exit
fi

#verify if we have curl
if ! command -v curl &> /dev/null
then
    echo "> Curl not found, installing..."
    brew install curl
fi

echo "> Feching nvm..."
# I don't need to care if it is already installed, it will just update it
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash 

echo "> Loading environment..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "> Installing node..."
#  install latest lts version and use it
nvm install --lts
nvm use --lts

while IFS= read -r line; do
    echo "> Installing $line"
    npm install -g $line &> /dev/null &
done < ./node/globals

# wait for the installation to finish
wait
echo "- ok"