#!/usr/bin/env bash
# ranger preview script — uses bat for syntax-highlighted text previews
# Requires: bat (brew install bat)

FILE_PATH="$1"
PV_WIDTH="$2"
PV_HEIGHT="$3"

MIME_TYPE=$(file --dereference --brief --mime-type "$FILE_PATH")

case "$MIME_TYPE" in
    # Syntax-highlighted preview via bat — only when bat has a syntax definition
    text/* | application/json | application/javascript | application/xml | inode/x-empty)
        bat \
            --color=always \
            --style=numbers \
            --line-range ":$PV_HEIGHT" \
            --terminal-width "$PV_WIDTH" \
            -- "$FILE_PATH" 2>/dev/null && exit 0
        ;;

    # Images — chafa converts to Unicode/block chars, works in Ghostty + tmux
    image/*)
        chafa --size "${PV_WIDTH}x${PV_HEIGHT}" "$FILE_PATH" 2>/dev/null && exit 0
        ;;

    # PDFs
    application/pdf)
        pdftotext -l 10 -nopgbrk -q -- "$FILE_PATH" - 2>/dev/null && exit 0
        ;;

    # Archives
    application/zip)
        unzip -l "$FILE_PATH" && exit 0 ;;
    application/x-tar | application/x-gzip | application/x-bzip2 | application/x-xz)
        tar tf "$FILE_PATH" && exit 0 ;;
esac

# Let ranger use its built-in default preview
exit 1
