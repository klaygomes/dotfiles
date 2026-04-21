#!/bin/bash -euo pipefail

# Install codedb
echo "Installing codedb..."
    curl -fsSL https://codedb.codegraff.com/install.sh | bash
echo " - ok"

# Configure  fzf
echo "Configuring fzf... "
    ${HOMEBREW_CELLAR}/fzf/$(fzf --version | cut -d ' ' -f 1)/install
echo " - ok"