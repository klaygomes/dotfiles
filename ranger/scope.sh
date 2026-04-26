#!/usr/bin/env bash

FILE_PATH="$1"
PV_WIDTH="$2"
PV_HEIGHT="$3"

MIME_TYPE=$(file --dereference --brief --mime-type "$FILE_PATH")

case "$MIME_TYPE" in
    text/* | application/json | application/javascript | application/xml | inode/x-empty)
        bat \
            --color=always \
            --style=numbers \
            --line-range ":$PV_HEIGHT" \
            --terminal-width "$PV_WIDTH" \
            -- "$FILE_PATH" 2>/dev/null && exit 0
        ;;

    image/*)
        chafa --format=symbols --size "${PV_WIDTH}x${PV_HEIGHT}" "$FILE_PATH" \
            | sed 's/\x1b\[?25[lh]//g' && exit 0
        ;;

    application/pdf)
        pdftotext -l 10 -nopgbrk -q -- "$FILE_PATH" - 2>/dev/null && exit 0
        ;;

    application/zip)
        unzip -l "$FILE_PATH" && exit 0 ;;
    application/x-tar | application/x-gzip | application/x-bzip2 | application/x-xz)
        tar tf "$FILE_PATH" && exit 0 ;;
esac

exit 1
