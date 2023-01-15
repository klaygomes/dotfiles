echo "Starting Mac configuration..."
#################################
#### FINDER
#################################

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Set 'home directory' as default, new window directory
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# Disable showing tags
defaults write com.apple.finder ShowRecentTags -int 0

########################################
#### DOCK
########################################

# Set Dock size
defaults write com.apple.dock tilesize -int 35

# Auto-hide Dock
defaults write com.apple.dock autohide -int 0

# Disable animations
defaults write com.apple.dock launchanim -int 0

# Disable minimizing windows into their application’s icon
defaults write com.apple.dock minimize-to-application -int 0

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -int 1

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "suck"

# Disable double-click on window's title bar to minimize it
defaults write NSGlobalDomain AppleActionOnDoubleClick None

#################################
#### TRACKPAD
#################################

# Enable tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -int 1

# Enable right click (tap with two fingers)
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -int 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -int 1

# Enable application change (swipe horizontal witch three fingers)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 2

# Enable the Launchpad gesture (pinch with thumb and three fingers)
defaults write com.apple.dock showLaunchpadGestureEnabled -int 1

# Enable Expose gesture (slide down with three fingers)
defaults write com.apple.dock showAppExposeGestureEnabled -int 1

#################################
#### KEYBOARD
#################################

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain WebAutomaticSpellingCorrectionEnabled -int 0

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Set keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

#################################
#### OTHER
#################################

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Enable Dark Mode
defaults write NSGlobalDomain AppleInterfaceStyle Dark

# Reset icons order in Dashboard
defaults write com.apple.dock ResetLaunchPad -bool true

# Show battery percentage in Menu Bar
defaults write com.apple.menuextra.battery ShowPercent YES

# Close windows then quitting an app
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -int 0

# Ask to kepp change when closing documents
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -int 1

# Set alert sound
defaults write NSGlobalDomain com.apple.sound.beep.sound -string "/System/Library/Sounds/Funk.aiff"

# Set date format in menubar
defaults write "com.apple.menuextra.clock" DateFormat -string "EEE d.MM  HH:mm"

# apply the changes
applications_to_kill=(
  "Activity Monitor"
  "Dock"
  "Finder"
)

killall "${applications_to_kill[@]}"

curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh

echo "done!"
