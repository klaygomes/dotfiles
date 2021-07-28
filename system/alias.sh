# Chrome
# Run Chrome browser without CORS 
alias nocors='open -n -a /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security'

# Update Homebrew itself, upgrade all packages, remove dead symlinks, remove old versions
# of installed formulas, clean old downloads from cache, remove versions of formulas, which
# are downloaded, but not installed, check system for potential problems
alias brewup='brew update; brew upgrade; brew prune; brew cleanup; brew doctor'

# GIT
function gcb() {
	if [ $# -ne 1 ]
		then
			echo "usage create <branch-name>"
		return	
	fi
	(git checkout -b $1) && (git push --set-upstream origin $1)&
}

function gdb(){
	if [ $# -ne 1 ]
	then
		echo "usage delete <branch-name>"
   		return
	fi
	(git branch -D $1) && (git push origin :$1)&
}

alias gpf="git push -f"
alias gcm="git checkout master"
alias gc="git checkout"

# GENERAL
alias vim="nvim"
alias vi="nvim"

# NAVIGATION
alias h="cd ~"
