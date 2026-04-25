#!/usr/bin/env bash
set -euo pipefail

PLUGINS_DIR="$HOME/.tmux/plugins"

clone_or_update() {
    local repo="$1"
    local name="${repo##*/}"
    local dest="$PLUGINS_DIR/$name"

    if [ ! -d "$dest" ]; then
        echo "> Cloning $name..."
        git clone --depth=1 "https://github.com/$repo" "$dest"
    else
        echo "> Updating $name..."
        git -C "$dest" pull --ff-only
    fi
}

mkdir -p "$PLUGINS_DIR"

clone_or_update "tmux-plugins/tpm"
clone_or_update "tmux-plugins/tmux-sensible"
clone_or_update "tmux-plugins/tmux-resurrect"
clone_or_update "tmux-plugins/tmux-continuum"

echo "- ok"
