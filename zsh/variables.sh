
# Android Emulator Variables
export ANDROID_HOME=/usr/local/share/android-sdk
export PATH=$ANDROID_HOME/emulator:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# Compilation flags
export ARCHFLAGS=$(uname -m)

# fzf and rg integration
if type rg &> /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files'
  export FZF_DEFAULT_OPTS='-m --height 50% --border'
fi
