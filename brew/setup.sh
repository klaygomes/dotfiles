#!/bin/bash -euo pipefail

# Configure  fzf
echo "Configuring fzf... "
    ${HOMEBREW_CELLAR}/fzf/$(fzf --version | cut -d ' ' -f 1)/install
echo " - ok"