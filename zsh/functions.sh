#!/bin/bash -euo pipefail

# https://stackoverflow.com/questions/23620827/envsubst-command-not-found-on-mac-os-x-10-8
which envsubst &>/dev/null || envsubst() { eval "echo \"$(sed 's/"/\\"/g')\""; }

# Move one git repo into another
function gmd(){
    echo "Enter the source repo url: "
    read source_repo_url
    echo "Enter the source repo name: "
    read source_repo_name
    echo "Enter the source branch: "
    read source_branch
    echo "Enter the source folder: "
    read source_folder
    echo "Enter the target repo url: "
    read target_repo_url
    echo "Enter the target repo name: "
    read target_repo_name

    git clone $source_repo_url
    git clone $target_repo_url
    cd $source_repo_name
    git filter-branch --subdirectory-filter $source_folder -- -- all
    git reset --hard
    git gc --aggressive
    git prune
    git clean -fd
    mkdir $source_folder
    git mv -k * ./$source_folder
    git commit -m "chore: collected the folders we need to move"
    cd ../$target_repo_name
    git remote add $source_repo_name ../$source_repo_name/
    git fetch $source_repo_name
    git branch $source_repo_name remotes/$source_repo_name/master
    git merge $source_repo_name --allow-unrelated-histories
    git remote rm $source_repo_name
    git branch -d $source_repo_name
    git commit -m "chore: move files from $source_repo_name into $target_repo_name"
}

# Function to prompt for input and validate
# Arguments:
#   $1: The prompt to display
#   $2: The variable name to store the input in
#   $3: The regex to validate the input against
# eg. get_input "Enter your name" name '^[A-Za-z ]+$'
function get_input() {
  prompt="$1"
  variable_name="$2"
  validation_regex="$3"
  default_value="${4-}"

  while true; do
    printf "%s (%s): " "$prompt" "${default_value:-empty}"
    read -r input
    input="${input:-$default_value}"
    if expr "${input}" : "$validation_regex" >/dev/null; then
      eval "export $variable_name=\"\$input\""
      return 0
    else
      echo "Invalid $variable_name. Please try again."
    fi
  done
}

# Inject a file into the .zshrc file before "source $ZSH/oh-my-zsh.sh"
# Arguments:
#   $1: The file to inject
# eg. 
#   inject "file.sh"
function inject(){
  file="$1"
  dest="${2-${HOME}/.zshrc}"
  if ! grep "${file}" ${dest} -q &> /dev/null; then
    # Find the line with "source $ZSH/oh-my-zsh.sh"
    if grep -q "source \$ZSH/oh-my-zsh.sh" "${dest}"; then
      # Insert before the oh-my-zsh source line using perl
      perl -i -pe 'print "\n[[ \$- = *i* ]] && source '\'''"$file"''\''\n" if /source \$ZSH\/oh-my-zsh\.sh/' "${dest}"
    else
      # Fallback: append to end if oh-my-zsh line not found
      echo "" >> "${dest}" # add a new line
      echo '[[ $- = *i* ]] && source '"'$file'" >> "${dest}"
    fi
  fi
}

# scrape entire website
# Arguments:
#   $1: The URL to scrape
# eg.
#   scrape "https://example.com"
function scrape(){
  if [ -z "$1" ]; then
    echo "Please provide a URL"
    return 1
  fi
  url=$1
  domain=$(echo "$url" | sed -E 's/^(https?:\/\/)([^/]+).+$/\2/')

  echo "---"
  echo "domain: $domain"
  echo "url: $url"
  echo "---"
  
  wget \
      --recursive \
      --no-clobber \
      --timestamping \
      --no-if-modified-since \
      --waitretry=3 \
      --read-timeout=20 \
      --timeout=15 \
      --page-requisites \
      --retry-connrefused \
      --convert-links \
      --restrict-file-names=windows \
      --domains "$domain" \
      --no-parent \
          $url
}

function get_ip_info() {
    local ip_wifi=$(ipconfig getifaddr en0)
    if [ -n "$ip_wifi" ]; then
        echo "$ip_wifi at wlan"
        return
    fi

    local ip_eth=$(ipconfig getifaddr en1)
    if [ -n "$ip_eth" ]; then
        echo "$ip_eth at eth0"
        return
    fi
}
