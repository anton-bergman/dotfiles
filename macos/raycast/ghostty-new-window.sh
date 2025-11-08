#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Ghostty - New window
# @raycast.mode compact

# Optional parameters:
# @raycast.icon /Applications/Ghostty.app/Contents/Resources/Ghostty.icns

# Documentation:
# @raycast.description Opens a new window for Ghostty
# @raycast.author Anton Bergman

osascript -e 'tell application "Ghostty" to activate' -e 'tell application "System Events" to tell process "Ghostty" to click menu item "New Window" of menu "File" of menu bar 1'
