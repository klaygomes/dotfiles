#!/bin/bash -euo pipefail

while IFS= read -rd "" f; do
    printf "Installing font $(basename $f)"
    cp "$f" ${HOME}/Library/Fonts/
    echo " - ok"
done < <( find -L fonts -type f -path '*.ttf' -print0 )