#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title iTerm - New window
# @raycast.mode compact

# Optional parameters:
# @raycast.icon /Applications/iTerm.app/Contents/Resources/iTerm2 App Icon for Release.icns

# Documentation:
# @raycast.description Opens a new window for iTerm
# @raycast.author Anton Bergman

osascript -e 'tell application "iTerm" to create window with default profile'
