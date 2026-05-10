#!/usr/bin/env bash
# Live grep current directory using rg + fzf + bat (§ /)

RG_PREFIX="rg --color=always --line-number --no-heading --smart-case"

selected=$(
  fzf --ansi --no-multi --no-info --height=100% \
      --disabled \
      --query "" \
      --bind "change:reload:$RG_PREFIX {q} . 2>/dev/null || true" \
      --delimiter : \
      --preview '[[ -n {2} ]] && bat --force-colorization --style=numbers --theme=GrepPreview --highlight-line {2} -- {1}' \
      --preview-window 'up,60%,border-bottom,+{2}-/2' \
      --bind 'esc:abort'
)

[ -z "$selected" ] && exit 0

file=$(echo "$selected" | cut -d: -f1)
line=$(echo "$selected" | cut -d: -f2)

${EDITOR:-nvim} +"$line" "$file"
