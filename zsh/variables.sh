
# Android Emulator Variables
export ANDROID_HOME=/usr/local/share/android-sdk
export PATH=$ANDROID_HOME/emulator:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# Compilation flags
export ARCHFLAGS=$(uname -m)

# fzf and fd integration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

