# Chrome
# Run Chrome browser without CORS 
alias nocors='open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security'

# Update Homebrew itself, upgrade all packages, remove dead symlinks, remove old versions
# of installed formulas, clean old downloads from cache, remove versions of formulas, which
# are downloaded, but not installed, check system for potential problems
alias brewup='brew update; brew upgrade; brew prune; brew cleanup; brew doctor'

alias gpf="git push -f"
alias gcm="git checkout master"
alias gc="git checkout"

# GENERAL
alias vim="nvim"
alias vi="nvim"
alias vi="nvim"
alias v="nvim"

# NAVIGATION
alias h="cd ~"
alias ls="exa --tree --long --git --no-permissions --changed --no-user --sort type --level 10 -F"

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

