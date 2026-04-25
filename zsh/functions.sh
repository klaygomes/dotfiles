#!/bin/bash -euo pipefail

# https://stackoverflow.com/questions/23620827/envsubst-command-not-found-on-mac-os-x-10-8
which envsubst &>/dev/null || envsubst() { eval "echo \"$(sed 's/"/\\"/g')\""; }

# Copy meeting notes prompt to clipboard
function mp() {
  cat <<'EOF' | pbcopy && echo "Meeting prompt copied to clipboard"
Transform the raw meeting annotations into a structured Obsidian note.

Instructions:
1. Identify the date, project name, and attendees from the text.
2. Distill raw notes into a concise 'Minutes' section.
3. Extract 'Key Decisions' and 'Action Items' (use the [ ] checkbox format).
4. Ensure all person names are formatted as Obsidian links: [[Name]].
5. Give detailed information about questions and answers and what was discussed.
EOF
}

# Save clipboard content as a meeting note in ~/personal/meetings/
# The date is extracted from the clipboard text; falls back to today.
function sm() {
  python3 "$HOME/dotfiles/scripts/sm.py"
}

function cred() {
  python3 "$HOME/dotfiles/scripts/aws-update-creds.py"
}

# Export notes from Apple Notes to ~/.notes_staging as plain-text files.
# Usage: export_notes [FolderName]
#   With no argument, exports all folders.
#   With a folder name, exports only that folder.
# Each file is prefixed with its folder name (e.g. "Meetings__title.txt")
# so that migrate_notes.py can classify them by destination.
function export_notes() {
  local STAGING_DIR="$HOME/.notes_staging"
  mkdir -p "$STAGING_DIR"
  local TARGET_FOLDER="${1:-}"

  osascript <<EOF
tell application "Notes"
  set folderList to {}
  if "$TARGET_FOLDER" is not "" then
    set folderList to {folder "$TARGET_FOLDER"}
  else
    set folderList to folders
  end if
  repeat with theFolder in folderList
    set folderName to name of theFolder
    repeat with theNote in notes of theFolder
      set noteTitle to name of theNote
      set noteBody to body of theNote
      set safeTitle to do shell script "printf '%s' " & quoted form of (folderName & "__" & noteTitle) & " | tr '/: ' '---'"
      set outPath to "$STAGING_DIR/" & safeTitle & ".html"
      do shell script "printf '%s' " & quoted form of noteBody & " > " & quoted form of outPath
      do shell script "textutil -convert txt " & quoted form of outPath & " -output " & quoted form of ("$STAGING_DIR/" & safeTitle & ".txt")
      do shell script "rm " & quoted form of outPath
    end repeat
  end repeat
end tell
EOF

  echo "Exported notes to $STAGING_DIR"
}

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

# Inject a file into the .zshrc file after "source $ZSH/oh-my-zsh.sh"
# Arguments:
#   $1: The file to inject
# eg.
#   inject "file.sh"
function inject(){
  local before=false
  if [[ "$1" == "--before" ]]; then
    before=true
    shift
  fi
  file="$1"
  dest="${2-${HOME}/.zshrc}"
  if ! grep "${file}" ${dest} -q &> /dev/null; then
    # Find the line with "source $ZSH/oh-my-zsh.sh"
    if grep -q "source \$ZSH/oh-my-zsh.sh" "${dest}"; then
      if $before; then
        # Insert before the oh-my-zsh source line using perl
        perl -i -pe 'print "\n[[ \$- = *i* ]] && source '\'''"$file"''\''\n" if /source \$ZSH\/oh-my-zsh\.sh/' "${dest}"
      else
        # Insert after the oh-my-zsh source line using perl
        perl -i -pe '$_ .= "\n[[ \$- = *i* ]] && source '\'''"$file"''\''\n" if /source \$ZSH\/oh-my-zsh\.sh/' "${dest}"
      fi
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

function install_rvb(){
  gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable
  curl -sSL https://get.rvm.io | bash -s stable --rails
}

# Switch to a tmux session by name, creating it in session_dir if it doesn't exist.
function _tmux_attach() {
  local session_name="$1"
  local session_dir="$2"
  if tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux switch-client -t "$session_name"
  else
    tmux new-session -d -s "$session_name" -c "$session_dir"
    tmux switch-client -t "$session_name"
  fi
}

# Open or switch to a tmux session for a local file or directory path.
# For files: session is created in the file's parent directory.
function _tmux_open_local() {
  local path="$1"
  local session_dir session_name
  if [[ -f "$path" ]]; then
    session_dir=$(dirname "$path")
  else
    session_dir="$path"
  fi
  session_name=$(basename "$session_dir" | sed 's/^\.//' | tr '. ' '--')
  _tmux_attach "$session_name" "$session_dir"
}

# Create or switch to a tmux session.
# Accepts a plain session name or a GitHub URL.
# GitHub URL example: https://github.com/org/repo/pull/123
#   -> session name: repo, cwd: ~/org/repo (or ~/personal/repo for klaygomes org)
# Clones the repo via gh if the folder doesn't exist yet.
function _tmux_new_session() {
  local input="$1"
  local session_name session_dir

  if [[ "$input" =~ ^https://github\.com/([^/]+)/([^/]+) ]]; then
    local org="${match[1]}"
    local repo="${match[2]%%/*}"   # strip trailing path (/pull/62, /tree/main, etc.)
    session_name="$repo"
    if [[ "$org" == "klaygomes" ]]; then
      session_dir="$HOME/personal/$repo"
    else
      session_dir="$HOME/$org/$repo"
    fi
    if [[ ! -d "$session_dir" ]]; then
      mkdir -p "${session_dir:h}"
      gh repo clone "$org/$repo" "$session_dir"
    fi
  else
    session_name="$input"
    session_dir="$PWD"
  fi

  _tmux_attach "$session_name" "$session_dir"
}

