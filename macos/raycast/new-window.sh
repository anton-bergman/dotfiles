#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title New window
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 🤖
# @raycast.argument1 { "type": "text", "placeholder": "Placeholder" }

# Documentation:
# @raycast.description Opens a new window for a given application
# @raycast.author Anton Bergman

app_name="$1"

if [ "$app_name" = "chrome" ]; then
	open -na "Google Chrome" --args "--profile-directory=Default"

elif [ "$app_name" = "vscode" ]; then
	open -na "Visual Studio Code"

elif [ "$app_name" = "iterm" ] || [ "$app_name" = "terminal" ]; then
	osascript -e 'tell application "iTerm" to create window with default profile'

else
	echo "Unknown app: $app_name"
	exit 1
fi
