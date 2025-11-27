#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Chrome - New window
# @raycast.mode compact

# Optional parameters:
# @raycast.icon /Applications/Google Chrome.app/Contents/Resources/app.icns

# Documentation:
# @raycast.description Opens a new window for Chrome
# @raycast.author Anton Bergman

open -na "Google Chrome" --args "--profile-directory=Default"
