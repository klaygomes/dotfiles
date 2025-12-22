#!/bin/bash -euo pipefail

# Chrome
# Run Chrome browser without CORS 
alias nocors='open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security'

# Update Homebrew itself, upgrade all packages, remove dead symlinks, remove old versions
# of installed formulas, clean old downloads from cache, remove versions of formulas, which
# are downloaded, but not installed, check system for potential problems
alias brewup='brew update; brew upgrade; brew prune; brew cleanup; brew doctor'

# GENERAL
alias vim="nvim"
alias vi="nvim"
alias v="nvim"

alias c="clear"
alias cl="clear"
alias cls="clear"

alias p="pwd"
# copy with confirmation
alias cp="cp -i"
# move with confirmation
alias mv="mv -i"
# create parent directories if needed
alias mkdir="mkdir -p"
# list files with human-readable sizes, permissions, and modification times
alias ls="ls -lahS"

# NAVIGATION
alias h="cd ~"
alias ...="cd ../.."
alias 2..="cd ../.."
alias 3..="cd ../../.."
alias 4..="cd ../../../.."
alias 5..="cd ../../../../.."

alias dotfiles="cd ${HOME}/dotfiles"

# well, I gave up not typing these
alias :x="exit"
alias :q="exit"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession
-suspend"

if type git &> /dev/null;
then

    alias g="git"
    alias gs="git status"
    alias ga="git add"
    alias gc="git commit"
    alias gcm="git checkout master"
    alias gco="git checkout"
    alias gpf="git push -f"
    alias gb="git branch"
    alias gbd="git branch -d"
    alias gba="git branch -a"

    if type fzf &> /dev/null;
    then

        alias glog="git log --oneline --decorate --graph | fzf"
        alias gfind="git checkout \$(git branch | fzf)"
    fi
fi

alias termlog="pmset -g thermlog"
