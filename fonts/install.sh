#!/bin/bash -euo pipefail

FONT_DIR="${HOME}/Library/Fonts"

if [ ! -d "$FONT_DIR" ]; then
    echo "Creating font directory: $FONT_DIR"
    mkdir -p "$FONT_DIR"
fi

while IFS= read -rd "" f; do
    printf "Installing font $(basename $f)"
    cp "$f" ${FONT_DIR}/
    echo " - ok"
done < <( find -L fonts -type f -path '*.ttf' -print0 )