#!/usr/bin/env bash
set -euo pipefail

printf "Starting Mac configuration..."
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

# Add home directory to Finder sidebar
defaults write com.apple.finder SidebarPlaces -dict-add "Home" "{ 'enabled' = 1; 'path' = '~/'; 'show' = 1; }"

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions in Finder
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

########################################
#### DOCK
########################################

# Move Dock to the right
defaults write com.apple.dock orientation -string "right"

# Remove default apps from the dock
defaults write com.apple.dock persistent-apps -array

# Add highlight effect to dock stacks
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Set item size
defaults write com.apple.dock tilesize -int 35

# Use genie animation
defaults write com.apple.dock mineffect -string "genie"

# Minimize apps into their dock icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable spring loading for opening files by dragging to dock
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

# Show indicator lights for open applications in the Dock
defaults write com.apple.dock show-process-indicators -bool true

# Enable app launching animations
defaults write com.apple.dock launchanim -bool true

# Set opening animation speed
defaults write com.apple.dock expose-animation-duration -float 1

# Auto-hide Dock
defaults write com.apple.dock autohide -bool false

# Show which dock apps are hidden
defaults write com.apple.dock showhidden -bool true

# Hide recent applications
defaults write com.apple.dock show-recents -bool false

# Double-click on window's title bar to maximize it
defaults write -g AppleActionOnDoubleClick -string "Maximize"

# Use dockutil to manage dock apps if available
if hash dockutil 2>/dev/null; then
  apps_to_remove=(
    'App Store' 'Calendar' 'Contacts' 'FaceTime'
    'Keynote' 'Mail' 'Maps' 'Messages' 'Music'
    'News' 'Notes' 'Numbers' 'Pages' 'Photos'
    'Podcasts' 'Reminders' 'TV'
  )
  apps_to_add=(
    'Ghostty' 'Google Chrome' 'Safari' 'Visual Studio Code'
  )
  for app in "${apps_to_remove[@]}"; do
    dockutil --remove "$app" --no-restart 2>/dev/null || true
  done
  for app in "${apps_to_add[@]}"; do
    if [[ -d "/Applications/${app}.app" ]]; then
      dockutil --add "/Applications/${app}.app" --no-restart 2>/dev/null || true
    fi
  done
fi

#################################
#### TRACKPAD
#################################

# Enable tap to click
for trackpad in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write "$trackpad" Clicking -int 1
done

# Enable right click (tap with two fingers)
for trackpad in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write "$trackpad" TrackpadRightClick -int 1
done

# Enable application change (swipe horizontal with three fingers)
for trackpad in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
    defaults write "$trackpad" TrackpadThreeFingerHorizSwipeGesture -int 2
done

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

# Disable spotlight keyboard shortcut
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "{enabled = 0; value = { parameters = (65535, 49, 1048576); type = 'standard'; }; }"

# Do a noise when changing volume
defaults write NSGlobalDomain com.apple.sound.beep.feedback -int 1

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

# Ask to keep change when closing documents
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -int 1

# Set alert sound
defaults write NSGlobalDomain com.apple.sound.beep.sound -string "/System/Library/Sounds/Funk.aiff"

# Set date format in menubar
defaults write "com.apple.menuextra.clock" DateFormat -string "EEE d.MM  HH:mm"

# Prevent Mac from changing the order of Desktops/Spaces
defaults write com.apple.dock "mru-spaces" -bool "false"

# Prevents Terminal showing last session's contents
touch ~/.hushlogin

defaults -currentHost write -g com.apple.keyboard.modifiermapping.0-0-0 -array

# apply the changes
applications_to_kill=(
  "Activity Monitor"
  "Dock"
  "Finder"
)

killall "${applications_to_kill[@]}"

echo " - ok"
# Disable spotlight indexing (We use Alfred, so it is not needed)
printf "Disabling spotlight indexing... "
    sudo mdutil -i off -d / &> /dev/null
    sudo mdutil -E / &> /dev/null
    # Tahoe: https://eclecticlight.co/2026/01/16/can-you-disable-spotlight-and-siri-in-macos-tahoe/
    sudo mdutil -a -d &> /dev/null
echo " - ok"

# Remove spotlight icon from menu bar
printf "Hide spotlight icon from menu bar... "
defaults -currentHost write com.apple.Spotlight MenuItemHidden -int 1

