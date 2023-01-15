setopt histignorealldups    # Subsitute commands in the prompt
setopt sharehistory         # Share history with other shells
setopt nonomatch            # Avoid zsh no matches found
setopt appendhistory        # Append history list to history file
setopt hist_reduce_blanks   # Remove blank lines from history
setopt hist_ignore_all_dups # Remove all duplicates from history
setopt nobeep               # Avoid beeping
setopt extended_glob        # Extended globbing
setopt extended_history     #
setopt notify               # Report the status of background jobs
setopt autocd               # Change to directory without "cd"
setopt longlistjobs         # Display PID when suspending processes
setopt hash_list_all        # When command completion is attempted, make sure the entire command path is hashed first.
setopt completeinword       # Complete at any position of the line
setopt auto_param_slash     # Append a slash if complettion target was a directory

export EDITOR='nvim'

# Defaults in case they're not set up
if [[ -z "$XDG_DATA_HOME" ]]; then
    export XDG_DATA_HOME="$HOME/.local/share"
fi

if [[ -z "$XDG_CONFIG_HOME" ]]; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ -z "$XDG_CACHE_HOME" ]]; then
    export XDG_CACHE_HOME="$HOME/.cache"
fi

# Liquid Prompt Plugin
LP_ENABLE_RUBY_VENV=0
# Replace LP_COLOR_SSH with a color based on the hash of the hostname.
LP_ENABLE_SSH_COLORS=1
